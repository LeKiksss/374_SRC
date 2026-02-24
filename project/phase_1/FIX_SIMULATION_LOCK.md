# Fix: ModelSim "Waiting for lock" / testbench not running

## What’s wrong
Quartus runs a script that does `vdel -lib rtl_work -all` before creating a fresh `rtl_work`. Another ModelSim (or a leftover lock) is holding that library, so the script waits forever and **Load canceled** — the testbench never starts.

## Fix (do in order)

### 1. Close everything
- Close **all** ModelSim windows.
- Close **Quartus** (or at least don’t run simulation again until step 3 is done).

### 2. Kill any stuck ModelSim
- Press **Ctrl+Shift+Esc** → **Task Manager**.
- Under **Processes**, look for:
  - `vsim.exe` (ModelSim)
  - `modelsim.exe`
  - Anything like `vsim*` or `*modelsim*`
- **End task** for each one.
- Optional: also end any **Quartus** process if you closed the window but it’s still running.

### 3. Remove the lock and library (so the script can recreate them)
- Open **File Explorer** and go to:
  ```
  C:\Users\21wys1\Documents\GitHub\374_SRC\project\phase_1\simulation\modelsim
  ```
- If you see a folder **`rtl_work`**:
  - Delete the **whole** `rtl_work` folder (right‑click → Delete).
  - That removes the lock file inside it (`_lock`) and the library.
- If you don’t see `rtl_work`, look for a file named **`_lock`** anywhere under `simulation\modelsim` and delete it.

### 4. Run simulation again
- Start **Quartus**.
- Open project **phase_1.qpf**.
- Set your test bench in **Assignments → Settings → Simulation** (e.g. top module **tb_add**).
- **Tools → Run Simulation Tool → RTL Simulation**.

The script will create a new `rtl_work`, compile, and run `vsim tb_add`; you should see the testbench in the Sim pane and be able to add waves and run.

---

## If it still locks

- Run RTL Simulation **once** and wait for it to fully finish (or quit ModelSim normally).
- Don’t run a second RTL Simulation while the first ModelSim is still open.
- If you use ModelSim standalone, close it before running from Quartus again.

## Optional: script change so it doesn’t delete the library

If you prefer not to delete `rtl_work` every time (avoids lock if something else has it open), you can comment out the `vdel` in the .do file so the script only creates the library if it’s missing. I can give the exact edit if you want.
