//==============================================================================
// File: cache_line.v
// Description:
//   Implements a single cache line for a set‐associative cache. This module
//   tracks a valid bit, tag store, data block, dirty bit, and an “age” counter
//   (for LRU eviction). It responds to read and write requests when `ready` is
//   asserted, performs tag comparison to detect hits or misses, allocates on
//   miss, and updates age unconditionally when directed by the parent module.
//
// Parameters:
//   ADDRESS_WORD_SIZE – Width (in bits) of the full memory address word.
//   TAG_SIZE          – Number of high‐order bits used as the cache line’s tag.
//   BLOCK_SIZE        – Number of words per cache block (e.g., 16 words).
//   WORD_SIZE         – Number of bytes per word (in this design, 4 bytes).
//
// Ports:
//   input  clk              – System clock. All sequential updates occur on posedge.
//   input  rst_b            – Active‐low reset. Clears all internal state.
//   input  ready            – Assertion from parent set/FSM indicating this line
//                            is selected for the current access.
//   input  address_word     – Full address (ADDRESS_WORD_SIZE bits). Top TAG_SIZE bits
//                            form the tag; lower bits form block/byte offsets.
//   input  try_read         – Assert to indicate a read operation on this line.
//   input  try_write        – Assert to indicate a write operation on this line.
//   input  write_data[7:0]  – One byte of data to write into the line on write misses/hits.
//   input  reset_age        – When high at posedge(clk), resets this line’s age counter to 0.
//   input  increment_age    – When high at posedge(clk), increments this line’s age counter by 1.
//
//   output reg [7:0] data   – The byte output from this cache line on read hits.
//   output reg [1:0] age    – Current age counter (2 bits) used for LRU arbitration.
//   output reg       hit_miss – Indicates “1” on a tag match + valid on this cycle (read/write).
//   output reg       is_empty – “1” if this line is currently invalid (never allocated or reset).
//   output wire      valid  – Exposes internal valid_bit (1 when line holds valid data).
//   output wire      dirty  – Exposes internal dirty_bit (1 if line has been written and not yet
//                            written back on eviction).
//
// Internal Registers:
//   reg valid_bit                    – High if this line has been allocated (contains valid data).
//   reg [TAG_SIZE-1:0] tag           – Stored tag for this line.
//   reg [BLOCK_SIZE*WORD_SIZE*8-1:0] block_of_data
//                                    – Full block of data (BLOCK_SIZE words × WORD_SIZE bytes each).
//   reg [1:0] age_bits               – Internal age counter (updated by reset_age/ increment_age).
//   reg dirty_bit                    – High if the data in this line has been modified (write‐back).
//
// Internal Wires:
//   wire matching_tags               – High if stored tag == incoming tag (bitwise comparison).
//   wire [3:0] block_offset          – Which word index within the block (address bits [5:2]).
//   wire [1:0] word_offset           – Which byte index within the selected word (address bits [1:0]).
//   wire [8:0] byte_index            – Bit‐index offset into block_of_data for reading/writing one byte.
//   wire [TAG_SIZE-1:0] addr_tag      – The top TAG_SIZE bits of address_word for comparison.
//
// Behavior Summary:
//   • On reset (rst_b = 0): valid_bit=0, tag=0, block_of_data=0, age_bits=0, dirty_bit=0,
//     data=0, age=0, hit_miss=0, is_empty=1.
//   • On any posedge(clk):
//       1) Age logic (unconditional):
//          - If reset_age=1 → age_bits <= 0.
//          - Else if increment_age=1 → age_bits <= age_bits + 1.
//       2) Compute hit/miss: hit_miss <= matching_tags & valid_bit.
//       3) If ready=1, then process read/write:
//           a) try_read=1:
//                - If hit_miss (matching_tags & valid_bit) → data <= selected byte.
//                - Else (read miss) → allocate line (valid_bit=1, zero‐fill block_of_data,
//                  tag <= addr_tag, dirty_bit=0), and output zero‐filled byte.
//           b) try_write=1:
//                - If hit_miss → write one byte into block_of_data, dirty_bit=1, data <= write_data.
//                - Else (write miss) → allocate line (valid_bit=1, zero‐fill block, tag <= addr_tag,
//                  dirty_bit=1), then write one byte and data <= write_data.
//       4) Register outputs: age <= age_bits; is_empty <= ~valid_bit.
//
//==============================================================================

