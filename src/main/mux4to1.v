module mux4to1 #(
    parameter w = 64
) (
    input  [w-1:0] in_0,
    input  [w-1:0] in_1,
    input  [w-1:0] in_2,
    input  [w-1:0] in_3,
    input  [  1:0] sel,
    output [w-1:0] out
);

    assign out = (sel == 2'b00) ? in_0 : {w{1'bz}};
    assign out = (sel == 2'b01) ? in_1 : {w{1'bz}};
    assign out = (sel == 2'b10) ? in_2 : {w{1'bz}};
    assign out = (sel == 2'b11) ? in_3 : {w{1'bz}};

endmodule
