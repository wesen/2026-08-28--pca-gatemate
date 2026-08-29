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
YOSYS_DATDIR := $(shell yosys-config --datdir 2>/dev/null)
PLACEMENT_INPUT := config/z80_objects.json
PLACEMENT_JSON  := $(BUILD)/placement.json
PLACEMENT_SV    := $(BUILD)/pca_placement_pkg.sv

# Phase 0: just reset_sync + a minimal top that proves the flow.
RTL_SYNTH := $(RTL_DIR)/reset_sync.sv $(RTL_DIR)/top.sv
SIM_SRCS  := $(RTL_DIR)/reset_sync.sv $(RTL_DIR)/top.sv \
             $(SIM_DIR)/CC_USR_RSTN.sv $(SIM_DIR)/tb_top.sv

# Board-facing direct and generated-placement mesh cores. Yosys prunes the
# unselected generate branch through the top-level MESH_MODE parameter.
Z80_TOP_RTL := $(PLACEMENT_SV) $(RTL_DIR)/pca_types.sv $(RTL_DIR)/z80_obj.sv \
             $(RTL_DIR)/pca_router.sv $(RTL_DIR)/pca_cell.sv $(RTL_DIR)/pca_mesh.sv \
             $(RTL_DIR)/z80_mesh_adapter.sv $(RTL_DIR)/obj_pc.sv $(RTL_DIR)/obj_memio.sv \
             $(RTL_DIR)/obj_regfile.sv $(RTL_DIR)/obj_alu.sv $(RTL_DIR)/obj_flags.sv \
             $(RTL_DIR)/obj_decode.sv $(RTL_DIR)/z80_core.sv $(RTL_DIR)/z80_mesh_core.sv \
             $(RTL_DIR)/reset_sync.sv $(RTL_DIR)/uart_tx.sv $(RTL_DIR)/top.sv
PROG ?= blink
ROM_DEPTH ?= 512
MESH_MODE ?= 0
DEBUG_LED_MODE ?= 0
PNR_SEED ?= 1

# Phase 1: the PCA routing substrate (types/router/cell/mesh) + testbench.
PCA_RTL   := $(RTL_DIR)/pca_types.sv $(RTL_DIR)/pca_router.sv $(RTL_DIR)/pca_cell.sv $(RTL_DIR)/pca_mesh.sv
SIM_MESH_SRCS := $(PCA_RTL) $(SIM_DIR)/tb_pca_mesh.sv

# Phase 6: board top (z80_core + reset_sync + uart_tx + top) for hello sim.
TOP_RTL   := $(Z80_TOP_RTL)
SIM_HELLO_SRCS := $(TOP_RTL) $(SIM_DIR)/CC_USR_RSTN.sv $(SIM_DIR)/tb_hello.sv

# Phase 3: the Z80 object graph (bus contract + objects + core) + testbench.
Z80_RTL   := $(RTL_DIR)/z80_obj.sv $(RTL_DIR)/obj_pc.sv $(RTL_DIR)/obj_memio.sv $(RTL_DIR)/obj_regfile.sv $(RTL_DIR)/obj_alu.sv $(RTL_DIR)/obj_flags.sv $(RTL_DIR)/obj_decode.sv $(RTL_DIR)/z80_core.sv
SIM_CORE_SRCS := $(Z80_RTL) $(SIM_DIR)/tb_z80_core.sv

.PHONY: all versions test sim synth pnr bit load clean placement check_placement test_placer test_mesh_integ sim_mesh_hello
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

# Pure-software unit tests (Phase 2+4): model + ISA + assembler. Phase 1+3: substrate + object-graph sim.
.PHONY: test
test: sim_mesh sim_core test_model test_assembler test_integ test_placer test_mesh_integ

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

# Phase 4 assembler tests (golden vectors + assemble->model cross-check).
.PHONY: test_assembler
test_assembler:
	python3 -m pytest sim/test_assembler.py -q

# Phase 5 integration tests (assemble -> object graph vs model, differential).
.PHONY: test_integ
test_integ:
	python3 -m pytest sim/test_integ.py -q

