# Makefile for RV64I + Zba Processor
# 
# Targets:
#   make compile    - Compile test.c to machine code
#   make sim        - Run simulation
#   make all        - Compile and simulate (default)
#   make clean      - Remove build artifacts
#   make disasm     - Show disassembly
#   make help       - Show this help message

# ============================================================================
# VARIABLES
# ============================================================================

PROJECT_ROOT := $(PWD)
BUILD_DIR := $(PROJECT_ROOT)/build
SIM_DIR := $(PROJECT_ROOT)/hw_sim
RTL_DIR := $(PROJECT_ROOT)/rtl
TB_DIR := $(PROJECT_ROOT)/tb
SW_DIR := $(PROJECT_ROOT)/sw
LOG_DIR := $(PROJECT_ROOT)/logs
RESULTS_LOG := $(LOG_DIR)/test_results.log

# Toolchain
RISCV_PREFIX := riscv64-unknown-elf-
CC := $(RISCV_PREFIX)gcc
OBJDUMP := $(RISCV_PREFIX)objdump
OBJCOPY := $(RISCV_PREFIX)objcopy

# Compilation flags
MARCH := rv64i_zba
MABI := lp64
CFLAGS := -march=$(MARCH) -mabi=$(MABI) -O2 -nostdlib -fno-builtin
CFLAGS += -ffunction-sections -fdata-sections

# Simulator
SIM := iverilog
SIMFLAGS := -g2009

# ============================================================================
# FILES
# ============================================================================

C_SRC := $(SW_DIR)/test.c
S_FILE := $(BUILD_DIR)/test.s
O_FILE := $(BUILD_DIR)/test.o
ELF_FILE := $(BUILD_DIR)/test.elf
BIN_FILE := $(BUILD_DIR)/test.bin
DIS_FILE := $(BUILD_DIR)/test_disasm.txt
HEX_FILE := $(BUILD_DIR)/instr_mem.hex

RTL_FILES := $(RTL_DIR)/rv64_core.sv \
            $(RTL_DIR)/regfile.sv \
            $(RTL_DIR)/alu.sv \
            $(RTL_DIR)/imm_gen.sv \
            $(RTL_DIR)/control_unit.sv \
            $(RTL_DIR)/alu_control.sv \
            $(RTL_DIR)/forwarding_unit.sv \
            $(RTL_DIR)/hazard_unit.sv \
            $(RTL_DIR)/data_mem.sv \
            $(RTL_DIR)/instr_mem.sv

TB_FILE := $(TB_DIR)/tb_processor.sv

SIM_EXEC := $(SIM_DIR)/tb_processor.vvp

# ============================================================================
# TARGETS
# ============================================================================

.PHONY: all compile sim test clean disasm help prepare info show-hex show-elf show-sections

all: compile sim

test: compile sim test-results

test-results:
	@echo ""
	@echo "================================================================================";
	@echo "TEST RESULTS"
	@echo "================================================================================"
	@if [ -f "$(SIM_DIR)/simulation.log" ]; then \
		echo "✓ PASSING TESTS:"; \
		grep "✓ PASS" "$(SIM_DIR)/simulation.log" | sed 's/^/  /'; \
		echo ""; \
		echo "✗ FAILING TESTS:"; \
		grep "✗ FAIL" "$(SIM_DIR)/simulation.log" | sed 's/^/  /'; \
		echo ""; \
		PASS_COUNT=$$(grep -c "✓ PASS" "$(SIM_DIR)/simulation.log"); \
		FAIL_COUNT=$$(grep -c "✗ FAIL" "$(SIM_DIR)/simulation.log"); \
		TOTAL=$$((PASS_COUNT + FAIL_COUNT)); \
		echo "Summary: $$PASS_COUNT/$$TOTAL tests passing"; \
		echo "================================================================================"; \
	else \
		echo "No simulation log found"; \
	fi

# ============================================================================
# COMPILATION TARGET
# ============================================================================

compile: $(HEX_FILE) $(DIS_FILE) prepare
	@echo ""
	@echo "✓ Compilation successful"
	@echo "  Output: $(HEX_FILE)"
	@echo "  Size: $$(stat -c%s $(HEX_FILE) 2>/dev/null || stat -f%z $(HEX_FILE)) bytes"

# Assembly from C
$(S_FILE): $(C_SRC) | $(BUILD_DIR)
	@echo "Compiling C to assembly..."
	$(CC) $(CFLAGS) -S -o $@ $<
	@echo "✓ Assembly: $@"

# Object file from assembly
$(O_FILE): $(S_FILE)
	@echo "Assembling to object file..."
	$(CC) $(CFLAGS) -c -o $@ $<
	@echo "✓ Object: $@"

# ELF from object
$(ELF_FILE): $(O_FILE)
	@echo "Linking to ELF..."
	$(CC) $(CFLAGS) -Wl,-Ttext=0x00000000 -o $@ $<
	@echo "✓ ELF: $@"

# Binary from ELF
$(BIN_FILE): $(ELF_FILE)
	@echo "Extracting binary..."
	$(OBJCOPY) -O binary $< $@
	@echo "✓ Binary: $@"

# Disassembly
$(DIS_FILE): $(ELF_FILE)
	@echo "Generating disassembly..."
	$(OBJDUMP) -d $< > $@
	@echo "✓ Disassembly: $@"
	@echo ""
	@echo "  Instruction Statistics:"
	@echo "    Total instructions: $$(grep -c '^[0-9a-f]' $@ || echo 0)"
	@echo "    Zba instructions: $$(grep -E 'sh[1-3]add|add\.uw|sh[1-3]add\.uw' $@ | wc -l)"
	@echo ""
	@echo "  First 10 instructions:"
	@head -20 $@ | tail -10 | sed 's/^/    /'

