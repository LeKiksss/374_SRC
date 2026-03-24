# ELEC 374 Mini SRC Phase 2 README

This README explains how to run each individual Phase 2 lab procedure item from `3.1` to `3.7` using the code in `project/phase_1` with Intel Quartus and ModelSim-Intel FPGA Edition.

The repository already contains:

- the Phase 2 datapath changes
- the RAM preload file
- one testbench per lab section
- standalone testbenches that each drive their own cycle-by-cycle control signals

The Phase 2 testbenches are:

- `tb_phase2_load.v` for `3.1`
- `tb_phase2_store.v` for `3.2`
- `tb_phase2_immediate.v` for `3.3`
- `tb_phase2_branch.v` for `3.4`
- `tb_phase2_jump.v` for `3.5`
- `tb_phase2_special.v` for `3.6`
- `tb_phase2_io.v` for `3.7`

The main Phase 2 datapath files are:

- `datapath_top.v`
- `datapath.v`
- `select_encode.v`
- `ram512x32.v`
- `con_ff.v`
- `mdr.v`
- `phase2_memory_init.hex`

## What Each Testbench Does

Each Phase 2 testbench:

- manually drives the control signals exactly as the lab asks
- runs the instruction fetch cycles `T0` to `T2`
- runs the required execution cycles for that instruction group
- prints the datapath state every clock step
- prints `PASS` or `FAIL` messages for each case

The output lines show values such as:

- `BUS`
- `PC`
- `IR`
- `MAR`
- `MDR`
- `MEM`
- `Y`
- `Zlow`
- `CON`
- selected general-purpose registers
- `OUT`
- `IN`

That makes it easier to demonstrate the control sequence timing to a TA.

## Prerequisites

You should have:

- Intel Quartus Prime Lite 18.1
- ModelSim-Intel FPGA Edition
- the Quartus project in `project/phase_1`

Open this project file in Quartus:

- `project/phase_1/phase_1.qpf`

## Recommended Workflow

The easiest workflow is:

1. Open `phase_1.qpf` in Quartus.
2. Use Quartus only as the project manager and source organizer.
3. Launch ModelSim from the Quartus environment.
4. Compile the Verilog files.
5. Run one Phase 2 testbench at a time.

You do not need to synthesize the design to run these functional simulations.

## One-Time Setup in Quartus

1. Open Quartus.
2. Select `File > Open Project`.
3. Open `project/phase_1/phase_1.qpf`.
4. In Quartus, confirm the Phase 2 files appear in the project navigator.
5. Make sure the memory init file `phase2_memory_init.hex` is present in the same folder as the Verilog files.

Notes:

- The `.qsf` already includes the Phase 2 Verilog files and the hex file.
- The old Phase 1 NativeLink testbench entries are still present in the `.qsf`, but the Phase 2 benches are easiest to run directly from ModelSim using the commands below.

## Launching ModelSim From Quartus

Use one of these approaches:

1. `Tools > Run Simulation Tool > RTL Simulation`
2. Or `Tools > Launch Simulation Library Compiler`, then open ModelSim manually if needed

If Quartus opens ModelSim for you, make sure the working directory is `project/phase_1`.

## Compile Command

Run this once in the ModelSim Transcript before running any of the Phase 2 benches:

```tcl
vlib work
vlog datapath_top.v datapath.v mdr.v general_purpose_register.v alu_core.v inc32.v addsub32.v adder32.v mult32x32_booth.v div32_nonrestoring.v select_encode.v con_ff.v ram512x32.v tb_phase2_load.v tb_phase2_store.v tb_phase2_immediate.v tb_phase2_branch.v tb_phase2_jump.v tb_phase2_special.v tb_phase2_io.v
```

What you should see:

- each module being compiled
- no syntax errors
- top-level modules listed:
  - `tb_phase2_load`
  - `tb_phase2_store`
  - `tb_phase2_immediate`
  - `tb_phase2_branch`
  - `tb_phase2_jump`
  - `tb_phase2_special`
  - `tb_phase2_io`

If you want to recompile after editing a file, just run the `vlog ...` line again.

