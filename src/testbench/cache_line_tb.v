`timescale 1ns / 1ps

module cache_line_tb;
    //-------------------------------------------------------------------------
    // Testbench Parameters
    //-------------------------------------------------------------------------
    parameter ADDRESS_WORD_SIZE = 32;
    parameter TAG_SIZE = 19;
    parameter BLOCK_SIZE = 16;
    parameter WORD_SIZE = 4;

    //-------------------------------------------------------------------------
    // Clock & Reset
    //-------------------------------------------------------------------------
    reg                          clk;
    reg                          rst_b;

    //-------------------------------------------------------------------------
    // Inputs to cache_line
    //-------------------------------------------------------------------------
    reg                          ready;
    reg  [ADDRESS_WORD_SIZE-1:0] address_word;
    reg                          try_read;
    reg                          try_write;
    reg  [                  7:0] write_data;
    reg  [                  3:0] reset_age;  // only [0] used
    reg  [                  3:0] increment_age;  // only [0] used

    //-------------------------------------------------------------------------
    // Outputs from cache_line DUT (including valid & dirty)
    //-------------------------------------------------------------------------
    wire [                  7:0] data_out;
    wire [                  1:0] age_out;
    wire                         hit_miss_out;
    wire                         is_empty_out;
    wire                         valid_out;  // internal valid_bit
    wire                         dirty_out;  // internal dirty_bit

    //-------------------------------------------------------------------------
    // Instantiate the DUT (cache_line)
    //-------------------------------------------------------------------------
    cache_line #(
        .ADDRESS_WORD_SIZE(ADDRESS_WORD_SIZE),
        .TAG_SIZE         (TAG_SIZE),
        .BLOCK_SIZE       (BLOCK_SIZE),
        .WORD_SIZE        (WORD_SIZE)
    ) dut (
        .clk          (clk),
        .rst_b        (rst_b),
        .ready        (ready),
        .address_word (address_word),
        .try_read     (try_read),
        .try_write    (try_write),
        .write_data   (write_data),
        .reset_age    (reset_age[0]),
        .increment_age(increment_age[0]),

        .data    (data_out),
        .age     (age_out),
        .hit_miss(hit_miss_out),
        .is_empty(is_empty_out),
        .valid   (valid_out),
        .dirty   (dirty_out)
    );

    //-------------------------------------------------------------------------
    // Generate a 10 ns clock period (100 MHz)
    //-------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //-------------------------------------------------------------------------
    // Main test sequence
    //-------------------------------------------------------------------------
    initial begin
        // 1) Initialize everything
        rst_b         = 1'b0;
        ready         = 1'b0;
        address_word  = {ADDRESS_WORD_SIZE{1'b0}};
        try_read      = 1'b0;
        try_write     = 1'b0;
        write_data    = 8'h00;
        reset_age     = 4'b0000;
        increment_age = 4'b0000;

        // Hold reset low for two clock cycles
        @(posedge clk);
        @(posedge clk);
        rst_b = 1'b1;  // Release reset on this rising edge

        // One more edge for the IP to see rst_b=1
        @(posedge clk);

        // ==== Print initial state ====
        $display("\n===== After Reset =====");
        $display(" is_empty=%b | valid=%b | dirty=%b | hit_miss=%b | age=%0d | data=%0h",
                 is_empty_out, valid_out, dirty_out, hit_miss_out, age_out, data_out);

        //-------------------------------------------------------------------------
        // 2) READ MISS  (so the line becomes valid)
        //-------------------------------------------------------------------------
        @(posedge clk);
        address_word = 32'hA5A5_1234;
        ready        = 1'b1;
        try_read     = 1'b1;
        @(posedge clk);  // DUT processes read‐miss here
        ready    = 1'b0;
        try_read = 1'b0;

        #1;  // let outputs settle
        $display("\n===== After READ MISS (time %0t) =====", $time);
        $display(" is_empty=%b | valid=%b | dirty=%b | hit_miss=%b | age=%0d | data=%0h",
                 is_empty_out, valid_out, dirty_out, hit_miss_out, age_out, data_out);
        // Expect: is_empty=0, valid=1, dirty=0, hit_miss=0, age=0, data=00

        //-------------------------------------------------------------------------
        // 3) READ HIT
        //-------------------------------------------------------------------------
        @(posedge clk);
        address_word = 32'hA5A5_1234;
        ready        = 1'b1;
        try_read     = 1'b1;
        @(posedge clk);  // DUT processes read‐hit here
        ready    = 1'b0;
        try_read = 1'b0;

        #1;
        $display("\n===== After READ HIT (time %0t) =====", $time);
        $display(" is_empty=%b | valid=%b | dirty=%b | hit_miss=%b | age=%0d | data=%0h",
                 is_empty_out, valid_out, dirty_out, hit_miss_out, age_out, data_out);
        // Expect: is_empty=0, valid=1, dirty=0, hit_miss=1, age=0, data=00

        //-------------------------------------------------------------------------
        // 4) WRITE MISS
        //-------------------------------------------------------------------------
        @(posedge clk);
        address_word = 32'hDEAD_BEEF;
        write_data   = 8'h5A;
        ready        = 1'b1;
        try_write    = 1'b1;
        @(posedge clk);  // DUT processes write‐miss here
        ready     = 1'b0;
        try_write = 1'b0;

        #1;
        $display("\n===== After WRITE MISS (time %0t) =====", $time);
        $display(" is_empty=%b | valid=%b | dirty=%b | hit_miss=%b | age=%0d | data=%0h",
                 is_empty_out, valid_out, dirty_out, hit_miss_out, age_out, data_out);
        // Expect: is_empty=0, valid=1, dirty=1, hit_miss=0, age=0, data=5A

        //-------------------------------------------------------------------------
        // 5) WRITE HIT
        //-------------------------------------------------------------------------
        @(posedge clk);
        address_word = 32'hDEAD_BEEF;
        write_data   = 8'hA5;
        ready        = 1'b1;
        try_write    = 1'b1;
        @(posedge clk);  // DUT processes write‐hit here
        ready     = 1'b0;
        try_write = 1'b0;

        #1;
        $display("\n===== After WRITE HIT (time %0t) =====", $time);
        $display(" is_empty=%b | valid=%b | dirty=%b | hit_miss=%b | age=%0d | data=%0h",
                 is_empty_out, valid_out, dirty_out, hit_miss_out, age_out, data_out);
        // Expect: is_empty=0, valid=1, dirty=1, hit_miss=1, age=0, data=A5

        //-------------------------------------------------------------------------
        // 6) AGE MANAGEMENT (unconditionally updating age_bits)
        //-------------------------------------------------------------------------
        // --- 6.1) reset_age pulse ---
        @(posedge clk);
        reset_age = 4'b0001;  // assert at this rising edge
        @(posedge clk);
        reset_age = 4'b0000;  // deassert immediately next edge

        // Sample age right after the second rising edge
        #1;
        $display("\n===== After reset_age (time %0t) =====", $time);
        $display(" age=%0d", age_out);  // Expect age = 0

        // --- 6.2) First increment_age pulse ---
        @(posedge clk);
        increment_age = 4'b0001;  // assert at this rising edge

        @(posedge clk);
        increment_age = 4'b0000;  // deassert immediately next edge

        // Sample age right after the second edge
        #1;
        $display("\n===== After first increment_age (time %0t) =====", $time);
        $display(" age=%0d", age_out);  // Expect age = 1

        // --- 6.3) Second increment_age pulse ---
        @(posedge clk);
        increment_age = 4'b0001;

        @(posedge clk);
        increment_age = 4'b0000;

        #1;
        $display("\n===== After second increment_age (time %0t) =====", $time);
        $display(" age=%0d", age_out);  // Expect age = 2

        // --- 6.4) Third increment_age pulse ---
        @(posedge clk);
        increment_age = 4'b0001;

        @(posedge clk);
        increment_age = 4'b0000;

        #1;
        $display("\n===== After third increment_age (time %0t) =====", $time);
        $display(" age=%0d", age_out);  // Expect age = 3

        //-------------------------------------------------------------------------
        // 7) Finish
        //-------------------------------------------------------------------------
        @(posedge clk);
        $display("\n===== TEST COMPLETE (time %0t) =====\n", $time);
        $finish;
    end

endmodule
