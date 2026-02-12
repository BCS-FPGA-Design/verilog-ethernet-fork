# Runner script for the adder cocotb example.
# Usage: python run.py [--sim SIM] [--top TOP] [--lang LANG] [--clean] [--gtkwave]
#
# Arguments:
#   --sim      Simulator name (default: "questa")
#   --top      Top-level module name (default: "adder")
#   --lang     Top-level language: "verilog" or "vhdl" (default: "verilog")
#   --clean    Remove build artifacts and exit
#   --gtkwave  Open waveform in GTKWave after simulation
from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

from cocotb_tools.runner import get_runner


def main():
    parser = argparse.ArgumentParser(description="Run the adder cocotb example")
    parser.add_argument(
        "--sim", default=os.getenv("SIM", "questa"), help="Simulator name (default: questa)"
    )
    parser.add_argument(
        "--top", default="adder", help="Top-level module name (default: adder)"
    )
    parser.add_argument(
        "--lang", default=os.getenv("HDL_TOPLEVEL_LANG", "verilog"),
        choices=["verilog", "vhdl"], help="Top-level language (default: verilog)"
    )
    parser.add_argument(
        "--clean", action="store_true", help="Remove build artifacts and exit"
    )
    parser.add_argument(
        "--gtkwave", action="store_true", help="Open waveform in GTKWave after simulation"
    )
    args = parser.parse_args()

    sim = args.sim
    toplevel = args.top
    toplevel_lang = args.lang

    # Ensure QuestaSim is on PATH (Libero SoC bundled install)
    if sim == "questa":
        questasim_bin = os.getenv(
            "QUESTASIM_BIN_DIR",
            r"C:\Microchip\Libero_SoC_v2024.2\QuestaSim\win64",
        )
        if questasim_bin not in os.environ.get("PATH", ""):
            os.environ["PATH"] = questasim_bin + os.pathsep + os.environ.get("PATH", "")

    proj_path = Path(__file__).resolve().parent.parent
    repo_root = Path(__file__).resolve().parents[3]

    hdl_dir   = repo_root / "rtl"
    axis_dir  = repo_root / "lib" / "axis" / "rtl"
    model_dir = proj_path / "models"
    tests_dir = proj_path / "tests"
    build_dir = tests_dir / "sim_build"
    

    if args.clean:
        removed = []
        for d in [build_dir, tests_dir / "__pycache__", model_dir / "__pycache__"]:
            if d.exists():
                shutil.rmtree(d)
                removed.append(str(d))
        print(f"Removed {', '.join(removed)}" if removed else "Nothing to clean.")
        return

    # Add model/ and tests/ to Python path so cocotb can import them
    sys.path.append(str(model_dir))
    sys.path.append(str(tests_dir))

    
    hdl_exts = {".v", ".sv", ".svh", ".vh", ".vhdl", ".vhd"}
    sources = sorted(
        [f for f in hdl_dir.iterdir() if f.suffix in hdl_exts]
        + [f for f in axis_dir.iterdir() if f.suffix in hdl_exts]
    )

    build_test_args = []

    # Enable VCD dumping when GTKWave is requested
    extra_env = {}
    if args.gtkwave:
        extra_env["COCOTB_RESULTS_FILE"] = ""
        os.environ["WAVES"] = "1"

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=toplevel,
        always=True,
        build_args=build_test_args,
        build_dir=build_dir,
    )
    runner.test(
        hdl_toplevel=toplevel,
        hdl_toplevel_lang=toplevel_lang,
        test_module="test_udp_complete",
        test_args=build_test_args,
        waves=args.gtkwave,
        build_dir=build_dir,
    )

    # Launch GTKWave if requested
    if args.gtkwave:
        gtkwave = os.getenv("GTKWAVE", r"C:\msys64\mingw64\bin\gtkwave.exe")
        vcd = build_dir / "dump.vcd"
        wlf = build_dir / "vsim.wlf"

        # Convert WLF → VCD (GTKWave can't read WLF directly)
        # Always re-convert so the VCD reflects the latest run
        if wlf.exists():
            if vcd.exists():
                vcd.unlink()
            print(f"Converting {wlf.name} → {vcd.name}...")
            subprocess.run(["wlf2vcd", str(wlf), "-o", str(vcd)], check=True)

        if vcd.exists():
            print(f"Opening {vcd} in GTKWave...")
            subprocess.Popen([gtkwave, str(vcd)])
        else:
            print("No waveform file found in sim_build/.")


if __name__ == "__main__":
    main()
