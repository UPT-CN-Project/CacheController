// Uses the dec7to128 decoder to activate the appropriate set based on the address.
// Employs tristate_driver modules to route the try_read, try_write, reset_age, and increment_age signals to the selected set.
// Each cache set is managed by a four_way_set module, which handles the actual storage and retrieval of data.
// Uses mux128to1 modules to select the appropriate data, age, and hit/miss outputs from the sets based on the address.

module cache_memory #(
    parameter ADDRESS_WORD_SIZE = 32,
    parameter TAG_SIZE = 19,
    parameter BLOCK_SIZE = 16,
    parameter WORD_SIZE = 4,
    parameter NUMBER_OF_SETS = 128
) (
    input clk,
    input rst_b,
    input [ADDRESS_WORD_SIZE-1:0] address_word,
    input try_read,
    input try_write,
    input [7:0] write_data,
    input [3:0] reset_age,
    input [3:0] increment_age,
    output [7:0] data,
    output [7:0] ages,
    output hit_miss,
    output [3:0] hit_miss_set
);

    wire [127:0] active;

    dec7to128 uut_decoder (
        .index (address_word[ADDRESS_WORD_SIZE-TAG_SIZE-1-:7]),
        .active(active)
    );

    wire [  NUMBER_OF_SETS-1:0] try_read_w;
    wire [  NUMBER_OF_SETS-1:0] try_write_w;
    wire [4*NUMBER_OF_SETS-1:0] reset_age_w;
    wire [4*NUMBER_OF_SETS-1:0] increment_age_w;

    generate
        genvar i;
        for (i = 0; i < NUMBER_OF_SETS; i = i + 1) begin : tristate_drivers
            tristate_driver #(
                .w(1)
            ) uut_tri_read (
                .in(try_read),
                .enable(active[i]),
                .out(try_read_w[i])
            );
            tristate_driver #(
                .w(1)
            ) uut_tri_write (
                .in(try_write),
                .enable(active[i]),
                .out(try_write_w[i])
            );
            tristate_driver #(
                .w(4)
            ) uut_tri_reset (
                .in(reset_age),
                .enable(active[i]),
                .out(reset_age_w[4*i+3:4*i])
            );
            tristate_driver #(
                .w(4)
            ) uut_tri_increment (
                .in(increment_age),
                .enable(active[i]),
                .out(increment_age_w[4*i+3:4*i])
            );
        end
    endgenerate

    wire [8*NUMBER_OF_SETS-1:0] data_w;
    wire [8*NUMBER_OF_SETS-1:0] ages_w;
    wire [  NUMBER_OF_SETS-1:0] hit_miss_w;
    wire [4*NUMBER_OF_SETS-1:0] hit_miss_set_w;

    generate
        genvar j;
        for (j = 0; j < NUMBER_OF_SETS; j = j + 1) begin : sets
            four_way_set #(
                .ADDRESS_WORD_SIZE(ADDRESS_WORD_SIZE),
                .TAG_SIZE(TAG_SIZE),
                .BLOCK_SIZE(BLOCK_SIZE),
                .WORD_SIZE(WORD_SIZE)
            ) set (
                .clk(clk),
                .rst_b(rst_b),
                .address_word(address_word),
                .try_read(try_read_w[j]),
                .try_write(try_write_w[j]),
                .write_data(write_data),
                .reset_age(reset_age_w[4*j+3:4*j]),
                .increment_age(increment_age_w[4*j+3:4*j]),
                .data(data_w[8*j+7:8*j]),
                .ages(ages_w[8*j+7:8*j]),
                .hit_miss(hit_miss_w[j]),
                .hit_miss_set(hit_miss_set_w[4*j+3:4*j])
            );
        end
    endgenerate

    mux128to1 #(
        .w(8)
    ) uut_mux_data (
        .in (data_w),
        .sel(address_word[ADDRESS_WORD_SIZE-TAG_SIZE-1-:7]),
        .out(data)
    );

    mux128to1 #(
        .w(8)
    ) uut_mux_ages (
        .in (ages_w),
        .sel(address_word[ADDRESS_WORD_SIZE-TAG_SIZE-1-:7]),
        .out(ages)
    );

    mux128to1 #(
        .w(1)
    ) uut_mux_hit (
        .in (hit_miss_w),
        .sel(address_word[ADDRESS_WORD_SIZE-TAG_SIZE-1-:7]),
        .out(hit_miss)
    );

    mux128to1 #(
        .w(4)
    ) uut_mux_hit_set (
        .in (hit_miss_set_w),
        .sel(address_word[ADDRESS_WORD_SIZE-TAG_SIZE-1-:7]),
        .out(hit_miss_set)
    );

endmodule
