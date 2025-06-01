//==============================================================================
// Module: muxNto1
// Description:
//   Parameterizable N-to-1 multiplexer, implemented in a “slice”-indexed style
//   to avoid writing out many conditional assignments. Given a concatenated input
//   bus of N channels (each w bits wide) and a select index of SEL_WIDTH bits
//   (where SEL_WIDTH = log₂(N)), this module picks the w-bit slice corresponding
//   to the selected channel and drives it on `out`. All other channels are never
//   explicitly driven, so synthesis tools implement this as a standard combinational mux.
//
// Parameters:
//   SEL_WIDTH – Number of bits in the `sel` input. Determines the number of channels: N = 2^SEL_WIDTH.
//               For example, SEL_WIDTH=4 → N=16 channels. Default is 4 (i.e. a 16-to-1 mux).
//   w         – Width (in bits) of each individual input channel (and of the output).
//               Default is 8.
//
// Derived Parameters:
//   N         – Number of input channels = 1 << SEL_WIDTH.
//
// Ports:
//   input  [N*w-1:0]   in     – Concatenated input bus containing N channels, each w bits wide.
//                              Channel k occupies bits [ (k+1)*w - 1 : k*w ].
//   input  [SEL_WIDTH-1:0] sel – Select index (0 .. N-1). Determines which w-bit slice to route to `out`.
//   output [w-1:0]     out    – The selected w-bit output slice from `in`. If sel is out of range,
//                              synthesis tools will clamp or ignore bits, but in correct use sel∈[0..N-1].
//
// Behavior:
//   out = in[ sel*w +: w ];
//   The “+: w” syntax means “take a w-bit slice starting at bit (sel*w) of `in`.”
//   If sel = k, then this picks bits [ k*w + (w-1) : k*w ], which correspond to channel k.
//
// Usage Notes:
//   • This approach scales to any power-of-two number of channels without writing out 2^SEL_WIDTH
//     assigns or case branches.
//   • For a non-power-of-two mux, you can still pack them into the same bus and simply
//     ensure sel never exceeds the valid range; unused channels can be tied to zero or left
//     undefined as appropriate.
//   • Because this is purely combinational, changes in `in` or `sel` propagate immediately to `out`.
//   • If you are using Verilog-2001 or later, you can take advantage of the “+: w” part-select
//     syntax directly. In older Verilog-1995, you can replace that line with a generate loop or a
//     big case statement.
//
// Example Instantiation (16-to-1, 8-bit wide):
//   // SEL_WIDTH=4 → N=16 channels, each 8 bits wide
//   muxNto1 #(
//     .SEL_WIDTH(4),
//     .w        (8)
//   ) u_mux16to1 (
//     .in  ({ch15[7:0], ch14[7:0], ch13[7:0], ch12[7:0],
//            ch11[7:0], ch10[7:0], ch9 [7:0], ch8 [7:0],
//            ch7 [7:0], ch6 [7:0], ch5 [7:0], ch4 [7:0],
//            ch3 [7:0], ch2 [7:0], ch1 [7:0], ch0 [7:0]}), // channel0 is LSB slice
//     .sel (select_index[3:0]),    // 4-bit index selects among 16
//     .out (selected_data[7:0])    // 8-bit output
//   );
//
//==============================================================================

module muxNto1 #(
    parameter SEL_WIDTH = 4,  // Number of bits in `sel` → N = 2^SEL_WIDTH channels
    parameter w         = 8   // Width of each channel in bits
) (
    input  wire [(1<<SEL_WIDTH)*w -1 : 0] in,   // Concatenated bus of N channels
    input  wire [        SEL_WIDTH-1 : 0] sel,  // Select index (0..N-1)
    output wire [                w-1 : 0] out   // Selected w-bit output
);

    // A single‐line slice: take w bits starting at bit (sel * w)
    assign out = in[sel*w+:w];

endmodule
