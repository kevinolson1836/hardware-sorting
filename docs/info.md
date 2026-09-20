## How it works

A free-running 16-bit LFSR generates pseudo-random bits. On each tick the chip
shifts one new 3-bit random value into an 8-slot register, so eight ticks fill
all slots. It then runs an odd-even transposition sort, one phase per tick:
even phases compare slots (0,1)(2,3)(4,5)(6,7) and odd phases compare
(1,2)(3,4)(5,6). Eight phases fully sort the slots. The result is held for 16
ticks, then the chip refills and repeats.

The slots are shown as a bar chart. A fast internal counter scans through the
8 columns. `uio[2:0]` is the column number and `uo[7:0]` is that column's bar
as a thermometer code (value 0 lights 1 row, value 7 lights all 8).

Ticks come from a clock divider (auto mode) or from the step button (manual
mode). The divider values assume roughly a 10 MHz clock.

## How to test

Set `ui[1]` high for manual mode and press `ui[2]` to advance one tick at a
time: 8 presses fill, 8 presses sort, then the sorted flag on `uio[3]` goes high.
Set `ui[0]` high to sort descending. In auto mode, leave `ui[1]` low and pick a
speed with `ui[4:3]`.

## External hardware

An 8x8 LED matrix (or 8 bar LEDs per column), a 3-to-8 decoder such as a 74HC138
on `uio[2:0]` to select the active column, current-limiting resistors, and buffers
or transistors to drive the LEDs. A debounced push button for `ui[2]`.
