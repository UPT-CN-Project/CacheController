// The cache_controller module uses a control unit and cache memory to perform cache operations.
// The control unit handles control signals and determines the operation to be performed.
// The cache memory performs the actual read/write operations and maintains cache data.
// The testbench provides a controlled environment to test the cache controller's functionality, including clock signal generation, reset pulse, and random opcode generation.

module cache_controller #(
    parameter ADDRESS_WORD_SIZE = 32,
    parameter TAG_SIZE = 19,
    parameter BLOCK_SIZE = 16,
    parameter WORD_SIZE = 4,
    parameter NUMBER_OF_SETS = 128
) (
    input clk,
    input rst_b,
    input opcode,
    output [7:0] data,
    output hit_miss
);

    wire hit_miss_w;
    wire [3:0] hit_miss_set;
    wire [7:0] ages;
    wire [ADDRESS_WORD_SIZE-1:0] address_word;
    wire try_read;
    wire try_write;
    wire [7:0] write_data;
    wire [3:0] reset_age;
    wire [3:0] increment_age;

    control_unit #(
        .ADDRESS_WORD_SIZE(ADDRESS_WORD_SIZE)
    ) uut_control (
        .clk(clk),
        .rst_b(rst_b),
        .opcode(opcode),
        .hit_miss(hit_miss_w),
        .hit_miss_set(hit_miss_set),
        .ages(ages),
        .address_word(address_word),
        .try_read(try_read),
        .try_write(try_write),
        .write_data(write_data),
        .reset_age(reset_age),
        .increment_age(increment_age)
    );

    cache_memory #(
        .ADDRESS_WORD_SIZE(ADDRESS_WORD_SIZE),
        .TAG_SIZE(TAG_SIZE),
        .BLOCK_SIZE(BLOCK_SIZE),
        .WORD_SIZE(WORD_SIZE),
        .NUMBER_OF_SETS(NUMBER_OF_SETS)
    ) uut_cache (
        .clk(clk),
        .rst_b(rst_b),
        .address_word(address_word),
        .try_read(try_read),
        .try_write(try_write),
        .write_data(write_data),
        .reset_age(reset_age),
        .increment_age(increment_age),
        .data(data),
        .ages(ages),
        .hit_miss(hit_miss_w),
        .hit_miss_set(hit_miss_set)
    );

    assign hit_miss = hit_miss_w;

endmodule
