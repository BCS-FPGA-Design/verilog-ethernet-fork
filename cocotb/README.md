# Cocotb Adder Example — Setup from Scratch

A minimal cocotb testbench that verifies a 4-bit adder using QuestaSim (bundled with Libero SoC).
Uses the **cocotb Python runner** — no Makefile or GNU Make required.

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| **Windows 10/11** | 64-bit | Native Windows — not WSL or MSYS2 |
| **Libero SoC** | 2024.2 | Includes QuestaSim Pro (`C:\Microchip\Libero_SoC_v2024.2`) |
| **Python** | 3.11 – 3.13 | Windows-native CPython (not Anaconda/MSYS2) |
| **GTKWave** *(optional)* | any | For viewing VCD waveforms |

## 1. Install Python

Download from <https://www.python.org/downloads/> and install.
Ensure **"Add python to PATH"** is checked during installation.

Verify:

```powershell
python --version
# Python 3.13.x
```

## 2. Install cocotb

```powershell
pip install cocotb
```

Verify:

```powershell
cocotb-config --version
# 2.x.x
```

## 3. Add QuestaSim to PATH

QuestaSim ships with Libero SoC. The runner script (`run.py`) automatically adds the default Libero QuestaSim path to `PATH`:

```
C:\Microchip\Libero_SoC_v2024.2\QuestaSim\win64
```

If your install is elsewhere, set `QUESTASIM_BIN_DIR`:

```powershell
$env:QUESTASIM_BIN_DIR = "D:\Microchip\Libero_SoC_v2024.2\QuestaSim\win64"
```

## 4. Install GTKWave (optional)

For waveform viewing:

```powershell
# via MSYS2
pacman -S mingw-w64-x86_64-gtkwave

# or download from https://gtkwave.sourceforge.net/
```

## 5. Project Structure

```
adder/
├── hdl/
│   ├── adder.sv          # SystemVerilog DUT
│   └── adder.vhdl        # VHDL DUT (alternative)
├── model/
│   └── adder_model.py    # Python reference model
├── tests/
│   ├── run.py            # Python runner (compile + simulate)
│   └── test_adder.py     # cocotb tests
└── README.md
```

## 6. Run the Tests

The runner is a standalone script (`run.py`) using `cocotb_tools.runner`. No Makefile needed.

```powershell
cd cocotb/examples/adder/tests
python run.py
```

### Command-line arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `--sim SIM` | `questa` | Simulator name (e.g. `questa`, `icarus`, `verilator`) |
| `--top TOP` | `adder` | Top-level module name |
| `--lang LANG` | `verilog` | Top-level language: `verilog` or `vhdl` |
| `--gtkwave` | — | Dump waveforms, convert WLF → VCD, and open GTKWave |
| `--clean` | — | Remove build artifacts (`sim_build/`, `__pycache__/`) and exit |

### Examples

```powershell
# Run with defaults (QuestaSim, top-level = adder, verilog)
python run.py

# Specify a different top-level module
python run.py --top my_module

# Use VHDL as the top-level language
python run.py --lang vhdl

# Run and open waveforms in GTKWave
python run.py --gtkwave

# Use Icarus Verilog instead of QuestaSim
python run.py --sim icarus

# Clean build artifacts
python run.py --clean
```

### How the runner works

`run.py` is a standalone script that:

1. Parses CLI arguments (falls back to `SIM` / `HDL_TOPLEVEL_LANG` env vars)
2. Adds QuestaSim to `PATH` automatically when `--sim questa`
3. Collects all HDL source files (`.v`, `.sv`, `.svh`, `.vh`, `.vhdl`, `.vhd`) from `hdl/`
4. Adds the `model/` and `tests/` directories to `sys.path` so cocotb can import them
5. Calls `runner.build()` to compile all sources into `tests/sim_build/`
6. Calls `runner.test()` with `--top` as the top-level module and `--lang` as the top-level language
7. If `--gtkwave`: converts `vsim.wlf` → `dump.vcd` via `wlf2vcd`, then opens GTKWave

## 7. Expected Output

```
     0.00ns INFO     cocotb.regression     running adder_basic_test (1/2)
     2.00ns INFO     cocotb.regression     adder_basic_test passed
     2.00ns INFO     cocotb.regression     running adder_randomised_test (2/2)
    22.00ns INFO     cocotb.regression     adder_randomised_test passed
    22.00ns INFO     cocotb.regression     ************************************
                                           ** TESTS=2 PASS=2 FAIL=0 SKIP=0  **
                                           ************************************
```

## 8. How It Works

1. **DUT** (`adder.sv`): A parameterized adder with two `DATA_WIDTH`-bit unsigned inputs (`A`, `B`) and a `DATA_WIDTH+1`-bit output (`X = A + B`).

2. **Model** (`adder_model.py`): A trivial Python function `adder_model(a, b) -> int` that returns `a + b`, used as the golden reference.

3. **Tests** (`test_adder.py`):
   - `adder_basic_test`: Drives `A=5, B=10`, waits 2 ns, asserts `X == 15`.
   - `adder_randomised_test`: Runs 10 iterations with random 4-bit inputs, checking each result against the model.

4. **Runner** (`run.py`): Uses `cocotb_tools.runner.get_runner()` to compile HDL and launch the simulator — a pure-Python alternative to Makefiles.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `vlog: command not found` | Set `QUESTASIM_BIN_DIR` env var or add QuestaSim to PATH (step 3) |
| `ModuleNotFoundError: cocotb` | Run `pip install cocotb` with the same Python that's on PATH |
| `ERROR: This script must be run with Windows Python` | Use native Windows Python, not MSYS2's `/usr/bin/python` |
| `No module named 'adder_model'` | `run.py` adds `model/` to `sys.path` automatically — works from any CWD |
| `No waveform file found` | Run with `--gtkwave` to enable waveform dumping |
| GTKWave says "No symbols / malformed" | Ensure `wlf2vcd` conversion ran — the runner does this automatically with `--gtkwave` |
| `No module named 'cocotb_tools'` | Upgrade cocotb: `pip install --upgrade cocotb` (runner requires cocotb 2.x) |
