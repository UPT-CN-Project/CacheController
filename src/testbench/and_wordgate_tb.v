module and_wordgate_tb;

    reg [7:0] in;
    wire AND_;

    and_wordgate uut (
        .in  (in),
        .AND_(AND_)
    );

    initial begin
        // Test case 1: All bits are 1
        in = 8'b11111111;
        #10;
        if (AND_ !== 1'b1) $display("Test case 1 failed: expected 1, got %b", AND_);

        // Test case 2: One bit is 0
        in = 8'b11111110;
        #10;
        if (AND_ !== 1'b0) $display("Test case 2 failed: expected 0, got %b", AND_);

        // Test case 3: All bits are 0
        in = 8'b00000000;
        #10;
        if (AND_ !== 1'b0) $display("Test case 3 failed: expected 0, got %b", AND_);

        // Test case 4: Mixed bits
        in = 8'b10101010;
        #10;
        if (AND_ !== 1'b0) $display("Test case 4 failed: expected 0, got %b", AND_);

        $display("All test cases passed!");

        $finish;
    end
endmodule
