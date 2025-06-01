//==============================================================================
// File: control_unit.v
// Description:
//   The control_unit module implements a finite‐state controller for driving cache
//   operations in a 4‐way set‐associative cache. It generates read/write requests,
//   captures hit/miss feedback, and manages per‐way age updates for LRU replacement.
//   The state machine sequences through request issuance, waiting for the result,
//   and, on a hit, enters UPDATE_AGES to clear the age of the accessed way and
//   increment the ages of “older” ways. On a miss, it stalls briefly before returning
//   to IDLE.
//
// Parameters:
//   ADDRESS_WORD_SIZE – Width of the memory address bus (e.g., 32).
//
// Ports:
//   input  clk                       – System clock (rising edge drives state transitions).
//   input  rst_b                     – Active‐low reset (forces state back to IDLE).
//   input  opcode                    – Single‐bit command: 0 → “issue read,” 1 → “issue write.”
//   input  hit_miss                   – From the selected four_way_set: 1 if hit, 0 if miss.
//   input  [3:0] hit_miss_set        – One‐hot way mask from the selected set (which of 4 ways matched).
//   input  [7:0] ages                – Concatenated 4×2‐bit ages from the selected set (two bits each).
//
//   output reg [ADDRESS_WORD_SIZE-1:0] address_word
//                                       – Randomly generated address for each read/write request.
//   output reg try_read               – Asserted for one cycle to request a read from the cache.
//   output reg try_write              – Asserted for one cycle to request a write to the cache.
//   output reg [7:0] write_data       – Random byte value to write when issuing a write request.
//   output reg [3:0] reset_age        – One‐hot mask telling the selected four_way_set which way’s age to clear.
//   output reg [3:0] increment_age    – One‐hot mask telling the selected set to increment ages of certain ways.
//
// State Encoding (3 bits):
//   IDLE        = 3’b000 : Wait for an opcode, then move to TRY_READ or TRY_WRITE.
//   TRY_READ    = 3’b001 : Assert try_read=1, pick a random address, then go to CHECK_STATUS.
//   TRY_WRITE   = 3’b010 : Assert try_write=1, pick a random address and write_data, then go to CHECK_STATUS.
//   CHECK_STATUS= 3’b110 : Wait one cycle for the cache to respond (hit_miss). If hit → UPDATE_AGES; else → STALL_1.
//   STALL_1     = 3’b011 : One‐cycle stall on miss → move to STALL_2.
//   STALL_2     = 3’b100 : Second stall cycle on miss → move to UPDATE_AGES (for replacement LRU update).
//   UPDATE_AGES = 3’b101 : On a hit (or after two‐cycle stall on miss), compute which way’s age to reset
//                           and which ways’ ages to increment, then return to IDLE.
//
// Internal Registers:
//   reg [2:0] current_state : Holds the current FSM state.
//   reg [2:0] next_state    : Computed combinationally from current_state and inputs.
//   integer  i              : Loop index for updating reset_age/increment_age masks.
//   integer  replace_index   : Index of way that hit (or chosen for replacement on miss).
//
// Behavior Summary:
//   • On reset (rst_b=0): current_state ← IDLE, all outputs = 0.
//   • In IDLE: clear all control outputs; if opcode=1 → TRY_WRITE, else TRY_READ.
//   • In TRY_READ: assert try_read=1 for one cycle, pick random address_word, go to CHECK_STATUS.
//   • In TRY_WRITE: assert try_write=1 for one cycle, pick random address_word & write_data, go to CHECK_STATUS.
//   • In CHECK_STATUS: if hit_miss=1 → UPDATE_AGES; else → STALL_1.
//   • In STALL_1: spend one cycle doing nothing (simulate memory fill delay), then → STALL_2.
//   • In STALL_2: spend second stall cycle, then → UPDATE_AGES (for LRU update on miss).
//   • In UPDATE_AGES:
//       – Scan hit_miss_set[3:0] to find which way matched (or was chosen on miss).
//       –   reset_age[i] = 1 for that way i (clears its age to 0).
//       –   replace_index = i to record the chosen way.
//       – Then, for all other ways j: if their age (ages[2*j +: 2]) is less than
//         ages[2*replace_index +: 2] (the age of the hit/evicted way), assert increment_age[j]=1.
//       – Finally, return to IDLE.
//   • All outputs are “reg” so they hold steady until the next state transition.
//
// NOTE on Age Logic:
//   – reset_age and increment_age are 4‐bit one‐hot masks. Only the chosen way’s
//     reset_age bit is 1. Every way whose age is “older” (numerically less) than the
//     chosen way has its increment_age bit set to 1, so its local age counter increments.
//   – These masks feed directly into the four_way_set, which in turn updates its
//     per‐way age_counters in that set on the same clock edge.
//
//==============================================================================

