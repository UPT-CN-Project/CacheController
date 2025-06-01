//==============================================================================
// Module: bit_comparator
// Description:
//   Compares two single-bit inputs, `b0` and `b1`, and outputs `eq` which is
//   high (1) if and only if the two inputs are identical (both 0 or both 1).
//
// Ports:
//   input  b0
//     - First single-bit input to compare.
//   input  b1
//     - Second single-bit input to compare.
//   output eq
//     - Output is 1 if b0 == b1, otherwise 0.
//
// Behavior:
//   eq = (b0 AND b1) OR ((NOT b0) AND (NOT b1))
//   • If both b0 and b1 are 1, the first term (b0 & b1) is 1 → eq = 1
//   • If both b0 and b1 are 0, the second term (~b0 & ~b1) is 1 → eq = 1
//   • Otherwise, eq = 0
//
// Usage Notes:
//   - This module is a purely combinational equality check for two bits.
//   - Can be instantiated in a larger comparator or tag‐matching logic where
//     each bit of two buses is compared individually, and results are combined.
//
// Example Instantiation:
//   bit_comparator u_bitcomp (
//       .b0   (tag_bit_from_cache),
//       .b1   (tag_bit_from_address),
//       .eq   (bit_match_signal)
//   );
//
//==============================================================================

module bit_comparator (
    input  b0,  // First bit to compare
    input  b1,  // Second bit to compare
    output eq   // High if b0 == b1, low otherwise
);

    // Combinational equality detection:
    //   eq is asserted when both bits are 1 (b0 & b1) or both bits are 0 (~b0 & ~b1).
    assign eq = (b0 & b1) | (~b0 & ~b1);

endmodule
