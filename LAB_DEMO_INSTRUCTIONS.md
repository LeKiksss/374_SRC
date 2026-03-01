# ELEC 374 Phase 1 – Lab Demo Instructions for TA

This document gives **step-by-step instructions** to demonstrate your Mini SRC datapath exactly as required by the **CPU Phase 1** handout. Use it as your script when showing the TA.

---

## What the handout requires (Section 3)

You must demonstrate **functional simulation** for all 13 instructions:

| Section | Instruction   | Example / Notes                          |
|---------|---------------|------------------------------------------|
| 3.1     | AND           | and R2, R5, R6                           |
| 3.2     | OR            | or R2, R5, R6                            |
| 3.3     | ADD           | add R2, R5, R6                           |
| 3.4     | SUB           | sub R2, R5, R6                           |
| 3.5     | MUL           | mul R3, R1 → result in HI, LO             |
| 3.6     | DIV           | div R3, R1 → quotient in LO, remainder in HI |
| 3.7     | SHR           | shr R7, R0, R4 (shift count in R4)        |
| 3.8     | SHRA          | shra R7, R0, R4                           |
| 3.9     | SHL           | shl R7, R0, R4                            |
| 3.10    | ROR           | ror R7, R0, R4                            |
| 3.11    | ROL           | rol R7, R0, R4                            |
| 3.12    | NEG           | neg R4, R7                                |
| 3.13    | NOT           | not R4, R7                                |

**Minimum outputs to show (handout):** R0, R1, …, R15, HI, LO, IR, BusMuxOut, Z (and any others you wish).

---

## Before the lab (preparation)

1. **Open the project**
   - Start **Quartus Prime Lite**.
   - **File → Open Project**.
   - Go to your project folder and select **`phase_1.qpf`**.
   - Wait until the project loads.

2. **Confirm simulation setup**
   - **Assignments → Settings**.
   - In the left pane, open **Simulation** (under EDA Tool Settings).
   - Ensure **Tool name** is **ModelSim-Altera (Verilog)**.
   - Under **Test Benches**, add **all 13 test benches** (one per instruction) so you don’t have to edit settings between demos. Click **Test Benches…**, then **New** for each entry:

     | Test bench name | Top level module in test bench |
     |-----------------|---------------------------------|
     | AND_test        | datapath_tb                     |
     | OR_test         | tb_or                           |
     | ADD_test        | tb_add                          |
     | SUB_test        | tb_sub                          |
     | MUL_test        | tb_mul                          |
     | DIV_test        | tb_div                          |
     | SHR_test        | tb_shr                          |
     | SHRA_test       | tb_shra                         |
     | SHL_test        | tb_shl                          |
     | ROR_test        | tb_ror                          |
     | ROL_test        | tb_rol                          |
     | NEG_test        | tb_neg                          |
     | NOT_test        | tb_not                          |

     Use **“Use project design files”** (or add your project’s .v files) for each test bench. Click **OK** for each, then **OK** to close Settings.
   - When you run simulation, you will **select which test bench to run** (see Step 1 in “Step-by-step” below). In some Quartus versions the list shows all test benches and you choose one (e.g. by double‑clicking or “Run” next to it); in others you may need to set one as active or run the one at the top and reorder the list. If your version only runs one test bench per launch, re-open **Test Benches…** and move the test bench you want to run to the **top** of the list, then run RTL Simulation.
   - Click **OK**.

3. **Optional: have ModelSim script ready**
   - In the project folder, open **`run_and_test.do`** in a text editor.
   - To run a different instruction, change only the last line (`vsim ...`) to the module name for that instruction (see table in Section 4 below).

---

## Step-by-step: running one instruction (e.g. AND first)

Do this once in full; for other instructions you only change the testbench top and rerun.

### 1. Set which testbench runs (simulation top)

- **If you added all 13 test benches:** In Quartus: **Assignments → Settings → Simulation → Test Benches…**. In the list, **select** the test bench for the instruction you are demonstrating (e.g. **AND_test** for 3.1, **OR_test** for 3.2). In Quartus 18.1, the tool often runs the **first** test bench in the list—so **move the one you want to the top** (e.g. use **Up** / **Down** if available), then click **OK**, **OK**.
- **If you only have one test bench entry:** Edit it and set **“Top level module in test bench”** to the module for this instruction (e.g. `datapath_tb` for AND, `tb_or` for OR—see table in Section 4). Click **OK**, **OK**.

### 2. Start RTL simulation

1. In Quartus: **Tools → Run Simulation Tool → RTL Simulation**.
2. Wait for ModelSim to start and finish compiling (Transcript window shows “Compilation successful” or similar).
3. The simulation will load with the testbench you selected; the design is at `work.<module_name>` (e.g. `work.datapath_tb`).

### 3. Add the required waveforms (for TA)

