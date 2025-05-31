module dec7to128 (
    input  [  6:0] index,
    output [127:0] active
);
    assign active = 128'd1 << index;

endmodule