## Running a Testbench

For any Phase 2 part, use:

```tcl
vsim tb_phase2_load
run -all
```

Replace `tb_phase2_load` with the bench for the section you want to run.

If you prefer the console-only version:

```tcl
vsim -c tb_phase2_load -do "run -all; quit -f"
```

## Optional Waveform Setup

If you want a visual waveform in ModelSim:

```tcl
vsim tb_phase2_load
add wave *
run -all
```

For more useful detail, add internal signals:

```tcl
add wave sim:/tb_phase2_load/BusMuxOut
add wave sim:/tb_phase2_load/PC
add wave sim:/tb_phase2_load/IR
add wave sim:/tb_phase2_load/MAR
add wave sim:/tb_phase2_load/MDR
add wave sim:/tb_phase2_load/MemoryData
add wave sim:/tb_phase2_load/CON
add wave sim:/tb_phase2_load/R0
add wave sim:/tb_phase2_load/R2
add wave sim:/tb_phase2_load/R7
run -all
```

## 3.1 Load Instructions: `ld`, `ldi`

Testbench:

- `tb_phase2_load.v`

Run:

```tcl
vsim tb_phase2_load
run -all
```

What this testbench checks:

- `ld R7, 0x65`
- `ld R0, 0x72(R2)`
- `ldi R7, 0x65`
- `ldi R0, 0x72(R2)`

Important files involved:

- `ram512x32.v`
- `phase2_memory_init.hex`
- `select_encode.v`
- `datapath.v`
- `datapath_top.v`

Memory values used:

- `mem[0x65] = 0x00000084`
- `mem[0xC9] = 0x0000002B`

What you should see:

- `T0`, `T1`, and `T2` fetch the instruction
- for `ld`, `MAR` should receive the effective address in `T5`
- in `T6`, `MDR` should load the value from memory
- in `T7`, the destination register should receive the data from `MDR`
- for `ldi`, the result should go directly from `Zlow` into the destination register without the second memory read

Example behavior:

- `ld R7, 0x65` should finish with `R7 = 00000084`
- `ld R0, 0x72(R2)` with `R2 = 00000057` should show:
  - `BAout with R2 base = 00000057`
  - effective address `0x72 + 0x57 = 0xC9`
  - final `R0 = 0000002B`
- `ldi R7, 0x65` should finish with `R7 = 00000065`
- `ldi R0, 0x72(R2)` should finish with `R0 = 000000C9`

Typical pass lines:

```text
PASS: ld R7, 0x65 = 00000084
PASS: BAout with R2 base = 00000057
PASS: ld R0, 0x72(R2) = 0000002b
PASS: ldi R7, 0x65 = 00000065
PASS: ldi R0, 0x72(R2) = 000000c9
PASS: GROUP 0 completed with no failures
```

## 3.2 Store Instruction: `st`

Testbench:

- `tb_phase2_store.v`

Run:

```tcl
vsim tb_phase2_store
run -all
```

What this testbench checks:

- `st 0x1F, R6`
- `st 0x1F(R6), R6`

Important files involved:

- `ram512x32.v`
- `mdr.v`
- `select_encode.v`
- `datapath.v`

Initial values:

- `R6 = 00000063`
- `mem[0x1F] = 000000D4`
- `mem[0x82] = 000000A7`

What you should see:

- `T0` to `T5` compute the effective address the same way as load
- `T6` places the source register onto the bus and loads it into `MDR`
- `T7` asserts `Write`, so the RAM stores `MDR` into `memory[MAR]`
- `T8` and `T9` read back the memory so the testbench can confirm the write succeeded

Example behavior:

- for `st 0x1F, R6`, the memory at `0x1F` should change from `000000D4` to `00000063`
- for `st 0x1F(R6), R6`, the effective address should become `0x82`, and memory at `0x82` should become `00000063`

Typical pass lines:

```text
PASS: st 0x1F, R6 memory readback = 00000063
PASS: st 0x1F(R6), R6 memory readback = 00000063
PASS: GROUP 1 completed with no failures
```

