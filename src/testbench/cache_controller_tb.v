module cache_controller_tb;
    reg clk;
    reg rst_b;
    reg opcode;
    wire [7:0] data;
    wire hit_miss;

    cache_controller uut (
        .clk(clk),
        .rst_b(rst_b),
        .opcode(opcode),
        .data(data),
        .hit_miss(hit_miss)
    );

    localparam RST_PULSE = 10;
    localparam CLK_CYCLES = 100;
    localparam CLK_PERIOD = 100;

    initial begin
        clk = 1'b0;
        repeat (2 * CLK_CYCLES) #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        rst_b = 1'b0;
        #(RST_PULSE) rst_b = 1'b1;
    end

    initial begin
        opcode = $urandom_range(0, 1);
        repeat (CLK_CYCLES) #(CLK_PERIOD) opcode = $urandom_range(0, 1);
    end

endmodule