1. In ModelSim **Sim** (or **Library**) window, expand **work** and double‑click your testbench (e.g. **datapath_tb**) to load it as the current design (if not already).
2. Open the **Wave** window: **View → Wave** (or click the Wave icon).
3. In the **sim - Default** (hierarchy) pane, expand **datapath_tb** (click the **+** next to it), then expand **DUT** (click the **+** next to DUT). This makes the DUT’s signals show up in the **Objects** pane.
4. In the **Objects** pane, you should now see DUT’s ports. The list may show inputs first (Clock, Rin, PCin, …). **Scroll down** in the Objects list to find the **outputs**: **BusMuxOut**, **Z**, **IR**, **PC**, **HI**, **LO**, **R0** … **R15**. (If you don’t see them after expanding DUT, click **DUT** once in the sim - Default pane so Objects refreshes to DUT’s signals.)
5. Add these **DUT** outputs to the Wave window (handout minimum):
   - **BusMuxOut**, **Z**, **IR**, **PC**, **HI**, **LO**, **R0** through **R15**
   - To add: in **Objects**, select each signal (or **Ctrl+click** to select several), then **right‑click → Add Wave** (or drag the selection into the Wave window).
6. **Optional but useful:** add **Present_state** and **Clock** from **datapath_tb** (select **datapath_tb** in the hierarchy, then in Objects add **Present_state** and **Clock**) so the TA can see timing.
7. Set **Radix** to **Hexadecimal** for bus signals: in the **Wave** window, right‑click each multi‑bit signal (e.g. BusMuxOut, Z, IR, PC, HI, LO, R0–R15) → **Radix → Hexadecimal**. (You can select multiple waves, then right‑click → Radix → Hexadecimal once.)

### 4. Run the simulation

1. In the Wave window or Transcript: **Run → Run All** (or in Transcript type **`run 5us`** or **`run -all`**).
2. If needed, **Zoom Full** (e.g. **View → Zoom → Zoom Full** or the Zoom Full button) so the whole run is visible.

### 5. Show the result for that instruction

- For **AND (3.1)**: After the run, show that **R2** = **0x04** (because R5 = 0x34, R6 = 0x45, and 0x34 & 0x45 = 0x04). Point out **R5**, **R6**, and **R2** in the waveform.
- For other instructions, use the “What to show the TA” column in **Section 4** and the “Expected results” in **Section 5**.

### 6. Repeat for the next instruction

1. **Stop** the simulation if it’s still running: **Simulate → End Simulation** (or **Simulate → Restart** if you prefer a clean run).
2. Change which test bench runs: **Assignments → Settings → Simulation → Test Benches…**. If you added all 13 test benches, **move the next test bench to the top** of the list (e.g. **OR_test** for 3.2) and click **OK**, **OK**. If you use a single entry, set **“Top level module in test bench”** to the next module (e.g. **`tb_or`**).
3. **Tools → Run Simulation Tool → RTL Simulation** again. ModelSim may restart; re-add the same waves (or reload a saved wave format if you have one) and run again.
4. Repeat until you have shown all 13 instructions (3.1–3.13).

---

## Section 4: Simulation top module for each instruction

| Handout section | Instruction | Top level module in test bench |
|-----------------|-------------|---------------------------------|
| 3.1             | AND         | **datapath_tb**                 |
| 3.2             | OR          | **tb_or**                       |
| 3.3             | ADD         | **tb_add**                      |
| 3.4             | SUB         | **tb_sub**                      |
| 3.5             | MUL         | **tb_mul**                      |
| 3.6             | DIV         | **tb_div**                      |
| 3.7             | SHR         | **tb_shr**                      |
| 3.8             | SHRA        | **tb_shra**                     |
| 3.9             | SHL         | **tb_shl**                      |
| 3.10            | ROR         | **tb_ror**                      |
| 3.11            | ROL         | **tb_rol**                      |
| 3.12            | NEG         | **tb_neg**                      |
| 3.13            | NOT         | **tb_not**                      |

---

## Section 5: Control sequences and what to show the TA

Each test follows the handout’s control sequence. Below: what happens in the test and what result to show.

### 3.1 AND (and R2, R5, R6)

- **Preload (testbench):** R5 = 0x34, R6 = 0x45, R2 = 0x67 (then overwritten by result).
- **Fetch:** T0 (PCout, MARin, IncPC, Zin), T1 (Zlowout, PCin, Read, Mdatain, MDRin), T2 (MDRout, IRin).
- **Execute:** T3 (R5out, Yin), T4 (R6out, AND, Zin), T5 (Zlowout, R2in).
- **Show:** **R2 = 0x04** (0x34 & 0x45 = 0x04). Point to R5, R6, and R2 in the waveform.

### 3.2 OR (or R2, R5, R6)

