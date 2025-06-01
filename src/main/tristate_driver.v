//==============================================================================
// Module: tristate_driver
// Description:
//   A simple parameterizable tri‐state driver. When `enable` is high, the w‐bit
//   input bus `in` is driven onto the output `out`. When `enable` is low, `out`
//   goes to high‐impedance (Z) on all bits. Use this to selectively connect or
//   disconnect a bus in a larger design.
//
// Parameters:
//   w – Width (in bits) of the input and output buses. Default is 8.
//
// Ports:
//   input  [w-1:0] in
//     – The w‐bit data to be driven when `enable` is asserted.
//   input  enable
//     – Control signal. When 1, `in` is driven onto `out`. When 0, `out` is high‐Z.
//   output tri [w-1:0] out
//     – The tri‐state w‐bit output. Acts as a pass‐through of `in` when `enable=1`,
//       otherwise all bits float (Z).
//
// Behavior:
//   out = in     when enable == 1
//   out = ZZZ…Z  when enable == 0
//
// Usage Notes:
//   – Use this module whenever you need a bus that can be conditionally driven or
//     left floating. On FPGA flows, the synthesis tool will typically infer internal
//     multiplexing rather than actual tri‐state buffers, but the high‐Z semantics
//     remain valid for combinational switching.
//   – Ensure that only one driver is enabled at a time on any multi‐driver net to
//     avoid contention.
//
// Example Instantiation (for a 16‐bit bus):
//   tristate_driver #(.w(16)) u_tri16 (
//       .in     (some_data_bus[15:0]),
//       .enable (drive_enable),
//       .out    (shared_bus[15:0])
//   );
//
//==============================================================================

module tristate_driver #(
    parameter w = 8  // Width of the input/output bus
) (
    input  wire [w-1:0] in,      // Data bus to drive
    input  wire         enable,  // When high, drive `in` onto `out`; else high‐Z
    output tri  [w-1:0] out      // Tri‐state output bus
);

    // Drive `in` onto `out` when enabled; otherwise float (all bits = Z)
    assign out = (enable) ? in : {w{1'bz}};

endmodule
