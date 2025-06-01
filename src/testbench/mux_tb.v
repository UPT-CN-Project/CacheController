//==============================================================================
// Testbench: tb_mux.v
// Description:
//   Verifies correct functionality of muxNto1 (N‐to‐1 multiplexer) for the case
//   SEL_WIDTH=3 (8‐way) and w=8 (each channel is 8 bits wide). Applies all select
//   values 0..7, checks that the output matches the expected channel data, and
//   uses assertions ($fatal) on mismatch.
//==============================================================================

`timescale 1ns / 1ps

module tb_mux;

    //-------------------------------------------------------------------------
    // Parameters for this test:
    //   – SEL_WIDTH=3  → 8 channels
    //   – w=8          → each channel is 8 bits wide
    //-------------------------------------------------------------------------
    localparam SEL_WIDTH = 3;
    localparam N = (1 << SEL_WIDTH);  // 8 channels
    localparam w = 8;  // bits per channel

    //-------------------------------------------------------------------------
    // Signals for the mux test
    //-------------------------------------------------------------------------
    reg     [      N*w-1:0] mux_in;  // Concatenated 8 channels × 8 bits each
    reg     [SEL_WIDTH-1:0] mux_sel;  // 3-bit select (0..7)
    wire    [        w-1:0] mux_out;  // 8-bit selected output

    integer                 i;
    reg     [        w-1:0] channel_values                                    [0:N-1];
    reg     [        w-1:0] expected_mux_out;

    //-------------------------------------------------------------------------
    // Instantiate muxNto1 with SEL_WIDTH=3, w=8
    //-------------------------------------------------------------------------
    muxNto1 #(
        .SEL_WIDTH(SEL_WIDTH),
        .w        (w)
    ) dut_mux (
        .in (mux_in),
        .sel(mux_sel),
        .out(mux_out)
    );

    //-------------------------------------------------------------------------
    // Test procedure
    //-------------------------------------------------------------------------
    initial begin
        // Initialize inputs
        mux_sel = {SEL_WIDTH{1'b0}};
        mux_in  = {N * w{1'b0}};

        // Precompute distinct values for each channel:
        // channel_values[k] = (k * 16) + 8'h05;  // arbitrary unique pattern
        for (i = 0; i < N; i = i + 1) begin
            channel_values[i] = (i * 16) + 8'h05;
        end

        // Build the concatenated mux_in so that channel k occupies bits [k*w +: w]
        for (i = 0; i < N; i = i + 1) begin
            mux_in[i*w+:w] = channel_values[i];
        end

        $display("\n=== muxNto1 (8→1, w=8) Test Begin ===");
        // Loop over all select values
        for (i = 0; i < N; i = i + 1) begin
            mux_sel = i[SEL_WIDTH-1:0];
            #1;  // wait for combinational mux to settle

            // Expected output = channel_values[i]
            expected_mux_out = channel_values[i];

            if (mux_out !== expected_mux_out) begin
                $display(">> ERROR: mux_sel=%0d, mux_out=0x%02h, expected=0x%02h", i, mux_out,
                         expected_mux_out);
                $fatal;  // immediate failure
            end else begin
                $display("  mux_sel=%0d → mux_out = 0x%02h (PASS)", i, mux_out);
            end
        end
        $display("=== muxNto1 Test Passed ===\n");

        $display(">>> All Mux Tests Passed Successfully <<<");
        $finish;
    end

endmodule
