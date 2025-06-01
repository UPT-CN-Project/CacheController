//==============================================================================
// Module: and_wordgate
// Description:
//   Performs a reduction AND across all bits of the input vector `in`. The
//   result is driven on the output `AND_`. The width of the input vector is
//   parameterizable via `w` (default 8).
//
// Parameters:
//   w  - Width of the input vector `in`. Determines how many bits are ANDed
//        together. Default is 8.
//
// Ports:
//   input  wire [w-1:0] in
//     - The multi-bit input vector. Each bit of this bus is ANDed together.
//   output reg          AND_
//     - The single-bit output which is the logical AND of all bits in `in`.
//
// Internal Signals:
//   integer i
//     - Loop index used in the generate‐for loop to iterate over each bit of
//       the input vector during the combinational evaluation.
//
// Behavior:
//   - As this is a combinational (always @(*)) block, `AND_` reflects the AND
//     of all bits of `in` at all times.
//   - We initialize `AND_` to 1, then iterate through each bit of `in`,
//     updating `AND_ = AND_ & in[i]`. If any bit of `in` is 0, `AND_` becomes 0.
//
// Usage Notes:
//   - Use this module when you need a reduction‐AND of a vector of arbitrary
//     width in purely behavioral (combinational) form.
//   - Because `AND_` is declared as `reg`, it can be used directly in
//     synthesizable code as a combinational output.
//
// Example Instantiation (for a 16-bit AND):
//   and_wordgate #(.w(16)) u_and16 (
//       .in   (some_bus[15:0]),
//       .AND_ (all_bits_high)
//   );
//
//==============================================================================
module and_wordgate #(
    parameter w = 8
) (
    input  wire [w-1:0] in,   // Multi-bit input vector to reduce
    output reg          AND_  // Single-bit output: AND of all input bits
);

    // Loop index for iterating through all bits of `in`
    integer i;

    // Combinational reduction AND:
    // - Initialize AND_ to 1, then AND with each bit of `in`.
    // - If any bit of `in` is 0, AND_ becomes 0.
    always @(*) begin
        AND_ = 1'b1;
        for (i = 0; i < w; i = i + 1) begin
            AND_ = AND_ & in[i];
        end
    end

endmodule
