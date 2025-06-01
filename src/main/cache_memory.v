//==============================================================================
// File: cache_memory.v
// Description:
//   Top‐level cache memory module for a 128‐set, 4‐way set‐associative cache.
//   – Uses a 7→128 one‐hot decoder to select which set is active based on the
//     address field.
//   – Routes control signals (try_read, try_write, reset_age, increment_age) to
//     the active set via tri‐state drivers.
//   – Instantiates 128 copies of four_way_set, each containing four cache lines.
//   – Collects per‐set outputs (data byte, age vector, hit/miss flag, hit/miss mask)
//     from all sets, then uses 128→1 multiplexers to select the outputs of the
//     active set, producing the final data, ages, hit_miss, and hit_miss_set.
//
// Parameters:
//   ADDRESS_WORD_SIZE – Width of the full memory address in bits (e.g., 32).
//   TAG_SIZE          – Number of high‐order bits used as the tag (e.g., 19).
//   BLOCK_SIZE        – Number of words per cache block (e.g., 16).
//   WORD_SIZE         – Number of bytes per word (e.g., 4).
//   NUMBER_OF_SETS    – Number of cache sets in the cache (must be a power of two, e.g., 128).
//
// Ports:
//   input  clk                          – System clock. Rising edge drives all sequential logic.
//   input  rst_b                        – Active‐low reset. Clears all internal state in sets.
//   input  [ADDRESS_WORD_SIZE-1:0] address_word
//                                        – Full address. Top TAG_SIZE bits are tag, next 7 bits
//                                          index the set, lower bits index block/byte within set.
//   input  try_read                     – Global read request. Routed to the selected set.
//   input  try_write                    – Global write request. Routed to the selected set.
//   input  [7:0] write_data             – One byte of data to write on a write hit/miss.
//   input  [3:0] reset_age              – 4‐bit age‐reset vector (for all ways). Routed to chosen set.
//   input  [3:0] increment_age          – 4‐bit age‐increment vector (for all ways). Routed to chosen set.
//
//   output [7:0] data                   – One‐byte read data from the active set.
//   output [7:0] ages                   – Concatenated 4×2‐bit age fields from the active set.
//   output       hit_miss                – High if the active set reported a hit.
//   output [3:0] hit_miss_set            – One‐hot mask of which way hit within the active set.
//
// Internal Signals:
//   wire [NUMBER_OF_SETS-1:0] active     – One‐hot select for each set (decoded from address).
//   wire [NUMBER_OF_SETS-1:0] try_read_w – Per‐set routed try_read (only one bit active).
//   wire [NUMBER_OF_SETS-1:0] try_write_w– Per‐set routed try_write (only one bit active).
//   wire [4*NUMBER_OF_SETS-1:0] reset_age_w
//                                        – Per‐set 4‐bit age‐reset buses (only active set drives its slice).
//   wire [4*NUMBER_OF_SETS-1:0] increment_age_w
//                                        – Per‐set 4‐bit age‐increment buses similarly.
//   wire [8*NUMBER_OF_SETS-1:0] data_w    – Per‐set 8‐bit data outputs from each four_way_set.
//   wire [8*NUMBER_OF_SETS-1:0] ages_w    – Per‐set 8‐bit age outputs (4×2 bits) from each four_way_set.
//   wire [NUMBER_OF_SETS-1:0] hit_miss_w  – Per‐set hit/miss outputs from each four_way_set.
//   wire [4*NUMBER_OF_SETS-1:0] hit_miss_set_w
//                                        – Per‐set 4‐bit hit/miss mask outputs from each four_way_set.
//
//==============================================================================

