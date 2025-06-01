//==============================================================================
// Testbench: tb_decNto2N.v
// Description:
//   Verifies correct functionality of decNto2N (N‐to‐2^N one‐hot decoder) for
//   the case N=3 (so W=8 outputs). Applies all index values 0..7, checks that
//   the output matches the expected one‐hot pattern, and uses assertions ($fatal)
//   on mismatch.
//==============================================================================

`timescale 1ns / 1ps

module tb_dec;

    //-------------------------------------------------------------------------
    // Parameters for this test:
    //   – N = 3    → 8 outputs (W = 1 << 3)
    //-------------------------------------------------------------------------
    localparam N = 3;
    localparam W = (1 << N);  // 8

    //-------------------------------------------------------------------------
    // Signals for the decoder test
    //-------------------------------------------------------------------------
    reg     [N-1:0] dec_index;  // 3-bit index (0..7)
    wire    [W-1:0] dec_active;  // 8-bit one-hot output

    integer         i;
    reg     [W-1:0] expected_one_hot;

    //-------------------------------------------------------------------------
    // Instantiate decNto2N with N=3 → W=8
    //-------------------------------------------------------------------------
    decoder #(
        .N(N),  // 3
        .W(W)   // 8
    ) dut_decoder (
        .index (dec_index),
        .active(dec_active)
    );

    //-------------------------------------------------------------------------
    // Test procedure
    //-------------------------------------------------------------------------
    initial begin
        $display("\n=== decNto2N (3→8) Test Begin ===");
        for (i = 0; i < W; i = i + 1) begin
            dec_index = i[N-1:0];
            #1;  // wait for combinational paths to settle

            // Build the expected one-hot: 1 shifted left by i, sized to W bits
            expected_one_hot = ({{(W - 1) {1'b0}}, 1'b1} << i);

            // Assertion: dec_active must match expected_one_hot
            if (dec_active !== expected_one_hot) begin
                $display(">> DECODER ERROR: dec_index=%0d, dec_active=%b, expected=%b", i,
                         dec_active, expected_one_hot);
                $fatal;  // immediate failure
            end else begin
                $display("  dec_index=%0d → dec_active = %b (PASS)", i, dec_active);
            end
        end
        $display("=== decNto2N Test Passed ===\n");
        $display(">>> Decoder Tests Passed Successfully <<<");
        $finish;
    end

endmodule
