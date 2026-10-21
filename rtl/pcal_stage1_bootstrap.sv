// Stage 1: context ownership and dispatcher only.
// This module MUST NOT claim to calculate a calendar date.
// All calendar arithmetic will be introduced at its contractual stages.
module pcal_stage1_bootstrap (
    input  logic               clk,
    input  logic               reset_n,
    input  logic               req_valid,
    output logic               req_ready,
    input  logic signed [63:0] calculation_day,
    input  logic signed [63:0] target_day,
    output logic               done,
    output logic               date_valid,
    output logic signed [63:0] captured_calculation_day,
    output logic signed [63:0] captured_target_day,
    output logic        [63:0] accepted_count,
    output logic         [1:0] diagnostic_phase
);
    typedef enum logic [1:0] {
        PH_IDLE     = 2'd0,
        PH_CAPTURE  = 2'd1,
        PH_OBSERVE  = 2'd2,
        PH_FINISH   = 2'd3
    } phase_t;
    phase_t phase;

    assign req_ready         = (phase == PH_IDLE);
    assign done              = (phase == PH_FINISH);
    assign date_valid        = 1'b0;
    assign diagnostic_phase  = phase;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            phase                     <= PH_IDLE;
            captured_calculation_day  <= '0;
            captured_target_day       <= '0;
            accepted_count            <= '0;
        end else begin
            case (phase)
                PH_IDLE: begin
                    if (req_valid) begin
                        captured_calculation_day <= calculation_day;
                        captured_target_day      <= target_day;
                        accepted_count           <= accepted_count + 64'd1;
                        phase                    <= PH_CAPTURE;
                    end
                end
                PH_CAPTURE: phase <= PH_OBSERVE;
                PH_OBSERVE: phase <= PH_FINISH;
                PH_FINISH:  phase <= PH_IDLE;
                default:    phase <= PH_IDLE;
            endcase
        end
    end
endmodule
