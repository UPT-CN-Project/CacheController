//==============================================================================
// Module: mux128to1
// Description:
//   A parameterizable wide‐bus 128‐to‐1 multiplexer. Selects one of 128 input
//   “channels,” each w bits wide, based on the 7‐bit select signal `sel`. The
//   selected w‐bit slice is driven to `out`.
//
// Parameters:
//   w – Width (in bits) of each input channel. Determines how many bits are
//       in each of the 128 slots. Default is 8.
//
// Ports:
//   input  [w*128-1:0] in
//     - Concatenated input bus containing 128 channels of width w each.
//       Channel i occupies bits [i*w + (w-1) : i*w].
//   input  [6:0] sel
//     - 7‐bit select index (0..127). Selects which w‐bit channel to route to `out`.
//   output [w-1:0] out
//     - The w‐bit output corresponding to the selected channel.
//
// Behavior:
//   out = in[ sel*w +: w ];
//   This syntax uses an indexed bit slice (`+: w`) to pick bits [sel*w + (w-1) : sel*w].
//   If sel = i, then out = in[i*w + (w-1) : i*w], for i in [0..127]. If sel is outside
//   0..127, synthesis tools will typically wrap or produce an undefined value—always
//   ensure sel is within range.
//
// Usage Notes:
//   - Use this module when you need a large 128‐way selection among equal‐width buses.
//   - Since 128 = 2^7, the select width is 7 bits. If you need more or fewer channels,
//     you can adjust the parameter or use a different sized mux (e.g., mux64to1, mux256to1).
//   - The implementation is purely combinational (no flip‐flops); changes on `in` or `sel`
//     immediately reflect on `out` (subject to propagation delay).
//
// Example Instantiation (for 16‐bit channels):
//   mux128to1 #(.w(16)) u_mux128 (
//       .in  (big_bus[2047:0]),  // 128×16 = 2048 bits
//       .sel (select_index[6:0]),
//       .out (selected_data[15:0])
//   );
//
//==============================================================================

module mux128to1 #(
    parameter w = 8  // Width of each input channel (in bits)
) (
    input  wire [w*128-1:0] in,   // 128‐channel wide input (concatenated)
    input  wire [      6:0] sel,  // 7‐bit selector (0..127)
    output wire [    w-1:0] out   // w‐bit output from the selected channel
);

    // Combinationally select w bits starting at index (sel * w)
    // The "+: w" notation picks a slice of width w beginning at bit sel*w.
    assign out = in[sel*w+:w];

endmodule
