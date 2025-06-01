//==============================================================================
// Module: decNto2N
// Description:
//   Parameterizable N-to-2^N one-hot decoder. Given an N-bit `index`, this module
//   produces a 2^N-bit `active` bus in which exactly one bit is high (1) and all
//   others are low (0). The high bit corresponds to the binary value of `index`.
//
// Parameters:
//   N  – Width of the index input. Determines how many output lines there are.
//         Default is 7, producing a 128-bit output.
//   W  – Number of output lines (2^N). Automatically computed as (1 << N).
//
// Ports:
//   input  [N-1:0] index
//     – N-bit binary index. Range [0 .. 2^N – 1]. Selects which single output bit
//       in `active` should be driven high.
//
//   output [W-1:0] active
//     – One-hot 2^N-bit output bus. Exactly one bit is '1' at the position specified
//       by `index`; all other bits are '0'.
//
// Behavior:
//   • If index == i (0 ≤ i < W), then active[i] = 1, and all other active[*] = 0.
//   • If index is outside [0..W-1] (should not happen in correct operation), the
//     synthesized behavior will effectively wrap or produce zeros—ensure index is
//     constrained to its valid range.
//
// Usage Notes:
//   • Instantiate this decoder whenever you need a one-hot selection among 2^N lines.
//   • Example: For a 4-way set‐associative cache, you might decode a 2‐bit LRU index
//     into a 4‐bit one-hot “way select.” In that case, set N=2, so W=4.
//   • The internal left‐shift operation ensures that the “1” is placed at bit position
//     `index` within an otherwise zeroed W-bit vector.
//
// Example Instantiation (original 7→128 decoder):
//   decoder #(
//       .N(7)           // 7-bit index
//       // W is implicitly 128 = 1 << 7
//   ) u_dec_7to128 (
//       .index  (address_index[6:0]),  // 0..127
//       .active (one_hot_out[127:0])   // one-hot 128-bit output
//   );
//
//==============================================================================

module decoder #(
    parameter N = 7,        // Width of index input
    parameter W = (1 << N)  // Number of output lines = 2^N
) (
    input  wire [N-1:0] index,  // N-bit select index
    output wire [W-1:0] active  // One-hot output of width 2^N
);

    // Internal vector whose LSB is '1' and all higher bits are '0'
    // This is W bits wide: { { (W-1){1'b0} }, 1'b1 }.
    // Shifting it left by 'index' yields a one-hot vector.
    wire [W-1:0] one_hot = ({{(W - 1) {1'b0}}, 1'b1} << index);

    // Drive the output with the computed one-hot pattern
    assign active = one_hot;

endmodule
