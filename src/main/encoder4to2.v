module encoder4to2 (
    input  [3:0] in,
    output [1:0] out
);

    assign out = (in == 4'b0001) ? 2'b00 : 2'bzz;
    assign out = (in == 4'b0010) ? 2'b01 : 2'bzz;
    assign out = (in == 4'b0100) ? 2'b10 : 2'bzz;
    assign out = (in == 4'b1000) ? 2'b11 : 2'bzz;

endmodule
