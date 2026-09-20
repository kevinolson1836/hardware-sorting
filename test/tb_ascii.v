`timescale 1ns/1ps

// Prints the 8x8 bar display as ASCII after every step.
// Run:  iverilog -g2012 -o ascii src/tt_um_sorting_bars.v tb_ascii.v && vvp ascii

module tb_ascii;
    reg        clk = 0;
    reg        rst_n = 0;
    reg  [7:0] ui_in = 8'b0000_0010;   // manual mode, ascending (set bit 0 for descending)
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

    task draw;
        integer r, c;
        begin
            for (r = 7; r >= 0; r = r - 1) begin
                for (c = 0; c < 8; c = c + 1)
                    $write("%s", (dut.v[c] >= r) ? "# " : ". ");
                $write("\n");
            end
            $write("0 1 2 3 4 5 6 7\n");
        end
    endtask

    integer n;

    initial begin
        repeat (4) @(posedge clk);
        rst_n = 1;
        repeat (4) @(posedge clk);

        for (n = 1; n <= 8; n = n + 1) begin
            step;
            $display("\nFILL step %0d of 8", n);
            draw;
        end
        for (n = 1; n <= 8; n = n + 1) begin
            step;
            $display("\nSORT phase %0d of 8 (%0s pairs)", n, (n % 2) ? "even" : "odd");
            draw;
        end
        $finish;
    end
endmodule
