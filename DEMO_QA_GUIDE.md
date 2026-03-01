# CPU Phase 1 Demo – Q&A Guide

Use this guide to answer TA questions during the demo. It is aligned with the **Demo/Marking Guidelines** PDF and your actual code.

---

## 1. Demo format (what to expect)

- **Duration:** ~20–25 minutes per group.
- **Live demo:** TAs will ask for **4–5 instructions** from Sections 3.1–3.13, typically including:
  - **MUL** (Booth algorithm / bit-pair recoding or Carry-Save Adders),
  - **Adder/Subtractor**,
  - **Divider**,
  - Plus a few others (e.g. AND, OR, shift/rotate, neg, not).
- **Waveforms:** Have waveforms ready (saved or quick to regenerate) to speed up the demo. Use the **required** signals below.
- **Be clear:** Say what works, what does not, and any bonus or differences from the handout.

---

## 2. Required signals in waveforms (handout page 7)

**Control signals to show (if asked):**  
R0in–R15in, R0out–R15out; HIin, HIout; LOin, LOout; PCin, PCout; IRin; Zin; Zhighout, Zlowout; Yin; MARin; MDRin, MDRout; Read; Mdatain[31..0].

**Outputs (minimum for demo):**  
R0–R15, HI, LO, IR, **BusMuxOut**, **Z** (and any others you want).

Your `Datapath_top` exposes BusMuxOut, Z, IR, PC, HI, LO, R0–R15. Add these to the wave window; set radix to **Hexadecimal** for buses.

---

## 3. How to answer “How did you design …?”

### 3.1 Bus

- **Implementation:** 32:1 multiplexer driven by a **5-bit select (BusSel)**.
- **Encoding:** In `datapath_top.v`, the **Rout[15:0]** and special outs (PCout, MDRout, HIout, LOout, Zhighout, Zlowout) are encoded into **BusSel** with a **priority encoder** (if/else if). Only one source should be active at a time.
- **Mapping:** BusSel 0–15 = R0–R15; 16 = HI; 17 = LO; 18 = Zhigh; 19 = Zlow; 20 = PC; 21 = MDR; 22 = InPort; 23 = C sign-extended (reserved for Phase 2).
- **Single transaction:** The bus carries one value at a time; the mux in `datapath.v` selects that one source onto **BusMuxOut**.

### 3.2 Registers (R0–R15, PC, IR, Y, MAR, HI, LO)

- **Module:** One parameterized **register** module (`general_purpose_register.v`), used for all of these (same design as in the handout).
- **Behavior:** Synchronous; on **posedge Clock**, if **enable** is high, register loads **BusMuxOut**. **Clear** resets to zero. Output is always the stored value (no tri-state; bus selection is done by the mux).
- **GPRs:** Generated with a **generate** loop: 16 instances, each with **Rin[i]** as enable. R0–R15 are the outputs of these registers.

### 3.3 MDR

- **Two inputs:** (1) **BusMuxOut** (internal bus), (2) **Mdatain** (from memory).
- **Selection:** When **Read = 1**, MDR loads **Mdatain**; when **Read = 0**, MDR loads **BusMuxOut**. So MDR has an internal 2:1 mux (MDMux) in front of the register.
- **Output:** Single 32-bit output drives **BusMuxIn-MDR** (wired into the bus mux in the datapath). So MDR has two input sources, one output to the bus (and later to memory in Phase 2).
- **Code:** In `mdr.v`, `MDMuxOut = Read ? Mdatain : BusMuxOut`; on posedge Clock, if **MDRin**, register stores MDMuxOut.

### 3.4 Y, Z, and ALU data path

- **Y:** Holds the first ALU operand (e.g. R5 for “and R2, R5, R6”). **A** of the ALU = Y; **B** = BusMuxOut (second operand from bus).
- **Z:** 64-bit register. **Input:** When **IncPC = 1**, Z gets **PC+1** (via **inc32**); otherwise Z gets the **ALU result** (logic_out). So there is a mux between IncPC path and ALU path into Z.
- **Z outputs:** Zlow = Z[31:0], Zhigh = Z[63:32]. Used for PC update (Zlowout → PCin), for MUL (Zlow→LO, Zhigh→HI), and for DIV (Zlow→LO quotient, Zhigh→HI remainder).

### 3.5 Adder / Subtractor

- **No `+`/`-` in the adder:** The 32-bit adder is built from **full adders** using only gates: **S = A xor B xor Cin**, **Cout** = majority (and/or) of A, B, Cin. Implemented in **adder32.v** (ripple carry).
- **Subtraction:** **addsub32.v**: A − B = A + (~B) + 1. So **Bx = B xor {32{Sub}}** (when Sub=1, Bx = ~B), and **Cin = Sub**. Same adder does add and sub; no `+`/`-` in this block.
- **CLA:** You did **not** use a Carry-Lookahead Adder; you used a **ripple-carry** adder. If the TA asks “did you use CLA?” say “No, we used a ripple-carry adder with full adders.”

