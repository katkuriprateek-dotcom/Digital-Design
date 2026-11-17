# 4x4 Systolic Array Matrix Multiplier

*A Verilog implementation of a signed 4x4 matrix multiplier for a Spartan‑7 FPGA.*

---

## Table of Contents

- [Project Overview](#project-overview)
- [Target Hardware &amp; Tools](#target-hardware--tools)
- [Repository Structure](#repository-structure)
- [HDL Modules &amp; Project Files](#hdl-modules--project-files)
- [Vivado Setup &amp; FPGA Implementation](#vivado-setup--fpga-implementation)
- [Running the Design](#running-the-design)
- [Serial Helper (Python)](#serial-helper-python)
- [Simulation Guide](#simulation-guide)
- [Images](#images)
- [End‑to‑End Workflow](#end‑to‑end-workflow)

---

## Project Overview

The design computes **C = A × B** where each input matrix consists of 16 signed 8‑bit elements. The datapath is a 4×4 array of processing elements (PEs) that perform signed‑8‑bit multiplication and 32‑bit accumulate (MAC) operations.

```
C[row][column] = sum(A[row][k] * B[k][column]) for k = 0..3
```

- `sys_array_4x4` instantiates one PE per matrix coordinate.
- Matrix A values flow **horizontally**, matrix B values flow **vertically** through registered signals.
- Each PE multiplies its inputs and accumulates the result in a 32‑bit register.
- A `matrix_skew_controller` captures the packed 128‑bit matrices, generates skewed rows/columns, and sequences the controller FSM (`IDLE → CLEAR → RUN → DONE`).
- `result_storage` collects the 512‑bit result and asserts `result_valid`.
- The top level connects a Vivado Virtual I/O (VIO) IP for laptop‑side interaction.

> **Note:** The supplied `matrix_sender.py` is a stand‑alone Serial helper and is **not** connected to the RTL.

---

## Target Hardware & Tools

| Parameter                     | Specification                       |
| ----------------------------- | ----------------------------------- |
| **EDA tool**            | AMD Xilinx Vivado 2025              |
| **FPGA family**         | Spartan‑7                          |
| **FPGA device**         | XC7S15                              |
| **Package**             | FTGB196ABX2409                      |
| **Board marking**       | D4ASM701A                           |
| **Constraint target**   | `xc7s15ftgb196-1`                 |
| **Clock constraint**    | 50 MHz (20 ns period)             |
| **Reset**               | Active‑high, pin J13               |
| **Result presentation** | Laptop via Vivado VIO / Tcl Console |

---

## Repository Structure

```
.
├── bitstream/                # Pre‑built .bit file
├── constraints/              # XDC constraints
├── docs/                     # Images and documentation
│   ├── fpga_board_setup.jpg
│   ├── input_matrices.jpg
│   └── simulation_result_matrix.jpg
├── ip/                       # Vivado IP sources
│   └── vio_matrix/           # VIO IP core
├── rtl/                      # Verilog source files
│   ├── PE.v
│   ├── matrix_skew_controller.v
│   ├── result_storage.v
│   ├── sys_array_4x4.v
│   └── top_fpga.v
├── sim/                      # Testbench
│   └── top_fpga_vio_tb.v
├── matrix_sender.py          # Python Serial helper
└── tcl_command.txt          # Vivado TCL script for VIO readout
```

---

## HDL Modules & Project Files

| File                             | Purpose                                                                                                                               |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `rtl/PE.v`                     | Signed 8‑bit multiplication, 32‑bit accumulation, and registered operand forwarding in one PE.                                      |
| `rtl/sys_array_4x4.v`          | Generates the 4×4 PE grid and wires A horizontally and B vertically.                                                                 |
| `rtl/matrix_skew_controller.v` | Captures matrices, detects `start`, generates skewed inputs, and controls the FSM (`IDLE/CLEAR/RUN/DONE`).                        |
| `rtl/result_storage.v`         | Captures the 512‑bit output and drives `result_valid`.                                                                             |
| `rtl/top_fpga.v`               | Connects `vio_matrix`, the controller, and result storage.                                                                          |
| `ip/vio_matrix/vio_matrix.xci` | Vivado configuration for the VIO IP used by `top_fpga`.                                                                             |
| `sim/top_fpga_vio_tb.v`        | Testbench that reads `matrix_input.mem`, drives VIO probes, waits for completion, prints results, and writes `matrix_output.mem`. |
| `constraints/top_fpga.xdc`     | Pin assignments and 50 MHz clock constraint.                                                                                         |
| `bitstream/top_fpga.bit`       | Pre‑built bitstream (build provenance not recorded).                                                                                 |

---

## Vivado Setup & FPGA Implementation

### 1. Create a Vivado Project

1. Launch **Vivado 2025** → **Create Project**.
2. Choose a project name and directory *outside* the repository (or use the repository root).
3. Select **RTL Project** and add the sources listed below.
4. In **Default Part**, search for `xc7s15ftgb196-1` and select it.
5. Finish.

### 2. Add Sources & IP

1. **Add Sources** → **Add or create design sources** → add `rtl/*.v` files.
2. **Add IP** → select `ip/vio_matrix/vio_matrix.xci` and generate its output products.
3. **Add Constraints** → `constraints/top_fpga.xdc`.
4. Set `top_fpga` as the top module.
5. Run **Validate Design** to resolve any errors.

### 3. Simulation (Behavioral)

1. Add `sim/top_fpga_vio_tb.v` as a simulation source and set it as the simulation top.
2. Create `matrix_input.mem` in the simulation working directory containing two 128‑bit hexadecimal words (example shown in the README).
3. Run **Run Behavioral Simulation** until the testbench finishes.
4. Observe the waveform signals (`clk`, `rst`, `probe_*`, etc.) and the printed result matrix.

### 4. Synthesis, Implementation & Bitstream

1. Ensure `top_fpga` is the active top design.
2. **Run Synthesis** → **Run Implementation** → **Generate Bitstream**.
3. The generated `.bit` file appears in the Vivado run directory (e.g., `project_name.runs/impl_1/`).
4. You may also use the provided `bitstream/top_fpga.bit`.

### 5. Program the Board & Use VIO

1. Connect the Spartan‑7 board and open **Hardware Manager**.
2. **Auto Connect**, then **Program Device** with the generated bitstream.
3. Open the VIO dashboard (`vio_matrix`).
4. Set `probe_out0` and `probe_out1` to the packed 128‑bit matrix values, set `probe_out2` low, then pulse it high to start multiplication.
5. Watch `probe_in3` (`busy`) and wait for `probe_in2` (`result_valid`).
6. In the **Tcl Console**, run:
   ```tcl
   source tcl_command.txt
   ```

   The script refreshes VIO values and prints the 4×4 result.

---

## Serial Helper (Python)

`matrix_sender.py` is a stand‑alone utility that sends the two 4×4 matrices over a serial port (default `COM3`, 9600 baud). It **does not** interface with the RTL design.

```bash
python matrix_sender.py
```

Install the dependency with:

```bash
pip install pyserial
```

---

## Simulation Guide

The testbench expects `matrix_input.mem` in the simulator’s working directory. Each line contains a 128‑bit word (32 hex digits) representing a matrix in row‑major order, least‑significant byte first.

Example content for matrices containing values 1‑16:

```
100f0e0d0c0b0a090807060504030201
100f0e0d0c0b0a090807060504030201
```

Run simulation as described in the **Vivado Setup** section.

---

## Images

![Spartan‑7 development board setup](docs/fpga_board_setup.jpg)

![Input matrix example](docs/input_matrices.jpg)

![Laptop‑side Vivado matrix result](docs/simulation_result_matrix.jpg)

---

## End‑to‑End Workflow

```text
Vivado laptop VIO dashboard
    → 128‑bit Matrix A and Matrix B probes
    → top_fpga / matrix_skew_controller
    → skewed row and column data
    → sys_array_4x4 (16 processing elements)
    → signed multiply‑and‑accumulate operations
    → result_storage (512‑bit result and result_valid)
    → VIO result probes
    → Vivado Tcl Console on the laptop
```
