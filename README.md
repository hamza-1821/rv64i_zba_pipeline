# RV64I + Zba 5-Stage Pipeline Processor

## Quick Setup

Simply navigate to the project directory and run make commands directly. All paths are relative and automatically handled by the Makefile.

```bash
cd rv64i_zba_core
make test
```

## Overview

A 5-stage pipeline RISC-V processor core supporting RV64I base instruction set and Zba bit manipulation extensions.


## Supported Instructions

### RV64I Base Set
- Arithmetic: ADD, SUB, ADDI, ADDW, SUBW
- Logical: AND, OR, XOR, ANDI, ORI, XORI
- Shifts: SLL, SRL, SRA, SLLI, SRLI, SRAI
- Comparisons: SLT, SLTU, SLTI, SLTIU
- Branches: BEQ, BNE, BLT, BGE, BLTU, BGEU
- Memory: LW, LD, SW, SD
- Other: LUI, AUIPC, JAL, JALR

### Zba Extension
- SH1ADD, SH2ADD, SH3ADD

## Quick Start

### Build
```
make all
```

### Run Tests
```
make test
```

### View Results
```
make test-results
```

### Clean
```
make clean
```

## Available Make Targets

- `make all` - Compile test program and testbench
- `make compile` - Compile test program only
- `make sim` - Run simulation only
- `make test` - Full test (compile + simulate + display results)
- `make test-results` - Show last test results from log
- `make disasm` - Generate assembly disassembly
- `make help` - Show all available targets
- `make clean` - Remove build artifacts and logs

## Project Structure

```
.
├── sw/              - Software (test program)
├── rtl/             - Hardware (Verilog/SystemVerilog)
├── tb/              - Testbench
├── build/           - Compiled output
├── hw_sim/          - Simulation output
├── logs/            - Test result logs
└── docs/            - Technical documentation
```

## Testing

The test program verifies:
- Arithmetic operations (ADD, SUB)
- Logical operations (AND, OR, XOR)
- Shift operations (SLL, SRL)
- Memory load/store
- Branch conditions
- Zba instructions (SH2ADD, SH3ADD)

Results are logged to `logs/test_results.log`.

## Test Parameters

Modify test parameters in `sw/test.c`:
- `a = 10` (left operand)
- `b = 20` (right operand)

The testbench automatically computes expected values based on these parameters.

## Notes

- Pipeline: Instruction Fetch → Decode → Execute → Memory → Write Back
- Data forwarding: Prevents stalls from load-use dependencies
- Memory: 4K doublewords instruction memory, 32K doublewords data memory
- Simulation: 100 MHz clock, up to 100k cycle timeout