module cache_memory #(
    parameter ADDRESS_WORD_SIZE = 32,  // Width of full address
    parameter TAG_SIZE          = 19,  // Number of tag bits
    parameter BLOCK_SIZE        = 16,  // Words per block
    parameter WORD_SIZE         = 4,   // Bytes per word
    parameter NUMBER_OF_SETS    = 128  // Total sets (must be power of 2)
) (
    input wire                         clk,           // System clock
    input wire                         rst_b,         // Active‐low reset
    input wire [ADDRESS_WORD_SIZE-1:0] address_word,  // Full address
    input wire                         try_read,      // Read request
    input wire                         try_write,     // Write request
    input wire [                  7:0] write_data,    // Write data byte
    input wire [                  3:0] reset_age,     // Age‐reset (all ways)
    input wire [                  3:0] increment_age, // Age‐increment (all ways)

    output wire [7:0] data,         // Read data from active set
    output wire [7:0] ages,         // Ages of 4 ways in active set
    output wire       hit_miss,     // Did the active set hit?
    output wire [3:0] hit_miss_set  // Which way in active set hit?
);

    //-------------------------------------------------------------------------
    // 1) Decode the set index (7 bits) into a one‐hot vector of length NUMBER_OF_SETS.
    //    address_word[ADDRESS_WORD_SIZE-1 : ADDRESS_WORD_SIZE-TAG_SIZE] is the tag.
    //    Next 7 bits are at [ADDRESS_WORD_SIZE-TAG_SIZE-1 -: 7].
    //-------------------------------------------------------------------------
    wire [NUMBER_OF_SETS-1:0] active;
    decoder #(
        .N(7),              // 7‐bit index → 128 outputs
        .W(NUMBER_OF_SETS)  // Should equal 1<<7
    ) dec7to128 (
        .index (address_word[ADDRESS_WORD_SIZE-TAG_SIZE-1-:7]),
        .active(active)
    );

    //-------------------------------------------------------------------------
    // 2) For each set, route the global control signals via tri‐state drivers:
    //    – try_read, try_write are 1‐bit signals
    //    – reset_age, increment_age are 4‐bit vectors (one bit per way)
    //    Only the active set’s slice will see the true signal; all others float (Z).
    //-------------------------------------------------------------------------
    wire [  NUMBER_OF_SETS-1:0] try_read_w;
    wire [  NUMBER_OF_SETS-1:0] try_write_w;
    wire [4*NUMBER_OF_SETS-1:0] reset_age_w;
    wire [4*NUMBER_OF_SETS-1:0] increment_age_w;

    generate
        genvar i;
        for (i = 0; i < NUMBER_OF_SETS; i = i + 1) begin : tristate_drivers
            // Route try_read to set[i]
            tristate_driver #(
                .w(1)
            ) tri_read_inst (
                .in    (try_read),
                .enable(active[i]),
                .out   (try_read_w[i])
            );

            // Route try_write to set[i]
            tristate_driver #(
                .w(1)
            ) tri_write_inst (
                .in    (try_write),
                .enable(active[i]),
                .out   (try_write_w[i])
            );

            // Route reset_age (4‐bit) to set[i]
            tristate_driver #(
                .w(4)
            ) tri_reset_inst (
                .in    (reset_age),
                .enable(active[i]),
                .out   (reset_age_w[4*i+:4])
            );

            // Route increment_age (4‐bit) to set[i]
            tristate_driver #(
                .w(4)
            ) tri_increment_inst (
                .in    (increment_age),
                .enable(active[i]),
                .out   (increment_age_w[4*i+:4])
            );
        end
    endgenerate

    //-------------------------------------------------------------------------
    // 3) Instantiate NUMBER_OF_SETS copies of four_way_set.
    //    Each one gets:
    //      • clk, rst_b
    //      • Full address_word (for tag comparison inside the set)
    //      • Per‐set control signals: try_read_w[i], try_write_w[i]
    //      • write_data (same for all sets)
    //      • reset_age_w[4*i +: 4], increment_age_w[4*i +: 4]
    //    Each produces:
    //      • data_w[8*i +: 8]       – 8‐bit data output
    //      • ages_w[8*i +: 8]       – 8‐bit age output (4×2 bits)
    //      • hit_miss_w[i]          – 1‐bit hit/miss flag
    //      • hit_miss_set_w[4*i+:4] – 4‐bit per‐way hit mask
    //-------------------------------------------------------------------------
    wire [8*NUMBER_OF_SETS-1:0] data_w;
    wire [8*NUMBER_OF_SETS-1:0] ages_w;
    wire [  NUMBER_OF_SETS-1:0] hit_miss_w;
    wire [4*NUMBER_OF_SETS-1:0] hit_miss_set_w;

    generate
        genvar j;
        for (j = 0; j < NUMBER_OF_SETS; j = j + 1) begin : sets
            four_way_set #(
                .ADDRESS_WORD_SIZE(ADDRESS_WORD_SIZE),
                .TAG_SIZE         (TAG_SIZE),
                .BLOCK_SIZE       (BLOCK_SIZE),
                .WORD_SIZE        (WORD_SIZE)
            ) cache_set_inst (
                // Inputs:
                .clk          (clk),
                .rst_b        (rst_b),
                .address_word (address_word),
                .try_read     (try_read_w[j]),
                .try_write    (try_write_w[j]),
                .write_data   (write_data),
                .reset_age    (reset_age_w[4*j+:4]),
                .increment_age(increment_age_w[4*j+:4]),
                // Outputs:
                .data         (data_w[8*j+:8]),
                .ages         (ages_w[8*j+:8]),
                .hit_miss     (hit_miss_w[j]),
                .hit_miss_set (hit_miss_set_w[4*j+:4])
            );
        end
    endgenerate

    //-------------------------------------------------------------------------
    // 4) Finally, select outputs from the active set using 128→1 multiplexers:
    //    – data_w is 1024 bits (128×8): select 8‐bit chunk based on set index.
    //    – ages_w is 1024 bits (128×8): select 8‐bit chunk based on set index.
    //    – hit_miss_w is 128 bits: select 1 bit based on set index.
    //    – hit_miss_set_w is 512 bits (128×4): select 4‐bit chunk based on set index.
    //    Use muxNto1 with SEL_WIDTH=7 (since 2^7 = 128).
    //-------------------------------------------------------------------------
    mux #(
        .SEL_WIDTH(7),  // 7‐bit select for 128 channels
        .w        (8)   // each data channel is 8 bits
    ) mux_data_inst (
        .in (data_w),
        .sel(address_word[ADDRESS_WORD_SIZE-TAG_SIZE-1-:7]),
        .out(data)
    );

    mux #(
        .SEL_WIDTH(7),
        .w        (8)   // each ages channel is 8 bits
    ) mux_ages_inst (
        .in (ages_w),
        .sel(address_word[ADDRESS_WORD_SIZE-TAG_SIZE-1-:7]),
        .out(ages)
    );

    mux #(
        .SEL_WIDTH(7),
        .w        (1)   // each hit_miss channel is 1 bit
    ) mux_hit_inst (
        .in (hit_miss_w),
        .sel(address_word[ADDRESS_WORD_SIZE-TAG_SIZE-1-:7]),
        .out(hit_miss)
    );

    mux #(
        .SEL_WIDTH(7),
        .w        (4)   // each hit_miss_set channel is 4 bits
    ) mux_hit_set_inst (
        .in (hit_miss_set_w),
        .sel(address_word[ADDRESS_WORD_SIZE-TAG_SIZE-1-:7]),
        .out(hit_miss_set)
    );

endmodule
