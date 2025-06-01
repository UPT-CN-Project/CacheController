//==============================================================================
// Module: encoder4to2
// Description:
//   A combinational priority encoder that converts a one-hot 4-bit input (`in`)
//   into a 2-bit binary output (`out`). If exactly one bit in `in[3:0]` is set,
//   `out` indicates the index of that bit (00 for bit0, 01 for bit1, 10 for bit2,
//   11 for bit3). If `in` is zero or contains multiple bits set, `out` defaults
//   to 2'b00.
//
// Ports:
//   input  wire [3:0] in
//     - One-hot encoded 4-bit vector. Exactly one bit should be high to select a
//       unique 2-bit output. Valid values are 4'b0001, 4'b0010, 4'b0100, 4'b1000.
//   output reg  [1:0] out
//     - 2-bit binary index of which input bit is set. If multiple or zero bits
//       are set, defaults to 2'b00.
//
// Behavior:
//   - If in == 4'b0001  → out = 2'b00  (select index 0)
//   - If in == 4'b0010  → out = 2'b01  (select index 1)
//   - If in == 4'b0100  → out = 2'b10  (select index 2)
//   - If in == 4'b1000  → out = 2'b11  (select index 3)
//   - Otherwise (in == 4'b0000 or more than one bit high) → out = 2'b00
//
// Usage Notes:
//   - Use this when a single one-hot signal among four lines must be encoded
//     into a two-bit “way” or “index” value.
//   - If multiple bits are high simultaneously, this module does not report an
//     error; it simply defaults to index 0 (2'b00).
//
// Example Instantiation:
//   encoder4to2 u_enc (
//       .in  (one_hot_signals[3:0]),
//       .out (selected_index[1:0])
//   );
//
//==============================================================================

module encoder4to2 (
    input  wire [3:0] in,  // One-hot 4-bit input
    output reg  [1:0] out  // 2-bit binary output index
);
    // Combinational logic: priority encode the one-hot input.
    // The `case` covers exactly one-hot patterns; default handles 0 or multiple bits.
    always @(*) begin
        case (in)
            4'b0001: out = 2'b00;  // Input bit0 is high → index 0
            4'b0010: out = 2'b01;  // Input bit1 is high → index 1
            4'b0100: out = 2'b10;  // Input bit2 is high → index 2
            4'b1000: out = 2'b11;  // Input bit3 is high → index 3
            default: out = 2'b00;  // No valid one-hot → default to 0
        endcase
    end
endmodule
