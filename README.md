# SystemVerilog FPGA Project

This is a SystemVerilog project using Icarus Verilog for simulation and testing.

## Prerequisites

- Icarus Verilog (iverilog)
- GTKWave (for waveform viewing)
- Make

## Project Structure

```
.
├── rtl/           # RTL design files
├── tb/            # Testbench files
├── sim/           # Simulation outputs
└── Makefile       # Build and simulation commands
```

## Building and Running

To build and run the testbench:
```bash
make
```

To clean build artifacts:
```bash
make clean
```

To view waveforms:
```bash
make wave
```

## Adding New Modules

1. Create your module in the `rtl/` directory
2. Create a corresponding testbench in the `tb/` directory
3. Update the Makefile if needed 