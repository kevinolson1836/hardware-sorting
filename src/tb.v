`timescale 1ns/1ps

module tb;
    reg        clk = 0;
    reg        rst_n = 0;
    reg  [7:0] ui_in = 8'b0000_0010;   // manual mode, ascending
    wire [7:0] uo_out, uio_out, uio_oe;

    tt_um_sorting_bars dut (
        .ui_in(ui_in), .uo_out(uo_out),
        .uio_in(8'h00), .uio_out(uio_out), .uio_oe(uio_oe),
        .ena(1'b1), .clk(clk), .rst_n(rst_n)
    );

    always #5 clk = ~clk;

    task step;
        begin
            ui_in[2] = 1; repeat (4) @(posedge clk);
            ui_in[2] = 0; repeat (4) @(posedge clk);
        end
    endtask

    task show(input [127:0] label);
        begin
            $display("%0s: %0d %0d %0d %0d %0d %0d %0d %0d  (state=%0d)", label,
                dut.v[0], dut.v[1], dut.v[2], dut.v[3],
                dut.v[4], dut.v[5], dut.v[6], dut.v[7], dut.state);
        end
    endtask

    integer i, ok;

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);

        repeat (4) @(posedge clk);
        rst_n = 1;
        repeat (4) @(posedge clk);

        repeat (8) step;              // FILL
        show("filled");
        repeat (8) step;              // SORT
        show("sorted");

        ok = 1;
        for (i = 0; i < 7; i = i + 1)
            if (dut.v[i] > dut.v[i+1]) ok = 0;
        if (ok) $display("PASS: ascending"); else $display("FAIL: not sorted");

        // descending run
        ui_in[0] = 1;
        repeat (16) step;             // finish HOLD (16 ticks)
        repeat (8) step;              // FILL
        show("filled2");
        repeat (8) step;              // SORT descending
        show("sorted2");
        ok = 1;
        for (i = 0; i < 7; i = i + 1)
            if (dut.v[i] < dut.v[i+1]) ok = 0;
        if (ok) $display("PASS: descending"); else $display("FAIL: not sorted (desc)");

        $finish;
    end
endmodule
