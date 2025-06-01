//==============================================================================
// Module: mux4to1
// Description:
//   Parameterizable 4-to-1 multiplexer. Selects one of four w-bit input buses
//   (in_0 through in_3) based on the 2-bit select signal `sel`. The chosen input
//   is driven to the output `out`. All other inputs are effectively tri-stated
//   via high-impedance assignments so that only the selected input drives `out`.
//
// Parameters:
//   w – Width (in bits) of each input and the output. Default is 64 bits.
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
//   input  [1:0]   sel
//     – 2-bit select signal (values 00, 01, 10, 11) to choose which input appears on `out`.
//   output [w-1:0] out
//     – The w-bit output bus carrying the value of the selected input. If `sel` is
//       outside 0–3 (which shouldn’t happen in normal usage), `out` will be all high-Z.
//
// Behavior:
//   – If sel == 2’b00, out = in_0;
//   – If sel == 2’b01, out = in_1;
//   – If sel == 2’b10, out = in_2;
//   – If sel == 2’b11, out = in_3;
//   – Otherwise (theoretically unreachable), out is driven to high-impedance (all bits = Z).
//   Each assign statement uses a conditional (ternary) operator: if the condition is true,
//   it selects the corresponding input; otherwise it assigns a w-bit vector of ‘z’ (tri-state).
//
// Usage Notes:
//   – Use this module when you need to route one of four equally wide buses onto a single
//     output in purely combinational logic. The high-impedance assignments ensure that only
//     the chosen input drives `out`, and synthesis tools will implement this as a multiplexed
//     routing rather than actual tri-state busses (on an FPGA, for example).
//   – To instantiate for a different width (e.g., 32 bits), override the parameter:
//       mux4to1 #(.w(32)) my_mux32 ( … );
//
// Example Instantiation (for 8-bit buses):
//   mux4to1 #(.w(8)) my_mux8 (
//       .in_0  (bus0[7:0]),
//       .in_1  (bus1[7:0]),
//       .in_2  (bus2[7:0]),
//       .in_3  (bus3[7:0]),
//       .sel   (select_index[1:0]),
//       .out   (selected_byte[7:0])
//   );
//
//==============================================================================

module mux4to1 #(
    parameter w = 64  // Number of bits per input/output bus
) (
    input  wire [w-1:0] in_0,  // First input bus
    input  wire [w-1:0] in_1,  // Second input bus
    input  wire [w-1:0] in_2,  // Third input bus
    input  wire [w-1:0] in_3,  // Fourth input bus
    input  wire [  1:0] sel,   // Select signal (00..11)
    output wire [w-1:0] out    // Output bus (driven by selected input)
);

    // If sel == 00, drive out with in_0; otherwise tri-state
    assign out = (sel == 2'b00) ? in_0 : {w{1'bz}};
    // If sel == 01, drive out with in_1; otherwise tri-state
    assign out = (sel == 2'b01) ? in_1 : {w{1'bz}};
    // If sel == 10, drive out with in_2; otherwise tri-state
    assign out = (sel == 2'b10) ? in_2 : {w{1'bz}};
    // If sel == 11, drive out with in_3; otherwise tri-state
    assign out = (sel == 2'b11) ? in_3 : {w{1'bz}};

endmodule