### 3.6 Multiplier (MUL)

- **Algorithm:** **32×32 Booth’s algorithm with bit-pair recoding** (radix-4). No simple `*` operator; you designed the multiplier as required.
- **Implementation:** **mult32x32_booth.v**. Multiplier B is extended with an extra bit for Booth encoding: **extB = {B[31], B, 1'b0}**. There are **16 radix-4 groups**. For each group, the 3-bit Booth code **{extB[2i+2], extB[2i+1], extB[2i]}** selects: 0, +A, +2A, −A, −2A. Partial products are shifted by **2*i** and accumulated. Result is 64-bit product **P**; in **alu_core**, when MUL is asserted, **result = mul_out** (full 64 bits into Z).
- **Combinational:** The multiplier is **combinational** (always @(*) with a for-loop); no extra “wait” cycles are needed for completion. One cycle of MUL, Zin is enough; next cycle Zlowout→LOin, Zhighout→HIin.
- **If asked “Carry-Save Adders?”:** “We used Booth with bit-pair recoding and a single accumulator for partial products. We did not use a separate Carry-Save Adder tree for summands.”

### 3.7 Divider (DIV)

- **Algorithm:** **Non-restoring division** (as in the lab and lectures).
- **Implementation:** **div32_nonrestoring.v**. 32 iterations. Each step: shift **{rem, quot}** left by 1; if current remainder ≥ 0, subtract divisor, else add divisor; set quotient bit from sign of new remainder. Final step: if remainder is negative, restore (add divisor once). **result = {remainder[31:0], quotient[31:0]}**, i.e. **Z = {Zhigh, Zlow} = {remainder, quotient}**.
- **Loading HI/LO:** **T5: Zlowout, LOin** → quotient into LO. **T6: Zhighout, HIin** → remainder into HI. So **LO = quotient**, **HI = remainder**, matching the CPU spec.
- **Divide by zero:** In your code, if divisor == 0, you output **result = {dividend, 32'hFFFF_FFFF}** (remainder = dividend, quotient = all 1s). You can state that briefly if the TA asks.

### 3.8 Other ALU ops (AND, OR, NOT, NEG, shifts, rotates)

- **AND, OR, NOT:** Done with Verilog **&**, **|**, **~** (basic logic operators are allowed per handout). NOT is applied to **B**; result is 64’b0 concatenated with the 32-bit result.
- **NEG:** Two’s complement of **B**: **neg_b = (~B) + 1**. The “+1” is done with **inc32** (no `+` in the ALU core), which is a dedicated incrementer built from gates (like your adder bit logic).
- **Shifts:** SHR = logical right (**A >> shamt**); SHRA = arithmetic right (**$signed(A) >>> shamt**); SHL = **A << shamt**. Shift amount **shamt = B[4:0]** (5 bits, 0–31).
- **Rotates:** Implemented with **{A, A}** (64 bits), then shift; take the appropriate 32-bit slice (e.g. **rol_a = (AA << shamt)[63:32]**, **ror_a = (AA >> shamt)[31:0]**) so that no “32 − shamt” is needed in a way that would require a run-time subtract in the datapath for the rotate unit itself.

---

## 4. Control sequences and timing (what happens each cycle)

Use these when the TA checks “register transfers in each clock cycle” and “correctness of control sequence.”

### 4.1 Fetch (T0–T2) – same for all instructions

| Step | Control sequence | What happens |
|------|------------------|--------------|
| T0   | PCout, MARin, IncPC, Zin | PC → bus → MAR; ALU computes PC+1 → Z |
| T1   | Zlowout, PCin, Read, Mdatain[31..0], MDRin | Zlow → bus → PC; memory data (Mdatain) → MDR |
| T2   | MDRout, IRin | MDR → bus → IR (instruction loaded) |

### 4.2 AND (and R2, R5, R6) – Section 3.1

| Step | Control sequence | What happens |
|------|------------------|--------------|
| T3   | R5out, Yin | R5 → bus → Y |
| T4   | R6out, AND, Zin | R6 on bus; ALU: Y & B → Z |
| T5   | Zlowout, R2in | Zlow → bus → R2 |

**Show:** R5=0x34, R6=0x45 ⇒ R2 = 0x04 (0x34 & 0x45).

### 4.3 ADD / SUB (add R2, R5, R6 / sub R2, R5, R6)

Same as AND; T4 uses **ADD** or **SUB**. T5: Zlowout, R2in.  
**ADD:** R2 = R5 + R6 (e.g. 0x34 + 0x45 = 0x79).  
**SUB:** R2 = R5 − R6 (e.g. 0x34 − 0x45 = 0xFFFFFFEF in 32-bit two’s complement).

### 4.4 MUL (mul R3, R1)

| Step | Control sequence | What happens |
|------|------------------|--------------|
| T3   | R3out, Yin | R3 (first operand) → Y |
| T4   | R1out, MUL, Zin | R1 on bus; ALU: Y × B → Z (64-bit product) |
| T5   | Zlowout, LOin | Z[31:0] → LO |
| T6   | Zhighout, HIin | Z[63:32] → HI |

**Show:** e.g. R3=100, R1=7 ⇒ LO=700, HI=0.

### 4.5 DIV (div R3, R1)

Same as MUL except T4 uses **DIV**. Z = {remainder, quotient}.  
**T5:** Zlowout, LOin → **quotient** → LO.  
**T6:** Zhighout, HIin → **remainder** → HI.  
**Show:** e.g. 100 ÷ 7 ⇒ LO=14, HI=2.

### 4.6 SHR / SHRA / SHL (e.g. shr R7, R0, R4)

| Step | Control sequence | What happens |
|------|------------------|--------------|
| T3   | R0out, Yin | Value to shift → Y |
| T4   | R4out, SHR (or SHRA/SHL), Zin | Shift amount on bus (B[4:0]); ALU shifts Y by shamt → Z |
| T5   | Zlowout, R7in | Zlow → R7 |

### 4.7 ROR / ROL (ror R7, R0, R4 / rol R7, R0, R4)

Same as SHR; T4 uses **ROR** or **ROL**. R4 supplies shift/rotate count.

### 4.8 NEG (neg R4, R7)

| Step | Control sequence | What happens |
|------|------------------|--------------|
| T3   | R7out, NEG, Zin | R7 on bus; ALU: −B (two’s complement) → Z |
| T4   | Zlowout, R4in | Zlow → R4 |

**Show:** e.g. R7 = 0xFFFFFFFB (−5) ⇒ R4 = 0x00000005 (5).

### 4.9 NOT (not R4, R7)

Same as NEG; T3 uses **NOT**. R4 = bitwise NOT(R7).

---

## 5. Opcode consistency (CPU specification)

TAs may check that **Mdatain** (instruction word) matches your CPU spec for each instruction. Your testbenches use patterns like:

- AND: **0x112B0000** (and R2, R5, R6)  
- ADD: **0x112D0000** (add R2, R5, R6)  
- MUL: **0x11980000** (mul R3, R1)  
- DIV: **0x119C0000** (div R3, R1)  

If your course has a **CPU Specification** or **Lab Reader** with exact opcode tables, say: “Our Mdatain values follow the Mini SRC opcode encoding from the spec.” If the TA gives a different format, you can note that in Phase 1 you are only simulating the datapath and the exact opcode bits are used only to load IR; decoding is in Phase 3.

---

## 6. Design choices to state clearly

- **Bus:** 32:1 mux + priority encoder from Rout and special outs → BusSel; only one driver at a time.
- **Registers:** Single parameterized register (sync, enable, clear); GPRs in a generate loop.
- **MDR:** Two inputs (bus vs Mdatain) selected by Read; one output to bus.
- **Adder/Sub:** Ripple-carry full adders; no `+`/`-` in adder/subtractor; NEG uses inc32 (no `+` in ALU).
- **Multiplier:** Booth with bit-pair recoding (radix-4), 16 groups, combinational; product in Z then LO/HI.
- **Divider:** Non-restoring division; Z = {remainder, quotient}; LO = quotient, HI = remainder.
- **Shifts/rotates:** Shift amount from B[4:0]; rotate via {A,A} and shift then slice.

---

## 7. Quick checklist before demo

- [ ] All 13 instructions (3.1–3.13) run in simulation; know which testbench (e.g. datapath_tb, tb_add, tb_mul, …) for each.
- [ ] Waveforms include at least: R0–R15, HI, LO, IR, BusMuxOut, Z (and control signals if required).
- [ ] You can walk through T0–T2 (fetch) and the execute steps for AND, ADD, MUL, DIV, and one shift/neg/not.
- [ ] You can explain in 1–2 sentences: bus (mux + encoder), registers (parameterized, sync), MDR (two inputs, Read select), adder (ripple, no +/−), multiplier (Booth bit-pair), divider (non-restoring, HI=rem, LO=quot).
- [ ] Report submitted by deadline (PDF, after demo); includes code, testbenches (or one + differences), and simulation runs for 3.1–3.13.

Use this guide alongside **LAB_DEMO_INSTRUCTIONS.md** for the step-by-step run and **SIMULATION_README.md** for simulation details.
