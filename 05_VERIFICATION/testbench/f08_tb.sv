
`timescale 1ns/1ps

module f08_tb;
    logic clk, rst_n, run, dir, half_step;
    logic [7:0] speed_div;
    logic [3:0] coil;
    logic [2:0] state_dbg;

    integer i;
    logic [2:0] saved_state;

    f08_stepper_ctrl #(.SPEED_DIV_W(8)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .run(run),
        .dir(dir),
        .half_step(half_step),
        .speed_div(speed_div),
        .coil(coil),
        .state_dbg(state_dbg)
    );

    always #5 clk = ~clk;

    task automatic tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task automatic reset_dut;
        begin
            @(negedge clk);
            rst_n = 0;
            run = 0;
            dir = 1;
            half_step = 1;
            speed_div = 8'd1;

            tick();
            tick();

            @(negedge clk);
            rst_n = 1;
            #1;

            if (state_dbg !== 3'd0)
                $fatal(1, "RESET FAIL: state=%0d", state_dbg);
        end
    endtask

    // TC1: State 0 quay lui ve state 7
    initial begin
        clk = 0;
        rst_n = 0;
        run = 0;
        dir = 1;
        half_step = 1;
        speed_div = 8'd1;

        $display("===== F08 TEST START =====");

        // TC1: Bien duoi
        reset_dut();
        @(negedge clk);
        dir = 0;
        half_step = 1;
        run = 1;
        tick();

        if (state_dbg !== 3'd7 || coil !== 4'b1000)
            $fatal(1, "TC1 FAIL: state=%0d coil=%b",
                   state_dbg, coil);

        $display("TC1 PASS: state 0 -> 7");

        // TC2: Quay thuan nua buoc, kiem tra du 8 trang thai
        reset_dut();
        @(negedge clk);
        dir = 1;
        half_step = 1;
        run = 1;

        for (i = 1; i <= 8; i = i + 1) begin
            tick();

            if (state_dbg !== (i % 8))
                $fatal(1, "TC2 FAIL at step %0d: state=%0d",
                       i, state_dbg);

            case (i % 8)
                0: if (coil !== 4'b1001) $fatal(1, "TC2 coil mismatch");
                1: if (coil !== 4'b0001) $fatal(1, "TC2 coil mismatch");
                2: if (coil !== 4'b0011) $fatal(1, "TC2 coil mismatch");
                3: if (coil !== 4'b0010) $fatal(1, "TC2 coil mismatch");
                4: if (coil !== 4'b0110) $fatal(1, "TC2 coil mismatch");
                5: if (coil !== 4'b0100) $fatal(1, "TC2 coil mismatch");
                6: if (coil !== 4'b1100) $fatal(1, "TC2 coil mismatch");
                7: if (coil !== 4'b1000) $fatal(1, "TC2 coil mismatch");
            endcase
        end

        $display("TC2 PASS: full half-step sequence");

        // TC3: Quay nghich buoc du: 0 -> 3 -> 2 -> 1 -> 0
        reset_dut();
        @(negedge clk);
        dir = 0;
        half_step = 0;
        run = 1;

        for (i = 1; i <= 4; i = i + 1) begin
            tick();

            if (state_dbg !== ((4 - i) % 4))
                $fatal(1, "TC3 FAIL at step %0d: state=%0d",
                       i, state_dbg);

            case ((4 - i) % 4)
                0: if (coil !== 4'b1001) $fatal(1, "TC3 coil mismatch");
                1: if (coil !== 4'b0011) $fatal(1, "TC3 coil mismatch");
                2: if (coil !== 4'b0110) $fatal(1, "TC3 coil mismatch");
                3: if (coil !== 4'b1100) $fatal(1, "TC3 coil mismatch");
            endcase
        end

        $display("TC3 PASS: full-step reverse sequence");

        // TC4: Doi chieu khi dang quay
        reset_dut();
        @(negedge clk);
        dir = 1;
        half_step = 1;
        run = 1;

        repeat (3) tick();

        if (state_dbg !== 3'd3)
            $fatal(1, "TC4 setup FAIL: expected state 3, got %0d",
                   state_dbg);

        @(negedge clk);
        saved_state = state_dbg;
        dir = 0;

        tick();

        if (state_dbg !== 3'd2)
            $fatal(1, "TC4 FAIL: before=%0d after=%0d",
                   saved_state, state_dbg);

        $display("TC4 PASS: direction reversal keeps position");

        // TC5: Dung dong co
        reset_dut();
        @(negedge clk);
        dir = 1;
        half_step = 1;
        run = 1;
        tick();

        saved_state = state_dbg;

        @(negedge clk);
        run = 0;
        #1;

        if (coil !== 4'b0000)
            $fatal(1, "TC5 FAIL: coil=%b while stopped", coil);

        tick();

        if (state_dbg !== saved_state)
            $fatal(1, "TC5 FAIL: state changed while stopped");

        if (coil !== 4'b0000)
            $fatal(1, "TC5 FAIL: coil not inactive");

        $display("TC5 PASS: motor stopped and state held");

        $display("===== ALL F08 TESTS PASSED =====");
        $finish;
    end

    // Waveform for GTKWave
    initial begin
        $dumpfile("f08_wave.vcd");
        $dumpvars(0, f08_tb);
    end

endmodule
