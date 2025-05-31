module tristate_driver #(
    parameter w = 8
) (
    input [w-1:0] in,
    input enable,
    output tri [w-1:0] out
);

    assign out = (enable) ? in : {w{1'bz}};

endmodule