## 3.3 ALU Immediate Instructions: `addi`, `andi`, `ori`

Testbench:

- `tb_phase2_immediate.v`

Run:

```tcl
vsim tb_phase2_immediate
run -all
```

What this testbench checks:

- `addi R7, R4, -9`
- `andi R7, R4, 0x71`
- `ori R7, R4, 0x71`

Important files involved:

- `select_encode.v`
- `datapath.v`
- `alu_core.v`

What you should see:

- `T3` loads the source register into `Y`
- `T4` gates the sign-extended immediate through `Cout`
- the ALU performs `ADD`, `AND`, or `OR`
- `Zlow` captures the result
- `T5` writes `Zlow` into the destination register

Example behavior:

- `addi` uses `-9`, so the bus at `T4` should show the sign-extended constant:
  - `FFFFFFFFF7` as a 32-bit two's complement value, displayed as `fffffff7`
- if `R4 = 00000034`, then `R7` should become `0000002B`
- `andi` with `R4 = 000000F3` and immediate `0x71` should give `00000071`
- `ori` with `R4 = 00000004` and immediate `0x71` should give `00000075`

Typical pass lines:

```text
PASS: addi sign-extended constant = fffffff7
PASS: addi R7, R4, -9 = 0000002b
PASS: andi R7, R4, 0x71 = 00000071
PASS: ori R7, R4, 0x71 = 00000075
PASS: GROUP 2 completed with no failures
```

## 3.4 Branch Instructions: `brzr`, `brnz`, `brpl`, `brmi`

Testbench:

- `tb_phase2_branch.v`

Run:

```tcl
vsim tb_phase2_branch
run -all
```

What this testbench checks:

- `brzr` taken and not taken
- `brnz` taken and not taken
- `brpl` taken and not taken
- `brmi` taken and not taken

Important files involved:

- `con_ff.v`
- `select_encode.v`
- `datapath.v`
- `alu_core.v`

Branch offset used:

- `C = 48`

PC setup used in the bench:

- initial PC before fetch is `0x10`
- after fetch, the PC becomes `0x11`
- if branch is taken, the new PC becomes `0x11 + 0x30 = 0x41`

What you should see:

- in `T3`, the selected register goes onto the bus and the `CON` flip-flop is loaded
- the testbench prints whether `CON` is `1` or `0`
- in `T4` and `T5`, the datapath computes `PC + 1 + C`
- in `T6`, `PCin` is only asserted when `CON = 1`

Example behavior:

- for `brzr` with `R3 = 0`, you should see:
  - `PASS: brzr taken CON = 1`
  - final `PC = 00000041`
- for `brzr` with `R3 != 0`, you should see:
  - `PASS: brzr not taken CON = 0`
  - final `PC = 00000011`
- similar patterns occur for `brnz`, `brpl`, and `brmi`

Typical pass lines:

```text
PASS: brzr taken CON = 1
PASS: brzr taken = 00000041
PASS: brzr not taken CON = 0
PASS: brzr not taken = 00000011
PASS: brnz taken CON = 1
PASS: brnz taken = 00000041
PASS: brpl taken CON = 1
PASS: brpl taken = 00000041
PASS: brmi taken CON = 1
PASS: brmi taken = 00000041
PASS: GROUP 3 completed with no failures
```

## 3.5 Jump Instructions: `jr`, `jal`

Testbench:

- `tb_phase2_jump.v`

Run:

```tcl
vsim tb_phase2_jump
run -all
```

What this testbench checks:

- `jr R12`
- `jal R4`

Important files involved:

- `select_encode.v`
- `datapath.v`
- `datapath_top.v`

What you should see for `jr`:

- `R12` is preloaded with `000000FF`
- after fetch, `T3` places `R12` on the bus and loads `PC`
- final `PC` should be `000000FF`

What you should see for `jal`:

- `R4` is the jump target
- `R12` is used as the return address register in this bench
- after fetch from address `0x20`, the PC becomes `0x21`
- `T3` writes that return address into `R12`
- `T4` jumps to the address in `R4`

Example behavior:

