module mux128to1 #(
    parameter w = 8
) (
    input [w*128-1:0] in,
    input [6:0] sel,
    output [w-1:0] out
);

    assign out = in[sel*w+:w];

endmodule
