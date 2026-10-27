module f08_stepper_ctrl #(
    parameter integer SPEED_DIV_W = 8
)(
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     run,
    input  logic                     dir,
    input  logic                     half_step,
    input  logic [SPEED_DIV_W-1:0]   speed_div,
    output logic [3:0]               coil,
    output logic [2:0]               state_dbg
);
    logic [2:0] state, state_next;
    logic [SPEED_DIV_W-1:0] div_count;
    logic step_tick;
    logic [1:0] state_trunc;

    assign state_trunc = state[1:0];

    function automatic logic [3:0] phase_decode(
        input logic [2:0] s,
        input logic       hs,
        input logic [1:0] s_trunc
    );
        if (hs) begin
            case (s)
                3'd0: phase_decode = 4'b1001;
                3'd1: phase_decode = 4'b0001;
                3'd2: phase_decode = 4'b0011;
                3'd3: phase_decode = 4'b0010;
                3'd4: phase_decode = 4'b0110;
                3'd5: phase_decode = 4'b0100;
                3'd6: phase_decode = 4'b1100;
                3'd7: phase_decode = 4'b1000;
                default: phase_decode = 4'b0000;
            endcase
        end else begin
            case (s_trunc)
                2'd0: phase_decode = 4'b1001;
                2'd1: phase_decode = 4'b0011;
                2'd2: phase_decode = 4'b0110;
                2'd3: phase_decode = 4'b1100;
                default: phase_decode = 4'b0000;
            endcase
        end
    endfunction

    always_comb begin
        state_next = state;
        if (half_step) begin
            if (dir)
                state_next = (state == 3'd7) ? 3'd0 : state + 3'd1;
            else
                state_next = (state == 3'd0) ? 3'd7 : state - 3'd1;
        end else begin
            if (dir)
                state_next = (state_trunc == 2'd3) ? 3'd0 : state + 3'd1;
            else
                state_next = (state_trunc == 2'd0) ? 3'd3 : state - 3'd1;
        end
    end

    always_comb begin
        step_tick = 1'b0;
        if (run) begin
            if (speed_div == '0)
                step_tick = 1'b1;
            else if (div_count >= speed_div - 1'b1)
                step_tick = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state     <= 3'd0;
            div_count <= '0;
        end else begin
            if (!run) begin
                div_count <= '0;
            end else if (step_tick) begin
                div_count <= '0;
                state     <= state_next;
            end else begin
                div_count <= div_count + 1'b1;
            end
        end
    end

    always_comb begin
        if (!half_step && (state > 3'd3))
            coil = 4'b1001;
        else
            coil = run ? phase_decode(state, half_step, state_trunc) : 4'b0000;
    end

    assign state_dbg = state;

endmodule
