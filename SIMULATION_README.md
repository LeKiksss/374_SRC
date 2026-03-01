# Running Testbenches in Quartus Prime Lite Edition

Your project uses **ModelSim-Altera (Verilog)** for simulation. Follow one of the two methods below.

---

## Method 1: Run from Quartus (recommended for first time)

### 1. Open simulation settings

1. In Quartus Prime Lite, open your project: **File → Open Project** → select `phase_1.qpf`.
2. Go to **Assignments → Settings**.
3. In the left category list, open **Simulation** (under “EDA Tool Settings” or under “Compilation Process”).

### 2. Set the simulation top (testbench to run)

1. Under **Simulation**, find **“Compile test bench”** or **“Test Benches”**.
2. Click **“Test Benches…”** (or “Add” / “…” next to “Compile test bench”).
3. In the dialog:
   - **Test bench name**: e.g. `AND_test` (any label you like).
   - **Top level module in test bench**: set to the **module name** of the testbench you want to run:
     - AND: `datapath_tb`
     - OR: `tb_or`
     - ADD: `tb_add`
     - SUB: `tb_sub`
     - MUL: `tb_mul`
     - DIV: `tb_div`
     - SHR: `tb_shr`
     - SHRA: `tb_shra`
     - SHL: `tb_shl`
     - ROR: `tb_ror`
     - ROL: `tb_rol`
     - NEG: `tb_neg`
     - NOT: `tb_not`
   - **Test bench and design files**: Click “…” and add all your Verilog files, or leave “Use project design files” checked so Quartus uses the files already in the project.
4. Click **OK**, then **OK** again to close Settings.

### 3. Launch RTL simulation

1. **Tools → Run Simulation Tool → RTL Simulation** (or **Gate Level Simulation** if you have already compiled the design).
2. ModelSim will start, compile the design and testbench, and run with the top module you set (e.g. `datapath_tb`).
3. In ModelSim, add waves for the signals you care about (e.g. `DUT/R2`, `DUT/BusMuxOut`, `Present_state`, `Clock`), then run (e.g. **Run → Run All** or set a run time).

### 4. Switching to another testbench

- Repeat **Method 1, steps 1–2**.
- Change **“Top level module in test bench”** to the desired module (e.g. `tb_add`, `tb_mul`, `tb_neg`, etc.).
- Run **Tools → Run Simulation Tool → RTL Simulation** again.

---

## Method 2: Run from ModelSim with a script

If you prefer to run ModelSim directly (or Quartus does not list “Test Benches”):

### 1. Launch ModelSim

- From Quartus: **Tools → Run Simulation Tool → RTL Simulation**,  
  **or** start **ModelSim - Intel FPGA Edition** from the Start menu and `cd` to your project folder:  
  `cd <path_to_project>\phase_1`

### 2. Use the supplied script

In the `phase_1` folder there is a script **`run_and_test.do`** that compiles all sources and runs the **AND** testbench (`datapath_tb`).

In ModelSim transcript:

```tcl
do run_and_test.do
```

Then add waves and run (e.g. `run 5us`).

### 3. Run a different testbench

Edit `run_and_test.do` and change the last `vsim` line from:

```tcl
vsim datapath_tb
```

to one of:

```tcl
vsim tb_or
vsim tb_add
vsim tb_sub
vsim tb_mul
vsim tb_div
vsim tb_shr
vsim tb_shra
vsim tb_shl
vsim tb_ror
vsim tb_rol
vsim tb_neg
vsim tb_not
```

Save the file and run `do run_and_test.do` again.

---

## Quick reference: testbench ↔ top module name

| Instruction | Top module name |
|-------------|------------------|
| AND (and R2,R5,R6) | `datapath_tb` |
| OR  | `tb_or`  |
| ADD | `tb_add` |
| SUB | `tb_sub` |
| MUL | `tb_mul` |
| DIV | `tb_div` |
| SHR | `tb_shr` |
| SHRA | `tb_shra` |
| SHL | `tb_shl` |
| ROR | `tb_ror` |
| ROL | `tb_rol` |
| NEG | `tb_neg` |
| NOT | `tb_not` |

---

## If “Test Benches” is missing in Quartus 18.1

- Look under **Assignments → Settings → EDA Tool Settings → Simulation**.
- Ensure **“Tool name”** is set to **ModelSim-Altera (Verilog)**.
- If your menu shows **“Compile test bench”** with a single box, use that to point to `testbench.v` and set **“Top level module”** to `datapath_tb` (or the module you want).
- After changing the top module, run **Tools → Run Simulation Tool → RTL Simulation** again.
