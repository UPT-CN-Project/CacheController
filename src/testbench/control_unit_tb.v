module control_unit_tb;
    reg clk;
    reg rst_b;
    reg opcode;
    reg hit_miss;
    reg [3:0] hit_miss_set;
    reg [7:0] ages;
    wire [31:0] address_word;
    wire try_read;
    wire try_write;
    wire [7:0] write_data;
    wire [3:0] reset_age;
    wire [3:0] increment_age;

    control_unit uut (
        .clk(clk),
        .rst_b(rst_b),
        .opcode(opcode),
        .hit_miss(hit_miss),
        .hit_miss_set(hit_miss_set),
        .ages(ages),
        .address_word(address_word),
        .try_read(try_read),
        .try_write(try_write),
        .write_data(write_data),
        .reset_age(reset_age),
        .increment_age(increment_age)
    );

    localparam RST_PULSE = 10;
    localparam CLK_CYCLES = 20;
    localparam CLK_PERIOD = 100;

    initial begin
        clk = 1'b0;
        repeat (2 * CLK_CYCLES) #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        rst_b = 1'b1;
        #(RST_PULSE) rst_b = 1'b0;
    end

    initial begin
        opcode = $urandom_range(0, 1);
        repeat (CLK_CYCLES) #(CLK_PERIOD) opcode = $urandom_range(0, 1);
    end

    initial begin
        hit_miss = $urandom_range(0, 1);
        repeat (CLK_CYCLES) #(CLK_PERIOD) hit_miss = $urandom_range(0, 1);
    end

    integer i;
    initial begin
        i = $urandom_range(0, 3);
        hit_miss_set = 4'd0;
        hit_miss_set[i] = 1'b1;
        repeat (CLK_CYCLES) begin
            #(CLK_PERIOD) i = $urandom_range(0, 3);
            hit_miss_set = 4'd0;
            hit_miss_set[i] = 1'b1;
        end
    end

    initial begin
        ages[1:0] = $urandom_range(0, 3);
        ages[3:2] = ages[1:0] + 2'b01;
        ages[5:4] = ages[3:2] + 2'b01;
        ages[7:6] = ages[5:4] + 2'b01;
        repeat (CLK_CYCLES) begin
            #(CLK_PERIOD) ages[1:0] = $urandom_range(0, 3);
            ages[3:2] = ages[1:0] + 2'b01;
            ages[5:4] = ages[3:2] + 2'b01;
            ages[7:6] = ages[5:4] + 2'b01;
        end
    end

endmodule
