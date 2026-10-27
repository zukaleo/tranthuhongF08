module f08_tb;
    logic clk, rst_n, run, dir, half_step;
    logic [7:0] speed_div;
    logic [3:0] coil;
    logic [2:0] state_dbg;
    logic [2:0] s_before;   // P-1: khai bao o pham vi module

    f08_stepper_ctrl #(.SPEED_DIV_W(8)) dut(
        .clk(clk), .rst_n(rst_n), .run(run), .dir(dir),
        .half_step(half_step), .speed_div(speed_div),
        .coil(coil), .state_dbg(state_dbg)
    );

    always #5 clk = ~clk;

    task automatic tick;
        begin @(posedge clk); #1; end
    endtask

    initial begin
        clk=0; rst_n=0; run=0; dir=1; half_step=1; speed_div=8'd1;
        repeat(2) tick();
        rst_n=1;

        // Start half-step sequence.
        run=1;
        repeat(8) tick();
        assert(state_dbg <= 3'd7) else $fatal(1,"invalid half-step state");

        // Direction reversal from a non-zero state must be adjacent, not reset.
        dir=1;
        tick();
        s_before = state_dbg;
        dir=0;
        tick();
        assert(state_dbg == ((s_before==0)?7:s_before-1))
            else $fatal(1,"direction reversal did not move to predecessor");

        // Full-step uses only states 0..3.
        half_step=0;
        repeat(8) tick();
        assert(state_dbg <= 3'd3) else $fatal(1,"invalid full-step state");

        // Stop drives coils inactive in the scaffold.
        run=0;
        tick();
        assert(coil==4'b0000) else $fatal(1,"stop output not inactive");

        // Reset.
        rst_n=0;
        tick();
        assert(state_dbg==0 && coil==0) else $fatal(1,"reset failure");

        $display("F08 TB completed");
        $finish;
    end
endmodule
