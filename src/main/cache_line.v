module cache_line #(
    parameter ADDRESS_WORD_SIZE = 32,
    parameter TAG_SIZE          = 19,
    parameter BLOCK_SIZE        = 16,  // number of 32‐bit words per line?
    parameter WORD_SIZE         = 4    // bytes per word?
) (
    input  wire                         clk,
    input  wire                         rst_b,
    input  wire                         ready,
    input  wire [ADDRESS_WORD_SIZE-1:0] address_word,
    input  wire                         try_read,
    input  wire                         try_write,
    input  wire [                  7:0] write_data,     // writing one byte
    input  wire                         reset_age,
    input  wire                         increment_age,
    output reg  [                  7:0] data,           // one byte out
    output reg  [                  1:0] age,
    output reg                          hit_miss,
    output reg                          is_empty
);

    //--------------------------------------------------------------------------
    // 1) Internal registers (state)
    //--------------------------------------------------------------------------
    reg valid_bit;
    reg [TAG_SIZE-1:0] tag;
    // We assume each “word” is 32 bits (4 bytes). BLOCK_SIZE=16 means
    // 16 words * 32 bits = 512 bits total for block_of_data.
    // If each “word” is 4 bytes, then you want 16 * 32 = 512 bits.
    reg [BLOCK_SIZE * WORD_SIZE * 8 - 1:0] block_of_data;
    reg [1:0] age_bits;
    reg dirty_bit;

    //--------------------------------------------------------------------------
    // 2) Combinational helpers: compute tag‐match, block/word offsets, index
    //--------------------------------------------------------------------------
    wire [TAG_SIZE-1:0] addr_tag = address_word[ADDRESS_WORD_SIZE-1 : ADDRESS_WORD_SIZE-TAG_SIZE];

    // Compare stored tag vs incoming tag:
    wire matching_tags;
    bitwise_comparator #(
        .w(TAG_SIZE)
    ) uut_comp (
        .in_0(tag),
        .in_1(addr_tag),
        .eq  (matching_tags)
    );

    // Splitting address into block_offset and word_offset:
    //   word_offset = lowest two bits → which byte within the 4‐byte word
    //   block_offset = next 4 bits → which 32‐bit word within the line
    wire [1:0] word_offset = address_word[1:0];  // selects which byte within 32‐bit word
    wire [3:0] block_offset = address_word[5:2];  // selects 0..15 (16 words)

    // We need 9 bits to index 512 bits (0..511). So end_index is 9 bits:
    //   Each block “word” is 32 bits (WORD_SIZE*8). We want the top‐of‐byte:
    //   end_index = (block_offset * 32) + ((word_offset + 1) * 8) - 1
    wire [8:0] byte_index;
    assign byte_index = (block_offset << 5)  // block_offset * 32
        + ((word_offset + 1) << 3)  // (word_offset + 1) * 8
        - 1;

    //--------------------------------------------------------------------------
    // 3) Sequential logic: reset + clock
    //--------------------------------------------------------------------------
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            // Asynchronous reset: clear everything
            valid_bit     <= 1'b0;
            tag           <= {TAG_SIZE{1'b0}};
            block_of_data <= {BLOCK_SIZE * WORD_SIZE * 8{1'b0}};
            age_bits      <= 2'b00;
            dirty_bit     <= 1'b0;

            // Outputs also reset
            data          <= 8'd0;
            age           <= 2'b00;
            hit_miss      <= 1'b0;
            is_empty      <= 1'b1;  // “empty” when not valid
        end else begin
            // Every clock, update outputs from their “next” registers:
            // 1) Compute hit/miss (registered)
            hit_miss <= matching_tags & valid_bit;

            // 2) Data read/write behavior if ready
            if (ready) begin
                if (try_read) begin
                    if (matching_tags & valid_bit) begin
                        // On a read‐hit: extract 8 bits from block_of_data
                        data <= block_of_data[byte_index-:8];
                        // (No change to valid_bit, tag, or dirty_bit)
                    end else begin
                        // On a read‐miss: bring in a new line (dummy value here)
                        valid_bit     <= 1'b1;
                        // TODO: Replace this with “read data from lower memory”
                        block_of_data <= {BLOCK_SIZE * WORD_SIZE * 8{1'b0}};
                        // Just fill with zeros for now (instead of $random)
                        tag           <= addr_tag;
                        dirty_bit     <= 1'b0;
                        data          <= block_of_data[byte_index-:8];
                    end
                end

                if (try_write) begin
                    if (matching_tags & valid_bit) begin
                        // On a write‐hit: update the one byte
                        // We must update block_of_data at byte_index..byte_index-7
                        block_of_data[byte_index-:8] <= write_data;
                        dirty_bit                    <= 1'b1;
                        data                         <= write_data;
                    end else begin
                        // On a write‐miss: bring in a new line, mark dirty, then write
                        valid_bit                    <= 1'b1;
                        // TODO: Replace this with real read from lower memory, then rewrite:
                        block_of_data                <= {BLOCK_SIZE * WORD_SIZE * 8{1'b0}};
                        dirty_bit                    <= 1'b1;
                        tag                          <= addr_tag;

                        // Now store the new write_data byte into that position:
                        block_of_data[byte_index-:8] <= write_data;
                        data                         <= write_data;
                    end
                end

                // 3) Age management
                if (reset_age) begin
                    age_bits <= 2'b00;
                end else if (increment_age) begin
                    age_bits <= age_bits + 1;
                end
            end

            // 4) At the end of the clock, update registered outputs that track “internal”
            age      <= age_bits;
            is_empty <= ~valid_bit;
        end
    end

endmodule
