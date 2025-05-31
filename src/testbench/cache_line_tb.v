module cache_line_tb;
    reg clk;
    reg rst_b;
    reg ready;
    reg [31:0] address_word;
    reg try_read;
    reg try_write;
    reg [7:0] write_data;
    reg reset_age;
    reg increment_age;
    wire [7:0] data;
    wire [1:0] age;
    wire hit_miss;
    wire is_empty;

    cache_line uut (
        .clk(clk),
        .rst_b(rst_b),
        .ready(ready),
        .address_word(address_word),
        .try_read(try_read),
        .try_write(try_write),
        .write_data(write_data),
        .reset_age(reset_age),
        .increment_age(increment_age),
        .data(data),
        .age(age),
        .hit_miss(hit_miss),
        .is_empty(is_empty)
    );

    localparam RST_PULSE = 10;
    localparam CLK_CYCLES = 10;
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
        ready = 1'b1;
    end

    initial begin
        address_word = $random;
        repeat (CLK_CYCLES / 2) #(CLK_PERIOD * 2) address_word = $random;
    end

    initial begin
        try_read  = 1'b1;
        try_write = 1'b0;
        #(5 * CLK_CYCLES) try_read = ~try_read;
        try_write = ~try_write;
    end

    initial begin
        write_data = $urandom_range(0, 255);
        repeat (CLK_CYCLES) #(CLK_PERIOD) write_data = $urandom_range(0, 255);
    end

    initial begin
        reset_age = $urandom_range(0, 1);
        increment_age = ~reset_age;
        repeat (CLK_CYCLES) begin
            #(CLK_PERIOD) reset_age = $urandom_range(0, 1);
            increment_age = ~reset_age;
        end
    end

    initial begin
        $display("Cache Line Testbench Started");
    end

endmodule