# Hex file
$(HEX_FILE): $(BIN_FILE)
	@echo "Generating hex file..."
	@python3 bin2hex.py $< $@
	@echo "✓ Hex: $@"

# Create build directory
$(BUILD_DIR):
	@mkdir -p $@

# ============================================================================
# SIMULATION TARGET
# ============================================================================

sim: $(SIM_EXEC)
	@echo ""
	@echo "Running simulation..."
	@mkdir -p $(LOG_DIR)
	@cd $(SIM_DIR) && vvp tb_processor.vvp 2>&1 | tee simulation.log
	@cp $(SIM_DIR)/simulation.log $(RESULTS_LOG)
	@echo ""
	@echo "✓ Simulation complete"
	@echo ""
	@echo "Test Results:"
	@echo "=============="
	@grep "✓ PASS" $(SIM_DIR)/simulation.log | head -13 || true
	@grep "✗ FAIL" $(SIM_DIR)/simulation.log | head -13 || true
	@echo ""
	@echo "Summary:"
	@if [ -f $(RESULTS_LOG) ]; then \
		PASS=$$(grep -c "^PASS:" $(RESULTS_LOG) || echo 0); \
		echo "$$PASS/10 tests passing"; \
		echo "Detailed results saved to: $(RESULTS_LOG)"; \
	fi

$(SIM_EXEC): prepare
	@echo "Compiling testbench..."
	@cd $(SIM_DIR) && \
		$(SIM) $(SIMFLAGS) -o tb_processor.vvp \
		tb_processor.sv \
		rv64_core.sv regfile.sv alu.sv imm_gen.sv \
		control_unit.sv alu_control.sv \
		forwarding_unit.sv hazard_unit.sv \
		data_mem.sv instr_mem.sv
	@echo "✓ Testbench compiled"

# Prepare simulation directory
prepare: $(HEX_FILE) | $(SIM_DIR)
	@cp $(HEX_FILE) $(SIM_DIR)/
	@cp $(RTL_FILES) $(SIM_DIR)/
	@cp $(TB_FILE) $(SIM_DIR)/
	@echo "✓ Simulation files prepared"

$(SIM_DIR):
	@mkdir -p $@

# ============================================================================
# UTILITY TARGETS
# ============================================================================

disasm: $(DIS_FILE)
	@echo ""
	@echo "Full disassembly in $(DIS_FILE):"
	@echo ""
	@head -50 $(DIS_FILE)
	@echo ""
	@echo "(Use 'cat $(DIS_FILE)' for full listing)"

help:
	@echo "RV64I + Zba Processor Build System"
	@echo ""
	@echo "Targets:"
	@echo "  make all       - Compile and simulate (default)"
	@echo "  make compile   - Compile test program to hex"
	@echo "  make sim       - Run simulation"
	@echo "  make test      - Full test (compile, sim, and show results)"
	@echo "  make test-results - Show test results from latest simulation"
	@echo "  make disasm    - Show disassembly"
	@echo "  make clean     - Clean build artifacts"
	@echo "  make help      - Show this message"
	@echo ""
	@echo "Variables:"
	@echo "  MARCH=$(MARCH)     - ISA arch"
	@echo "  MABI=$(MABI)       - ABI"
	@echo "  SIM=$(SIM)         - Simulator"
	@echo ""
	@echo "Output Files:"
	@echo "  Simulation log: $(SIM_DIR)/simulation.log"
	@echo "  Test results:   $(RESULTS_LOG)"
	@echo ""
	@echo "Examples:"
	@echo "  make                    # Full build and simulation"
	@echo "  make test               # Full test with results"
	@echo "  make compile            # Just compile"
	@echo "  make sim                # Just run simulation"
	@echo "  make clean && make test # Clean rebuild and test"
	@echo "  make test-results       # Show latest test results"

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR) $(SIM_DIR) $(LOG_DIR)
	@echo "✓ Clean complete"

# ============================================================================
# DEBUGGING TARGETS
# ============================================================================

info:
	@echo "Build Configuration:"
	@echo "  Project: $(PROJECT_ROOT)"
	@echo "  Build directory: $(BUILD_DIR)"
	@echo "  Simulation directory: $(SIM_DIR)"
	@echo "  Toolchain prefix: $(RISCV_PREFIX)"
	@echo "  Compiler: $(CC)"
	@echo "  Simulator: $(SIM)"
	@echo "  CFLAGS: $(CFLAGS)"
	@echo ""
	@echo "Files:"
	@echo "  C source: $(C_SRC)"
	@echo "  Assembly: $(S_FILE)"
	@echo "  Object: $(O_FILE)"
	@echo "  ELF: $(ELF_FILE)"
	@echo "  Hex: $(HEX_FILE)"
	@echo ""
	@echo "RTL modules: $$(ls -1 $(RTL_DIR)/*.sv | wc -l) files"
	@echo "  $$(ls -1 $(RTL_DIR)/*.sv)"

show-hex:
	@echo "Hex file contents:"
	@head -20 $(HEX_FILE)

show-elf:
	$(OBJDUMP) -h $(ELF_FILE)

show-sections:
	$(OBJCOPY) --help | grep -i section || echo "Use show-elf target"

# ============================================================================
# DEFAULT TARGET
# ============================================================================

.DEFAULT_GOAL := all