module control_unit #(
    parameter ADDRESS_WORD_SIZE = 32  // Width of the memory address bus
) (
    input wire       clk,           // System clock
    input wire       rst_b,         // Active‐low reset
    input wire       opcode,        // 0→read, 1→write
    input wire       hit_miss,      // 1 if cache set hit, 0 if miss
    input wire [3:0] hit_miss_set,  // One‐hot way mask in the selected set
    input wire [7:0] ages,          // 4×2‐bit ages of the selected set

    output reg [ADDRESS_WORD_SIZE-1:0] address_word,  // Randomly generated address
    output reg try_read,  // Pulse high to issue read
    output reg try_write,  // Pulse high to issue write
    output reg [7:0] write_data,  // Random write data byte
    output reg [3:0] reset_age,  // One‐hot mask: clear chosen way’s age
    output reg [3:0] increment_age  // One‐hot mask: increment other ways’ ages
);

    // FSM state encoding
    localparam IDLE = 3'b000;
    localparam TRY_READ = 3'b001;
    localparam TRY_WRITE = 3'b010;
    localparam STALL_1 = 3'b011;
    localparam STALL_2 = 3'b100;
    localparam UPDATE_AGES = 3'b101;
    localparam CHECK_STATUS = 3'b110;

    // State registers
    reg [2:0] current_state;
    reg [2:0] next_state;

    // Index of the chosen way (hit or replacement candidate)
    integer replace_index;
    // Loop variable for building masks
    integer i;

    // Initialization
    initial begin
        current_state = IDLE;
        next_state    = IDLE;
        address_word  = {ADDRESS_WORD_SIZE{1'b0}};
        try_read      = 1'b0;
        try_write     = 1'b0;
        write_data    = 8'd0;
        reset_age     = 4'd0;
        increment_age = 4'd0;
        replace_index = 0;
    end

    // Combinational next-state / output logic
    always @(*) begin
        // Default all outputs to zero unless overridden in a state
        address_word  = {ADDRESS_WORD_SIZE{1'b0}};
        try_read      = 1'b0;
        try_write     = 1'b0;
        write_data    = 8'd0;
        reset_age     = 4'd0;
        increment_age = 4'd0;
        replace_index = 0;
        next_state    = IDLE;

        case (current_state)
            // --------------------------------------------------------
            IDLE: begin
                // Wait for an opcode. If opcode==1, prepare a write; else a read.
                if (opcode) next_state = TRY_WRITE;
                else next_state = TRY_READ;
            end

            // --------------------------------------------------------
            TRY_READ: begin
                // Issue a read request for one cycle, pick a random address.
                try_read     = 1'b1;
                address_word = $random;
                next_state   = CHECK_STATUS;
            end

            // --------------------------------------------------------
            TRY_WRITE: begin
                // Issue a write request for one cycle, pick random address & data.
                try_write    = 1'b1;
                address_word = $random;
                write_data   = $urandom_range(0, 255);
                next_state   = CHECK_STATUS;
            end

            // --------------------------------------------------------
            CHECK_STATUS: begin
                // After issuing the request, wait one cycle for hit/miss feedback.
                // If hit → go update ages. If miss → start two‐cycle stall.
                if (hit_miss) next_state = UPDATE_AGES;
                else next_state = STALL_1;
            end

            // --------------------------------------------------------
            STALL_1: begin
                // First stall cycle on miss (simulate memory fetch delay)
                next_state = STALL_2;
            end

            // --------------------------------------------------------
            STALL_2: begin
                // Second stall cycle on miss (still fetching)
                next_state = UPDATE_AGES;
            end

            // --------------------------------------------------------
            UPDATE_AGES: begin
                // Build reset_age mask: which way just hit (or is being replaced)
                for (i = 0; i < 4; i = i + 1) begin
                    if (hit_miss_set[i]) begin
                        reset_age     = 4'b0000;
                        reset_age[i]  = 1'b1;
                        replace_index = i;  // remember which way to compare ages against
                    end
                end
                // Build increment_age mask: every way whose age is less than the chosen way’s age
                for (i = 0; i < 4; i = i + 1) begin
                    // Compare 2‐bit age fields: ages[2*i +: 2] versus ages[2*replace_index +: 2]
                    if (ages[2*i+:2] < ages[2*replace_index+:2]) begin
                        increment_age[i] = 1'b1;
                    end else begin
                        increment_age[i] = 1'b0;
                    end
                end
                next_state = IDLE;
            end

            // --------------------------------------------------------
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Sequential state update on rising clock or asynchronous reset
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

endmodule
