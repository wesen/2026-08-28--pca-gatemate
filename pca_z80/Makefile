# Makefile — PCA-Z80 on the Olimex GateMateA1-EVB (Cologne Chip CCGM1A1)
#
# Architecture + phases: see ttmp/.../design-doc/01-pca-z80-system-intern-onboarding-guide.md (§13).
# Toolchain: OSS CAD Suite — source its `environment` before building:
#     source ~/fpga/oss-cad-suite/environment
# Reuses the verified board pins + flow from the sibling MATE-16 project.

TOP      ?= top
DEVICE   ?= CCGM1A1
BOARD    ?= olimex_gatemateevb
CCF      ?= constraints/olimex_gatematea1_evb.ccf
SDC      ?= constraints/top.sdc
SIM_TOP  ?= tb_top

RTL_DIR  := rtl
SIM_DIR  := sim
BUILD    := build

# Phase 0: just reset_sync + a minimal top that proves the flow.
RTL_SYNTH := $(RTL_DIR)/reset_sync.sv $(RTL_DIR)/top.sv
SIM_SRCS  := $(RTL_DIR)/reset_sync.sv $(RTL_DIR)/top.sv \
             $(SIM_DIR)/CC_USR_RSTN.sv $(SIM_DIR)/tb_top.sv

# Phase 1: the PCA routing substrate (types/router/cell/mesh) + testbench.
PCA_RTL   := $(RTL_DIR)/pca_types.sv $(RTL_DIR)/pca_router.sv $(RTL_DIR)/pca_cell.sv $(RTL_DIR)/pca_mesh.sv
SIM_MESH_SRCS := $(PCA_RTL) $(SIM_DIR)/tb_pca_mesh.sv

# Phase 3: the Z80 object graph (bus contract + objects + core) + testbench.
Z80_RTL   := $(RTL_DIR)/z80_obj.sv $(RTL_DIR)/obj_pc.sv $(RTL_DIR)/obj_memio.sv $(RTL_DIR)/obj_decode.sv $(RTL_DIR)/z80_core.sv
SIM_CORE_SRCS := $(Z80_RTL) $(SIM_DIR)/tb_z80_core.sv

.PHONY: all versions test sim synth pnr bit load clean
all: sim bit

# Record exact tool versions (sibling §1.4 / Exercise 1.1): never "latest".
.PHONY: versions
versions:
	@mkdir -p $(BUILD)
	@{ \
	  date -u; \
	  echo "OSS CAD Suite: $$(cat ~/fpga/oss-cad-suite/VERSION 2>/dev/null)"; \
	  yosys -V; \
	  nextpnr-himbaechel --version 2>&1; \
	  openFPGALoader --version 2>&1; \
	  iverilog -V 2>&1 | head -n 2; \
	  verilator --version 2>&1; \
	  python3 --version 2>&1; \
	} | tee $(BUILD)/tool-versions.txt

# Pure-software unit tests (Phase 2): reference model + ISA. Phase 1+3: substrate + object-graph sim.
.PHONY: test
test: sim_mesh sim_core test_model

# Phase 3 object-graph simulation (directed differential vs the oracle).
.PHONY: sim_core
sim_core:
	@mkdir -p $(BUILD)
	iverilog -g2012 -s tb_z80_core -o $(BUILD)/z80_core.vvp $(SIM_CORE_SRCS)
	vvp $(BUILD)/z80_core.vvp | tee $(BUILD)/z80_core_sim.log

# Phase 2 reference-model unit tests (pytest, toolchain-independent).
.PHONY: test_model
test_model:
	python3 -m pytest sim/test_model.py -q

# Phase 1 substrate simulation.
.PHONY: sim_mesh
sim_mesh:
	@mkdir -p $(BUILD)
	iverilog -g2012 -s tb_pca_mesh -o $(BUILD)/pca_mesh.vvp $(SIM_MESH_SRCS)
	vvp $(BUILD)/pca_mesh.vvp | tee $(BUILD)/pca_mesh_sim.log

# Assemble a program (Phase 4+): default target program.asm -> build/program.*
.PHONY: asm
asm:
	@echo "assembler arrives in Phase 4"

# Simulation (sibling §1.7): uses the sim-only CC_USR_RSTN model.
sim:
	@mkdir -p $(BUILD)
	iverilog -g2012 -s $(SIM_TOP) -o $(BUILD)/top.vvp $(SIM_SRCS)
	vvp $(BUILD)/top.vvp

# Synthesis (sibling §1.8): Yosys synth_gatemate with -luttree -nomx8.
synth:
	@mkdir -p $(BUILD)
	yosys -ql $(BUILD)/yosys.log -p 'read_verilog -defer -sv $(RTL_SYNTH); synth_gatemate -top $(TOP) -luttree -nomx8; stat; write_json $(BUILD)/top.json;'

# Place and route (sibling §1.8): nextpnr-himbaechel, router2, CCF + SDC.
pnr: synth
	@mkdir -p $(BUILD)
	nextpnr-himbaechel -l $(BUILD)/nextpnr.log --device $(DEVICE) \
	  --json $(BUILD)/top.json \
	  -o ccf=$(CCF) -o out=$(BUILD)/top.txt \
	  --sdc $(SDC) --router router2

# Bitstream (sibling §1.8): gmpack.
bit: pnr
	gmpack $(BUILD)/top.txt $(BUILD)/top.bit

# Load to board over the RP2040 DirtyJTAG bridge (sibling §1.8).
load: bit
	openFPGALoader -b $(BOARD) $(BUILD)/top.bit

clean:
	rm -f $(BUILD)/*.json $(BUILD)/*.txt $(BUILD)/*.bit $(BUILD)/*.vcd $(BUILD)/*.log $(BUILD)/*.vvp
