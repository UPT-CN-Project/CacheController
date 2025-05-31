module bitwise_comparator_tb;

    reg [7:0] in_0;
    reg [7:0] in_1;
    wire eq;

    bitwise_comparator uut (
        .in_0(in_0),
        .in_1(in_1),
        .eq  (eq)
    );

    initial begin
        // Test case 1: Equal inputs
        in_0 = 8'b10101010;
        in_1 = 8'b10101010;
        #10;
        if (eq !== 1'b1) $display("Test case 1 failed: expected 1, got %b", eq);

        // Test case 2: Different inputs
        in_0 = 8'b11110000;
        in_1 = 8'b00001111;
        #10;
        if (eq !== 1'b0) $display("Test case 2 failed: expected 0, got %b", eq);

        // Test case 3: All bits different
        in_0 = 8'b11001100;
        in_1 = 8'b00110011;
        #10;
        if (eq !== 1'b0) $display("Test case 3 failed: expected 0, got %b", eq);

        // Test case 4: All bits same but different from first test
        in_0 = 8'b11111111;
        in_1 = 8'b11111111;
        #10;
        if (eq !== 1'b1) $display("Test case 4 failed: expected 1, got %b", eq);

        $display("All test cases passed!");

        $finish;
    end
endmodule
