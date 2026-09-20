import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

MANUAL = 0b010       # ui_in[1] = manual stepping
DESCENDING = 0b001   # ui_in[0] = sort descending
BTN = 0b100          # ui_in[2] = step button


async def reset(dut, ui_base):
    cocotb.start_soon(Clock(dut.clk, 10, unit="us").start())
    dut.ena.value = 1
    dut.uio_in.value = 0
    dut.ui_in.value = ui_base
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)


async def step(dut, ui_base, n=1):
    for _ in range(n):
        dut.ui_in.value = ui_base | BTN
        await ClockCycles(dut.clk, 4)
        dut.ui_in.value = ui_base
        await ClockCycles(dut.clk, 4)


async def read_bars(dut):
    """Watch the column scan and rebuild the 8 slot values from the pins."""
    vals = [None] * 8
    done = 0
    while any(v is None for v in vals):
        await RisingEdge(dut.clk)
        col = int(dut.uio_out.value) & 0b111
        rows = int(dut.uo_out.value)
        vals[col] = bin(rows).count("1") - 1   # thermometer code: height 1..8 -> value 0..7
        done = (int(dut.uio_out.value) >> 3) & 1
    return vals, done


@cocotb.test()
async def test_fill_is_not_constant(dut):
    ui = MANUAL
    await reset(dut, ui)
    await step(dut, ui, 8)                     # FILL: 8 ticks
    vals, done = await read_bars(dut)
    dut._log.info(f"after fill: {vals}")
    assert done == 0
    assert len(set(vals)) > 1, "LFSR fill produced identical values"


@cocotb.test()
async def test_sorts_ascending(dut):
    ui = MANUAL
    await reset(dut, ui)
    await step(dut, ui, 8)                     # FILL
    await step(dut, ui, 8)                     # SORT
    vals, done = await read_bars(dut)
    dut._log.info(f"ascending: {vals}")
    assert vals == sorted(vals)
    assert done == 1, "done flag (uio_out[3]) should be high while holding"


@cocotb.test()
async def test_sorts_descending(dut):
    ui = MANUAL | DESCENDING
    await reset(dut, ui)
    await step(dut, ui, 16)                    # FILL + SORT
    vals, done = await read_bars(dut)
    dut._log.info(f"descending: {vals}")
    assert vals == sorted(vals, reverse=True)
    assert done == 1


@cocotb.test()
async def test_loops_back_to_fill(dut):
    ui = MANUAL
    await reset(dut, ui)
    await step(dut, ui, 16)                    # FILL + SORT -> HOLD
    await step(dut, ui, 16)                    # HOLD -> FILL
    _, done = await read_bars(dut)
    assert done == 0, "should have left HOLD and started refilling"