- `jr R12` should end with `PC = 000000FF`
- `jal R4` should show:
  - `R12 = 00000021`
  - `PC = 000000A5`

Typical pass lines:

```text
PASS: jr R12 = 000000ff
PASS: jal link register = 00000021
PASS: jal jump target = 000000a5
PASS: GROUP 4 completed with no failures
```

## 3.6 Special Instructions: `mfhi`, `mflo`

Testbench:

- `tb_phase2_special.v`

Run:

```tcl
vsim tb_phase2_special
run -all
```

What this testbench checks:

- `mfhi R5`
- `mflo R1`

Important files involved:

- `datapath.v`
- `datapath_top.v`
- `select_encode.v`

What you should see:

- for `mfhi`, `HIout` drives the bus and `Gra + Rin` loads the destination register
- for `mflo`, `LOout` drives the bus and `Gra + Rin` loads the destination register

Example behavior:

- if `HI = 12345678`, then `R5` should become `12345678`
- if `LO = 89ABCDEF`, then `R1` should become `89ABCDEF`

Typical pass lines:

```text
PASS: mfhi R5 = 12345678
PASS: mflo R1 = 89abcdef
PASS: GROUP 5 completed with no failures
```

## 3.7 Input/Output Instructions: `in`, `out`

Testbench:

- `tb_phase2_io.v`

Run:

```tcl
vsim tb_phase2_io
run -all
```

What this testbench checks:

- `out R7`
- `in R5`

Important files involved:

- `datapath.v`
- `datapath_top.v`
- `select_encode.v`

What you should see for `out`:

- `R7` is preloaded with `CAFEBABE`
- in `T3`, `Gra + Rout + Out_Portin` sends the selected register onto the bus and latches it into `Out_Port`
- final `Out_Port` should be `CAFEBABE`

What you should see for `in`:

- `port_in` is set to `13579BDF`
- `In_Portout` drives that value onto the bus
- `Gra + Rin` writes it into `R5`

Typical pass lines:

```text
PASS: out R7 = cafebabe
PASS: in R5 = 13579bdf
PASS: GROUP 6 completed with no failures
```

## Quick Command Reference

Compile once:

```tcl
vlib work
vlog datapath_top.v datapath.v mdr.v general_purpose_register.v alu_core.v inc32.v addsub32.v adder32.v mult32x32_booth.v div32_nonrestoring.v select_encode.v con_ff.v ram512x32.v tb_phase2_load.v tb_phase2_store.v tb_phase2_immediate.v tb_phase2_branch.v tb_phase2_jump.v tb_phase2_special.v tb_phase2_io.v
```

Run `3.1`:

```tcl
vsim tb_phase2_load
run -all
```

Run `3.2`:

```tcl
vsim tb_phase2_store
run -all
```

Run `3.3`:

```tcl
vsim tb_phase2_immediate
run -all
```

Run `3.4`:

```tcl
vsim tb_phase2_branch
run -all
```

Run `3.5`:

```tcl
vsim tb_phase2_jump
run -all
```

Run `3.6`:

```tcl
vsim tb_phase2_special
run -all
```

Run `3.7`:

```tcl
vsim tb_phase2_io
run -all
```

## What Counts as Success

For each section, success means:

- the simulation finishes without compile or runtime errors
- each case prints `PASS`
- the final line says the group completed with no failures

Examples:

```text
PASS: GROUP 0 completed with no failures
PASS: GROUP 1 completed with no failures
PASS: GROUP 2 completed with no failures
PASS: GROUP 3 completed with no failures
PASS: GROUP 4 completed with no failures
PASS: GROUP 5 completed with no failures
PASS: GROUP 6 completed with no failures
```

## Notes for Lab Demo

For a demo, it is useful to show:

- the instruction fetch cycles `T0`, `T1`, `T2`
- the execution cycles for the selected instruction
- the relevant register before and after execution
- `MAR`, `MDR`, and memory contents for load/store
- `CON` and `PC` for branch
- `Out_Port` and `In_Port` for I/O

If the TA wants waveforms instead of only transcript text, add the key signals to the waveform window before running.

