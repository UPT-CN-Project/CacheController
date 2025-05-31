module bit_comparator (
    input  b0,
    input  b1,
    output eq
);

    assign eq = (b0 & b1) | (~b0 & ~b1);

endmodule
