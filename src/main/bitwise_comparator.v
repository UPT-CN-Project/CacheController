module bitwise_comparator #(
    parameter w = 8
) (
    input [w-1:0] in_0,
    input [w-1:0] in_1,
    output eq
);

    wire [w-1:0] bitwise_eq;

    generate
        genvar i;
        for (i = 0; i < w; i = i + 1) begin : comp_instances
            bit_comparator uut (
                .b0(in_0[i]),
                .b1(in_1[i]),
                .eq(bitwise_eq[i])
            );
        end
    endgenerate

    and_wordgate #(
        .w(w)
    ) uut (
        .in  (bitwise_eq),
        .AND_(eq)
    );

endmodule
