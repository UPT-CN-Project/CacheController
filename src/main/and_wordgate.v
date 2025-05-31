module and_wordgate #(
    parameter w = 8
) (
    input  wire [w-1:0] in,
    output reg          AND_
);

    integer i;
    always @(*) begin
        AND_ = 1'b1;
        for (i = 0; i < w; i = i + 1) begin
            AND_ = AND_ & in[i];
        end
    end
endmodule