- Same sequence as AND; T4 uses **OR** instead of AND.
- **Show:** **R2 = 0x75** (0x34 | 0x45 = 0x75).

### 3.3 ADD (add R2, R5, R6)

- Same structure; T4 uses **ADD**.
- **Show:** **R2 = 0x79** (0x34 + 0x45 = 0x79).

### 3.4 SUB (sub R2, R5, R6)

- Same structure; T4 uses **SUB**.
- **Show:** **R2 = 0xFFFFFFEF** (0x34 − 0x45 in 32‑bit two’s complement = −17). (If your testbench uses different R5/R6 values, compute R5−R6 and show that R2 matches.)

### 3.5 MUL (mul R3, R1)

- **Preload:** R3 and R1 with two operands (e.g. R3 = 100, R1 = 7).
- **Fetch:** T0–T2. **Execute:** T3 (R3out, Yin), T4 (R1out, MUL, Zin), T5 (Zlowout, LOin), T6 (Zhighout, HIin).
- **Show:** **LO** = low 32 bits of product, **HI** = high 32 bits (e.g. 100×7 = 700 → LO = 700, HI = 0).

### 3.6 DIV (div R3, R1)

- Same structure as MUL; T4 uses **DIV**. Z holds {remainder, quotient}; handout: quotient in lower part, remainder in higher part.
- **Show:** **LO** = quotient, **HI** = remainder (e.g. 100 ÷ 7 → quotient 14, remainder 2).

### 3.7 SHR (shr R7, R0, R4)

- **Preload:** R0 = value to shift, R4 = shift count (e.g. 2). T3 (R0out, Yin), T4 (R4out, SHR, Zin), T5 (Zlowout, R7in).
- **Show:** **R7** = R0 logically shifted right by R4 (e.g. 0xF000_0008 >> 2 = 0x3C00_0002).

### 3.8 SHRA (shra R7, R0, R4)

- Same as SHR; T4 uses **SHRA** (arithmetic right shift).
- **Show:** **R7** = R0 arithmetically shifted right by R4 (sign extension).

### 3.9 SHL (shl R7, R0, R4)

- Same as SHR; T4 uses **SHL**.
- **Show:** **R7** = R0 shifted left by R4.

### 3.10 ROR (ror R7, R0, R4)

- T4 uses **ROR**. **Show:** **R7** = R0 rotated right by R4.

### 3.11 ROL (rol R7, R0, R4)

- T4 uses **ROL**. **Show:** **R7** = R0 rotated left by R4.

### 3.12 NEG (neg R4, R7)

- **Preload:** R7 = operand (e.g. −5 = 0xFFFFFFFB). T3 (R7out, NEG, Zin), T4 (Zlowout, R4in).
- **Show:** **R4** = two’s complement of R7 (e.g. −(−5) = 5 = 0x00000005).

### 3.13 NOT (not R4, R7)

- Same structure; T3 uses **NOT**.
- **Show:** **R4** = bitwise NOT of R7 (e.g. NOT 0x000000FF = 0xFFFFFF00).

---

## Section 6: Quick checklist for the TA

- [ ] Project opens in Quartus (**phase_1.qpf**).
- [ ] Simulation uses **ModelSim-Altera (Verilog)**.
- [ ] For each of 3.1–3.13:
  - [ ] Simulation top set to the correct module (Section 4 table).
  - [ ] RTL Simulation run; waveforms show at least **BusMuxOut, Z, IR, HI, LO, R0–R15** (and PC if you like).
  - [ ] Result register(s) match the expected value for that instruction (Section 5).
- [ ] Report (if required) includes: Verilog code, testbenches (or one plus differences), and simulation runs for **all** tests 3.1–3.13.

---

## Section 7: If you use the ModelSim .do script instead of Quartus

1. Start **ModelSim - Intel FPGA Edition** (or run it once from Quartus via **Tools → Run Simulation Tool → RTL Simulation**).
2. In the transcript: **`cd <full_path_to_phase_1_folder>`** then **`do run_and_test.do`**.
3. Before running the script, edit **run_and_test.do** and set the last line to **`vsim -t 1ps work.<module_name>`** with `<module_name>` from the Section 4 table (e.g. `work.datapath_tb`, `work.tb_or`, …).
4. After **vsim** runs, add waves as in Section “Step-by-step” (paragraph 3) and run (e.g. **`run 5us`**).

---

## Section 8: Report (handout Section 4)

- Upload **Phase 1 Lab report** (PDF) to onQ by the deadline.
- Include:
  - Verilog code (and schematic, if any).
  - Testbenches (if similar, one full testbench + short description of differences for others).
  - **Functional simulation runs for all tests 3.1–3.13** (waveform screenshots or exported figures).

Use this document as your lab demo script and adjust any opcode or test values to match your Mini SRC specification if your instructor provides one.