# Continuation P3: deterministic static logical placement + generated artifacts.
$(PLACEMENT_JSON) $(PLACEMENT_SV) &: $(PLACEMENT_INPUT) tools/placer.py
	@mkdir -p $(BUILD)
	python3 tools/placer.py --input $(PLACEMENT_INPUT) --json $(PLACEMENT_JSON) --sv $(PLACEMENT_SV)

placement: $(PLACEMENT_JSON) $(PLACEMENT_SV)

check_placement:
	python3 tools/placer.py --input $(PLACEMENT_INPUT) --json $(PLACEMENT_JSON) --sv $(PLACEMENT_SV) --check

test_placer:
	python3 -m pytest sim/test_placer.py -q

# Continuation P4: assembled programs traverse generated endpoints and PCA routers.
test_mesh_integ: placement
	python3 -m pytest sim/test_mesh_integ.py -q

# Phase 6 UART bring-up sim (Z80 emits 'Hi' over the memory-mapped UART).
.PHONY: sim_hello
sim_hello: placement
	@mkdir -p $(BUILD)
	python3 tools/zasm.py programs/hello.asm -o $(BUILD) -n hello
	iverilog -g2012 -s tb_hello -o $(BUILD)/hello.vvp $(SIM_HELLO_SRCS)
	vvp $(BUILD)/hello.vvp | tee $(BUILD)/hello_sim.log

sim_mesh_hello: placement
	@mkdir -p $(BUILD)
	python3 tools/zasm.py programs/hello.asm -o $(BUILD) -n hello
	iverilog -g2012 -s tb_mesh_hello -o $(BUILD)/mesh_hello.vvp $(TOP_RTL) \
	  $(SIM_DIR)/CC_USR_RSTN.sv $(SIM_DIR)/tb_mesh_hello.sv
	vvp $(BUILD)/mesh_hello.vvp | tee $(BUILD)/mesh_hello_sim.log

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
# Phase 6: synthesize the Z80 top with the assembled program ROM.
synth: placement
	@mkdir -p $(BUILD)
	python3 tools/zasm.py programs/$(PROG).asm -o $(BUILD) -n top_prog --size $(ROM_DEPTH)
	yosys -ql $(BUILD)/yosys.log -p 'read_verilog -defer -sv -DROM_FILE="$(BUILD)/top_prog.hex" $(Z80_TOP_RTL); chparam -set ROM_DEPTH $(ROM_DEPTH) -set MESH_MODE $(MESH_MODE) -set DEBUG_LED_MODE $(DEBUG_LED_MODE) top; synth_gatemate -top top -luttree -nomx8; stat; write_json $(BUILD)/top.json;'

# Gate-level firmware smoke test: proves BRAM init survives synth_gatemate.
.PHONY: post_synth
post_synth: synth
	yosys -q -p 'read_json $(BUILD)/top.json; write_verilog -noattr $(BUILD)/top_synth.v'
	python3 tools/check_gatemate_rom.py $(BUILD)/top_synth.v
	iverilog -g2012 -s tb_post_synth -o $(BUILD)/post_synth.vvp \
	  $(YOSYS_DATDIR)/gatemate/cells_sim.v sim/CC_USR_RSTN.sv \
	  $(BUILD)/top_synth.v sim/tb_post_synth.sv
	vvp $(BUILD)/post_synth.vvp

# Place and route (sibling §1.8): nextpnr-himbaechel, router2, CCF + SDC.
pnr: synth
	@mkdir -p $(BUILD)
	nextpnr-himbaechel -l $(BUILD)/nextpnr.log --device $(DEVICE) \
	  --json $(BUILD)/top.json \
	  -o ccf=$(CCF) -o out=$(BUILD)/top.txt \
	  --sdc $(SDC) --router router2 --seed $(PNR_SEED)

# Bitstream (sibling §1.8): gmpack.
bit: pnr
	gmpack $(BUILD)/top.txt $(BUILD)/top.bit

# Load to board over the RP2040 DirtyJTAG bridge (sibling §1.8).
load: bit
	openFPGALoader -b $(BOARD) $(BUILD)/top.bit

clean:
	rm -f $(BUILD)/*.json $(BUILD)/*.txt $(BUILD)/*.bit $(BUILD)/*.vcd $(BUILD)/*.log $(BUILD)/*.vvp $(PLACEMENT_SV)
