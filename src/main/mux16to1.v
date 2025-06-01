//==============================================================================
// Module: mux16to1
// Description:
//   Parameterizable 16-to-1 multiplexer. Selects one of sixteen w-bit input buses
//   (in_0 through in_15) based on the 4-bit select signal `sel`. The selected input
//   is driven to the output `out`. All other inputs are effectively tri-stated via
//   high-impedance assignments so that only the chosen input drives `out`.
//
// Parameters:
//   w – Width (in bits) of each input and the output bus. Default is 64 bits.
//
// Ports:
//   input  [w-1:0] in_0
//     – First data input bus (w bits).
//   input  [w-1:0] in_1
//     – Second data input bus (w bits).
//   input  [w-1:0] in_2
//     – Third data input bus (w bits).
//   input  [w-1:0] in_3
//     – Fourth data input bus (w bits).
//   input  [w-1:0] in_4
//     – Fifth data input bus (w bits).
//   input  [w-1:0] in_5
//     – Sixth data input bus (w bits).
//   input  [w-1:0] in_6
//     – Seventh data input bus (w bits).
//   input  [w-1:0] in_7
//     – Eighth data input bus (w bits).
//   input  [w-1:0] in_8
//     – Ninth data input bus (w bits).
//   input  [w-1:0] in_9
//     – Tenth data input bus (w bits).
//   input  [w-1:0] in_10
//     – Eleventh data input bus (w bits).
//   input  [w-1:0] in_11
//     – Twelfth data input bus (w bits).
//   input  [w-1:0] in_12
//     – Thirteenth data input bus (w bits).
//   input  [w-1:0] in_13
//     – Fourteenth data input bus (w bits).
//   input  [w-1:0] in_14
//     – Fifteenth data input bus (w bits).
//   input  [w-1:0] in_15
//     – Sixteenth data input bus (w bits).
//   input  [3:0]   sel
//     – 4-bit select signal (values 0000..1111) to choose which input appears on `out`.
//   output [w-1:0] out
//     – The w-bit output bus carrying the value of the selected input. If `sel` is
//       outside 0–15 (which shouldn’t happen), `out` will be all high-Z.
//
// Behavior:
//   – If sel == 4’b0000, out = in_0; otherwise out = Z.
//   – If sel == 4’b0001, out = in_1; otherwise out = Z.
//   ...
//   – If sel == 4’b1111, out = in_15; otherwise out = Z.
//   Only one of these drives `out` at a time; all others tri-state.
//
// Usage Notes:
//   – Use this module when you need to route one of sixteen equally wide buses onto
//     a single output in combinational logic. The high-impedance assignments ensure
//     that only the chosen input drives `out`, and synthesis tools will implement this
//     as a multiplexer rather than actual tri-state buffers in most FPGA flows.
//   – To instantiate for a different width (e.g., 32 bits), override the parameter:
//       mux16to1 #(.w(32)) my_mux32 ( … );
//   – Ensure that no more than one driver is active at any time to avoid bus contention.
//
// Example Instantiation (for 64-bit buses):
//   mux16to1 #(.w(64)) u_mux16 (
//       .in_0  (bus0[63:0]),
//       .in_1  (bus1[63:0]),
//       .in_2  (bus2[63:0]),
//       .in_3  (bus3[63:0]),
//       .in_4  (bus4[63:0]),
//       .in_5  (bus5[63:0]),
//       .in_6  (bus6[63:0]),
//       .in_7  (bus7[63:0]),
//       .in_8  (bus8[63:0]),
//       .in_9  (bus9[63:0]),
//       .in_10 (bus10[63:0]),
//       .in_11 (bus11[63:0]),
//       .in_12 (bus12[63:0]),
//       .in_13 (bus13[63:0]),
//       .in_14 (bus14[63:0]),
//       .in_15 (bus15[63:0]),
//       .sel   (select_index[3:0]),
//       .out   (selected_data[63:0])
//   );
//
//==============================================================================

module mux16to1 #(
    parameter w = 64  // Width of each input/output bus (default 64 bits)
) (
    input  wire [w-1:0] in_0,   // Input channel 0
    input  wire [w-1:0] in_1,   // Input channel 1
    input  wire [w-1:0] in_2,   // Input channel 2
    input  wire [w-1:0] in_3,   // Input channel 3
    input  wire [w-1:0] in_4,   // Input channel 4
    input  wire [w-1:0] in_5,   // Input channel 5
    input  wire [w-1:0] in_6,   // Input channel 6
    input  wire [w-1:0] in_7,   // Input channel 7
    input  wire [w-1:0] in_8,   // Input channel 8
    input  wire [w-1:0] in_9,   // Input channel 9
    input  wire [w-1:0] in_10,  // Input channel 10
    input  wire [w-1:0] in_11,  // Input channel 11
    input  wire [w-1:0] in_12,  // Input channel 12
    input  wire [w-1:0] in_13,  // Input channel 13
    input  wire [w-1:0] in_14,  // Input channel 14
    input  wire [w-1:0] in_15,  // Input channel 15
    input  wire [3:0]   sel,    // Select signal (0..15)
    output wire [w-1:0] out     // Output bus (driven by selected input)
);

    // Drive each input onto 'out' when 'sel' matches its index; otherwise tri-state.
    assign out = (sel == 4'b0000) ? in_0 : {w{1'bz}};
    assign out = (sel == 4'b0001) ? in_1 : {w{1'bz}};
    assign out = (sel == 4'b0010) ? in_2 : {w{1'bz}};
    assign out = (sel == 4'b0011) ? in_3 : {w{1'bz}};
    assign out = (sel == 4'b0100) ? in_4 : {w{1'bz}};
    assign out = (sel == 4'b0101) ? in_5 : {w{1'bz}};
    assign out = (sel == 4'b0110) ? in_6 : {w{1'bz}};
    assign out = (sel == 4'b0111) ? in_7 : {w{1'bz}};
    assign out = (sel == 4'b1000) ? in_8 : {w{1'bz}};
    assign out = (sel == 4'b1001) ? in_9 : {w{1'bz}};
    assign out = (sel == 4'b1010) ? in_10 : {w{1'bz}};
    assign out = (sel == 4'b1011) ? in_11 : {w{1'bz}};
    assign out = (sel == 4'b1100) ? in_12 : {w{1'bz}};
    assign out = (sel == 4'b1101) ? in_13 : {w{1'bz}};
    assign out = (sel == 4'b1110) ? in_14 : {w{1'bz}};
    assign out = (sel == 4'b1111) ? in_15 : {w{1'bz}};

endmodule
