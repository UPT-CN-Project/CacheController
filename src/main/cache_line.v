// cache_line.v
`timescale 1ns / 1ps

module cache_line #(
    parameter ADDRESS_WORD_SIZE = 32,
    parameter TAG_SIZE          = 19,
    parameter BLOCK_SIZE        = 16,
    parameter WORD_SIZE         = 4
) (
    input wire                         clk,
    input wire                         rst_b,
    input wire                         ready,         // permission from parent
    input wire [ADDRESS_WORD_SIZE-1:0] address_word,
    input wire                         try_read,
    input wire                         try_write,
    input wire [                  7:0] write_data,
    input wire                         reset_age,     // driven by parent
    input wire                         increment_age, // driven by parent

    output reg [7:0] data,
    output reg [1:0] age,
    output reg       hit_miss,
    output reg       is_empty,

    // === NEW OUTPUTS ===
    output wire valid,  // exposes internal valid_bit
    output wire dirty   // exposes internal dirty_bit
);

    // Internal state
    reg                                 valid_bit;
    reg  [                TAG_SIZE-1:0] tag;
    reg  [BLOCK_SIZE*WORD_SIZE*8 - 1:0] block_of_data;
    reg  [                         1:0] age_bits;
    reg                                 dirty_bit;

    // Combinational signals
    wire                                matching_tags;
    wire [                         3:0] block_offset;
    wire [                         1:0] word_offset;
    wire [                         8:0] byte_index;
    wire [                TAG_SIZE-1:0] addr_tag;

    // Compute the slice of address_word used as “tag”
    assign addr_tag = address_word[ADDRESS_WORD_SIZE-1 : ADDRESS_WORD_SIZE-TAG_SIZE];

    // Compare stored tag vs incoming tag
    bitwise_comparator #(
        .w(TAG_SIZE)
    ) comp (
        .in_0(tag),
        .in_1(addr_tag),
        .eq  (matching_tags)
    );

    // Byte/word/block offsets
    assign word_offset = address_word[1:0];  // which byte within 32‐bit word
    assign block_offset = address_word[5:2];  // which 32‐bit word within the 16‐word block

    // Compute the “top‐bit” of the selected byte
    // Each word = WORD_SIZE * 8 bits = 4 bytes * 8 = 32 bits ⇒ shift by 5 (<<5)
    // (word_offset + 1) * 8 − 1 picks the last bit in that byte
    assign byte_index = (block_offset << 5)  // block_offset * 32
        + ((word_offset + 1) << 3)  // (word_offset + 1) * 8
        - 1;  // zero‐based bit index

    // Expose the internal valid_bit and dirty_bit
    assign valid = valid_bit;
    assign dirty = dirty_bit;

    //----------------------------------------------------------------------
    // Single always block for reset + everything else
    //----------------------------------------------------------------------
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            // Reset all registers
            valid_bit     <= 1'b0;
            tag           <= {TAG_SIZE{1'b0}};
            block_of_data <= {BLOCK_SIZE * WORD_SIZE * 8{1'b0}};
            age_bits      <= 2'b00;
            dirty_bit     <= 1'b0;

            data          <= 8'd0;
            age           <= 2'b00;
            hit_miss      <= 1'b0;
            is_empty      <= 1'b1;
        end else begin
            // --------------------------------------------------
            // 1) Always update age_bits if either increment_age or reset_age is asserted
            // --------------------------------------------------
            if (reset_age) age_bits <= 2'b00;
            else if (increment_age) age_bits <= age_bits + 1;
            // else age_bits stays the same

            // --------------------------------------------------
            // 2) Compute hit/miss (registered)
            // --------------------------------------------------
            hit_miss <= (matching_tags & valid_bit);

            // --------------------------------------------------
            // 3) Do read/write logic ONLY when “ready” is asserted
            // --------------------------------------------------
            if (ready) begin
                if (try_read) begin
                    if (matching_tags & valid_bit) begin
                        // Read‐hit: pick the byte from the block
                        data <= block_of_data[byte_index-:8];
                    end else begin
                        // Read‐miss: allocate new line (zero‐fill for now), set tag
                        valid_bit     <= 1'b1;
                        block_of_data <= {BLOCK_SIZE * WORD_SIZE * 8{1'b0}};
                        tag           <= addr_tag;
                        dirty_bit     <= 1'b0;
                        data          <= block_of_data[byte_index-:8];
                    end
                end

                if (try_write) begin
                    if (matching_tags & valid_bit) begin
                        // Write‐hit: change that one byte, set dirty
                        block_of_data[byte_index-:8] <= write_data;
                        dirty_bit                    <= 1'b1;
                        data                         <= write_data;
                    end else begin
                        // Write‐miss: allocate new line, then write into that byte
                        valid_bit                    <= 1'b1;
                        block_of_data                <= {BLOCK_SIZE * WORD_SIZE * 8{1'b0}};
                        tag                          <= addr_tag;
                        dirty_bit                    <= 1'b1;
                        block_of_data[byte_index-:8] <= write_data;
                        data                         <= write_data;
                    end
                end
            end

            // --------------------------------------------------
            // 4) Always update “age” output and “is_empty” regardless of ready
            // --------------------------------------------------
            age      <= age_bits;
            is_empty <= ~valid_bit;
        end
    end

endmodule
