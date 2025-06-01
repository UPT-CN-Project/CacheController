`timescale 1ns / 1ps

module four_way_set_tb;
    //-------------------------------------------------------------------------
    // Parameters (must match the DUT’s parameters)
    //-------------------------------------------------------------------------
    parameter ADDRESS_WORD_SIZE = 32;
    parameter TAG_SIZE = 19;
    parameter BLOCK_SIZE = 16;
    parameter WORD_SIZE = 4;

    //-------------------------------------------------------------------------
    // Clock & Reset
    //-------------------------------------------------------------------------
    reg                          clk;
    reg                          rst_b;

    //-------------------------------------------------------------------------
    // Inputs to the four_way_set DUT
    //-------------------------------------------------------------------------
    reg                          try_read;
    reg                          try_write;
    reg  [ADDRESS_WORD_SIZE-1:0] address_word;
    reg  [                  7:0] write_data;

    //-------------------------------------------------------------------------
    // Outputs from the four_way_set DUT
    //-------------------------------------------------------------------------
    wire [                  7:0] data_out;  // selected data byte
    wire [                  7:0] ages;  // {age_way3, age_way2, age_way1, age_way0}
    wire                         hit_miss;  // indicates whether the selected way hit
    wire [                  3:0] hit_miss_set;  // one‐hot: which way(s) hit

    //-------------------------------------------------------------------------
    // Instantiate the DUT
    //-------------------------------------------------------------------------
    four_way_set #(
        .ADDRESS_WORD_SIZE(ADDRESS_WORD_SIZE),
        .TAG_SIZE         (TAG_SIZE),
        .BLOCK_SIZE       (BLOCK_SIZE),
        .WORD_SIZE        (WORD_SIZE)
    ) dut (
        .clk         (clk),
        .rst_b       (rst_b),
        .try_read    (try_read),
        .try_write   (try_write),
        .address_word(address_word),
        .write_data  (write_data),
        .data        (data_out),
        .ages        (ages),
        .hit_miss    (hit_miss),
        .hit_miss_set(hit_miss_set)
    );

    //-------------------------------------------------------------------------
    // Generate a 10 ns clock (100 MHz)
    //-------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //-------------------------------------------------------------------------
    // Test sequence
    //-------------------------------------------------------------------------
    initial begin
        // 1) Initialize / Reset
        rst_b        = 1'b0;
        try_read     = 1'b0;
        try_write    = 1'b0;
        address_word = {ADDRESS_WORD_SIZE{1'b0}};
        write_data   = 8'h00;

        #12;
        rst_b = 1'b1;  // Release reset
        #8;  // Wait for next rising edge

        $display("\n=== After Reset ===");
        $display("  ages          = %0h", ages);
        $display("  hit_miss_set  = %b", hit_miss_set);
        $display("  hit_miss      = %b", hit_miss);
        $display("  data          = %0h\n", data_out);

        //-------------------------------------------------------------------------
        // 2) READ MISS #1 → Fill way0
        //    Address A = 32'h1000_0000
        //-------------------------------------------------------------------------
        #2;  // Align to just before posedge
        address_word = 32'h1000_0000;  // Address A
        try_read     = 1'b1;
        try_write    = 1'b0;
        #10;  // At this rising edge: all ways are empty, so way0 is chosen.
              // This is a miss, so way0’s age→0, way1–way3 ages→1.
        try_read = 1'b0;
        #1;
        $display("=== After READ MISS #1 ===");
        $display("  ages          = %0h   (expect {01,01,01,00} = 0x54)", ages);
        $display("  hit_miss_set  = %b   (expect 0000, since it was a miss)", hit_miss_set);
        $display("  hit_miss      = %b   (expect 0)", hit_miss);
        $display("  data          = %0h\n", data_out);

        //-------------------------------------------------------------------------
        // 3) READ MISS #2 → Fill way1
        //    Address B = 32'h2000_0000
        //-------------------------------------------------------------------------
        #9;  // Wait until just before next rising edge
        address_word = 32'h2000_0000;  // Address B
        try_read     = 1'b1;
        #10;  // At rising edge: way0 valid but tags don’t match. way1 is first empty, chosen.
              // Now: way1→age 0; way0→age 1; way2→age 2; way3→age 2
        try_read = 1'b0;
        #1;
        $display("=== After READ MISS #2 ===");
        $display("  ages          = %0h   (expect {02,02,00,01} = 0xA1)", ages);
        $display("  hit_miss_set  = %b   (expect 0000)", hit_miss_set);
        $display("  hit_miss      = %b   (expect 0)", hit_miss);
        $display("  data          = %0h\n", data_out);

        //-------------------------------------------------------------------------
        // 4) READ MISS #3 → Fill way2
        //    Address C = 32'h3000_0000
        //-------------------------------------------------------------------------
        #9;
        address_word = 32'h3000_0000;  // Address C
        try_read     = 1'b1;
        #10;  // rising edge: way0 & way1 valid but tags mismatch; way2 is first empty → chosen.
              // Now: way2→age 0; way0→age 2; way1→age 1; way3→age 3
        try_read = 1'b0;
        #1;
        $display("=== After READ MISS #3 ===");
        $display("  ages          = %0h   (expect {03,01,00,02} = 0x3102)", ages);
        $display("  hit_miss_set  = %b   (expect 0000)", hit_miss_set);
        $display("  hit_miss      = %b   (expect 0)", hit_miss);
        $display("  data          = %0h\n", data_out);

        //-------------------------------------------------------------------------
        // 5) READ MISS #4 → Fill way3
        //    Address D = 32'h4000_0000
        //-------------------------------------------------------------------------
        #9;
        address_word = 32'h4000_0000;  // Address D
        try_read     = 1'b1;
        #10;  // rising edge: way0–way2 valid & mismatched; way3 empty→chosen.
              // Now: way3→age 0; way0→age 3; way1→age 2; way2→age 1
        try_read = 1'b0;
        #1;
        $display("=== After READ MISS #4 ===");
        $display("  ages          = %0h   (expect {00,01,10,11} = 0x016B)", ages);
        $display("  hit_miss_set  = %b   (expect 0000)", hit_miss_set);
        $display("  hit_miss      = %b   (expect 0)", hit_miss);
        $display("  data          = %0h\n", data_out);

        //-------------------------------------------------------------------------
        // 6) READ HIT       → Re‐read Address B (32'h2000_0000), which is in way1
        //-------------------------------------------------------------------------
        #9;
        address_word = 32'h2000_0000;  // Address B
        try_read     = 1'b1;
        #10;  // rising edge: matching_tags & valid for way1 → hit.
              // So way1→age 0. Others increment:
              //    way0: age=3→4→wrapped or clamped; if wrap: 4→0, if clamp: 3
              //    way2: age=1→2
              //    way3: age=0→1
        try_read = 1'b0;
        #1;
        $display("=== After READ HIT on B (#5) ===");
        $display("  ages          = %0h   (expect if wrap: {01,00,10,00} = 0x1 0 2 0 = 0x1020)",
                 ages);
        $display("  hit_miss_set  = %b   (expect 0010)", hit_miss_set);
        $display("  hit_miss      = %b   (expect 1)", hit_miss);
        $display("  data          = %0h\n", data_out);

        //-------------------------------------------------------------------------
        // 7) READ MISS #5 → New Address E = 32'h5000_0000
        //     All 4 ways valid; choose LRU.  After step #6, ages (wrap‐case) might be:
        //      way0=0 (wrapped), way1=0, way2=2, way3=1 — LRU=way2 (age=2)? or if clamp, recalc.
        //     For clarity, we’ll just observe which way is chosen:
        //-------------------------------------------------------------------------
        #9;
        address_word = 32'h5000_0000;  // Address E
        try_read     = 1'b1;
        #10;  // rising edge: No tag matches, no empties. Choose the way whose age==‘11’.
              // Check the printed hit_miss_set to see which one was LRU.
        try_read = 1'b0;
        #1;
        $display("=== After READ MISS #5 (LRU eviction) ===");
        $display("  ages          = %0h", ages);
        $display("  hit_miss_set  = %b   (the 1-hot bit shows evicted slot)", hit_miss_set);
        $display("  hit_miss      = %b   (expect 0)", hit_miss);
        $display("  data          = %0h\n", data_out);

        //-------------------------------------------------------------------------
        // Optionally, you could now read one of the original addresses (A–D), but if its line
        // was just evicted, it will miss again—verifying eviction. You could also test write similarly.
        //-------------------------------------------------------------------------

        #10;
        $display("\n=== TEST COMPLETE ===\n");
        $finish;
    end

endmodule
