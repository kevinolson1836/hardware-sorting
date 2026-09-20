`default_nettype none

// Sorting Bars: an LFSR fills 8 slots with random 3-bit values, an odd-even
// transposition sorter sorts them one phase per tick, and the 8 values are
// scanned out as a bar chart for an 8x8 LED matrix.
//
// Pins (Tiny Tapeout)
//   ui_in[0]    1 = sort descending, 0 = ascending
//   ui_in[1]    1 = manual stepping (button on ui_in[2]), 0 = auto
//   ui_in[2]    step button (rising edge = one tick, debounce externally)
//   ui_in[4:3]  auto speed: 00 slowest ... 11 fastest
//   uo_out[7:0] row data for the current column (thermometer code, bit 0 = bottom)
//   uio_out[2:0] column select -> 74HC138 or similar decoder
//   uio_out[3]  HOLD indicator ("sorted!" LED)

module tt_um_sorting_bars (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // ---------------- inputs ----------------
    wire       descending = ui_in[0];
    wire       manual     = ui_in[1];
    wire       btn        = ui_in[2];
    wire [1:0] speed      = ui_in[4:3];

    // ---------------- free-running divider ----------------
    // Low bits pace the slow "tick"; bits [12:10] drive the fast column scan.
    reg [19:0] div;
    always @(posedge clk) begin
        if (!rst_n) div <= 20'd0;
        else        div <= div + 20'd1;
    end

    reg auto_tick;
    always @* begin
        case (speed)
            2'd0:    auto_tick = (div[19:0] == 20'd0);
            2'd1:    auto_tick = (div[18:0] == 19'd0);
            2'd2:    auto_tick = (div[17:0] == 18'd0);
            default: auto_tick = (div[14:0] == 15'd0);  // not 2^16: see note below
        endcase
    end
    // Note: an LFSR with a 2^16-1 period advances exactly 1 state per 2^16
    // clocks, which would make consecutive samples overlap. Avoid 2^16 ticks.

    // Button: 2-flop synchronizer + edge detect
    reg [2:0] btn_sync;
    always @(posedge clk) begin
        if (!rst_n) btn_sync <= 3'b000;
        else        btn_sync <= {btn_sync[1:0], btn};
    end
    wire btn_rise = btn_sync[1] & ~btn_sync[2];

    wire tick = manual ? btn_rise : auto_tick;

    // ---------------- 16-bit LFSR (free-running) ----------------
    // Taps 16,14,13,11 -> maximal length (65535)
    reg [15:0] lfsr;
    wire fb = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];
    always @(posedge clk) begin
        if (!rst_n) lfsr <= 16'hACE1;
        else        lfsr <= {lfsr[14:0], fb};
    end

    // ---------------- state machine + data ----------------
    localparam FILL = 2'd0, SORT = 2'd1, HOLD = 2'd2;

    reg [1:0] state;
    reg [3:0] cnt;          // step counter within a state
    reg [2:0] v [0:7];      // the 8 slots

    // Odd-even transposition: even phase compares (0,1)(2,3)(4,5)(6,7),
    // odd phase compares (1,2)(3,4)(5,6). 8 phases fully sorts 8 items.
    reg [2:0] nxt [0:7];
    integer i;
    always @* begin
        for (i = 0; i < 8; i = i + 1) nxt[i] = v[i];
        for (i = 0; i < 7; i = i + 1) begin
            if (i[0] == cnt[0]) begin
                if (descending ? (v[i] < v[i+1]) : (v[i] > v[i+1])) begin
                    nxt[i]   = v[i+1];
                    nxt[i+1] = v[i];
                end
            end
        end
    end

    integer k;
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= FILL;
            cnt   <= 4'd0;
            for (k = 0; k < 8; k = k + 1) v[k] <= 3'd0;
        end else if (tick) begin
            case (state)
                FILL: begin
                    // shift a new random value in each tick
                    v[0] <= lfsr[2:0];
                    for (k = 1; k < 8; k = k + 1) v[k] <= v[k-1];
                    if (cnt == 4'd7) begin cnt <= 4'd0; state <= SORT; end
                    else cnt <= cnt + 4'd1;
                end
                SORT: begin
                    for (k = 0; k < 8; k = k + 1) v[k] <= nxt[k];
                    if (cnt == 4'd7) begin cnt <= 4'd0; state <= HOLD; end
                    else cnt <= cnt + 4'd1;
                end
                HOLD: begin
                    // admire the result for 16 ticks, then refill
                    if (cnt == 4'd15) begin cnt <= 4'd0; state <= FILL; end
                    else cnt <= cnt + 4'd1;
                end
                default: state <= FILL;
            endcase
        end
    end

    // ---------------- display scan ----------------
    wire [2:0] col = div[12:10];
    wire [2:0] val = v[col];

    // value 0..7 -> bar height 1..8 (thermometer code)
    assign uo_out  = 8'hFF >> ~val;
    assign uio_out = {4'b0000, (state == HOLD), col};
    assign uio_oe  = 8'b0000_1111;

    wire _unused = &{ena, uio_in, ui_in[7:5], 1'b0};

endmodule