`timescale 1ns / 1ps

module cache_line #(
    parameter ADDRESS_WORD_SIZE = 32,  // Width of full address
    parameter TAG_SIZE          = 19,  // Number of tag bits
    parameter BLOCK_SIZE        = 16,  // Words per cache block
    parameter WORD_SIZE         = 4    // Bytes per word
) (
    input wire                         clk,           // System clock
    input wire                         rst_b,         // Active‐low reset
    input wire                         ready,         // Parent grants access to this line
    input wire [ADDRESS_WORD_SIZE-1:0] address_word,  // Full address word
    input wire                         try_read,      // Assert to perform read
    input wire                         try_write,     // Assert to perform write
    input wire [                  7:0] write_data,    // Data byte for writes
    input wire                         reset_age,     // Reset age_counter to 0
    input wire                         increment_age, // Increment age_counter by 1

    output reg [7:0] data,      // Byte read out on hit
    output reg [1:0] age,       // Current age counter
    output reg       hit_miss,  // High if tag match & valid
    output reg       is_empty,  // High if line is not valid

    // Exposed for monitoring / higher‐level eviction logic:
    output wire valid,  // 1 if line has valid data
    output wire dirty   // 1 if line has been written
);

    //-------------------------------------------------------------------------
    // Internal state registers
    //-------------------------------------------------------------------------
    reg valid_bit;  // 1 if line contains valid data
    reg [TAG_SIZE-1:0] tag;  // Stored tag bits
    reg [BLOCK_SIZE*WORD_SIZE*8-1:0] block_of_data;  // Full block of data bytes
    reg [1:0] age_bits;  // Internal age counter
    reg dirty_bit;  // 1 if data modified (write‐back)

    //-------------------------------------------------------------------------
    // Combinational signals for indexing and tag extraction
    //-------------------------------------------------------------------------
    wire [TAG_SIZE-1:0] addr_tag;  // High‐order TAG_SIZE bits from address_word
    wire matching_tags;  // 1 if tag == addr_tag & valid_bit=1

    wire [1:0] word_offset;  // Which byte within selected word (address_word[1:0])
    wire [3:0] block_offset;  // Which word within block (address_word[5:2])
    wire [8:0] byte_index;  // Bit‐index into block_of_data to select one byte

    // Extract the TAG_SIZE MSBs of address_word
    assign addr_tag = address_word[ADDRESS_WORD_SIZE-1 : ADDRESS_WORD_SIZE-TAG_SIZE];

    // Instantiate bitwise_comparator to compare tag vs. addr_tag
    bitwise_comparator #(
        .w(TAG_SIZE)
    ) comp (
        .in_0(tag),
        .in_1(addr_tag),
        .eq  (matching_tags)
    );

    // Determine byte_offset and block_offset
    assign word_offset = address_word[1:0];  // Lower 2 bits: byte index within 32‐bit word
    assign block_offset = address_word[5:2];  // Next 4 bits: word index within the cache block

    // Compute the bit index of the top of the selected byte in block_of_data:
    //   - block_offset << 5 = block_offset * (WORD_SIZE * 8) = block_offset * 32
    //   - (word_offset + 1) << 3 = (word_offset+1) * 8 → selects that byte’s MSB
    assign byte_index = (block_offset << 5)  // block_offset × 32 bits
        + ((word_offset + 1) << 3)  // + (word_offset+1) × 8 bits
        - 1;  // zero‐based indexing

    // Expose the internal valid_bit and dirty_bit on top‐level ports
    assign valid = valid_bit;
    assign dirty = dirty_bit;

    //-------------------------------------------------------------------------
    // Single sequential always block:
    //   • Reset logic (negedge rst_b).
    //   • Age counter update (independent of ready).
    //   • Hit/miss calculation (registered).
    //   • Read/write logic when ready is asserted.
    //   • Output registers: age and is_empty.
    //-------------------------------------------------------------------------
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            // Asynchronous reset: clear all internal state
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
            // 1) Age management (unconditional):
            //    - If reset_age, set age_bits=0.
            //    - Else if increment_age, age_bits += 1.
            //    - Otherwise, age_bits holds its value.
            // --------------------------------------------------
            if (reset_age) begin
                age_bits = 2'b00;
            end else if (increment_age) begin
                age_bits = age_bits + 1;
            end

            // --------------------------------------------------
            // 2) Compute hit/miss = (matching_tags & valid_bit)
            //    This is captured on each clock.
            // --------------------------------------------------
            hit_miss <= (matching_tags & valid_bit);

            // --------------------------------------------------
            // 3) Read / Write logic (only if ready=1 this cycle):
            //    • try_read:
            //        – If tag matches & valid_bit=1 → read hit: output byte from block_of_data.
            //        – Else → read miss: allocate new line: valid_bit=1, zero‐fill block, tag=addr_tag,
            //                 dirty_bit=0, output zero‐filled byte.
            //    • try_write:
            //        – If tag matches & valid_bit=1 → write hit: write one byte, set dirty_bit=1.
            //        – Else → write miss: allocate new line: valid_bit=1, zero‐fill block, tag=addr_tag,
            //                  dirty_bit=1, write one byte, output that byte.
            // --------------------------------------------------
            if (ready) begin
                // Handle read
                if (try_read) begin
                    if (matching_tags & valid_bit) begin
                        // Read‐hit: return the requested byte
                        data <= block_of_data[byte_index-:8];
                    end else begin
                        // Read‐miss: allocate line, zero‐fill, mark valid, tag=addr_tag
                        valid_bit     <= 1'b1;
                        block_of_data <= {BLOCK_SIZE * WORD_SIZE * 8{1'b0}};
                        tag           <= addr_tag;
                        dirty_bit     <= 1'b0;
                        data          <= block_of_data[byte_index-:8];  // zero‐filled
                    end
                end

                // Handle write
                if (try_write) begin
                    if (matching_tags & valid_bit) begin
                        // Write‐hit: update one byte, set dirty bit
                        block_of_data[byte_index-:8] <= write_data;
                        dirty_bit                    <= 1'b1;
                        data                         <= write_data;
                    end else begin
                        // Write‐miss: allocate line, zero‐fill, set valid, tag, then write byte
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
            // 4) Update registered outputs:
            //    age      <= age_bits (reflects the internal counter)
            //    is_empty <= ~valid_bit (line is empty if valid_bit=0)
            // --------------------------------------------------
            age      <= age_bits;
            is_empty <= ~valid_bit;
        end
    end

endmodule
