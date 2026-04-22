# ---------------------------------------------------------------------------
# mk/common.mk - Shared build rules for every VHDL example in this tutorial.
#
# Each example's Makefile is expected to define the following variables and
# then `include` this file:
#
#   EXAMPLE_NAME   Human-readable identifier (used in artifact names).
#   TOP            Top-level entity for synthesis / diagram generation.
#   TB_TOP         Top-level entity of the testbench (simulation entry point).
#   SRC_FILES      VHDL sources that make up the design (relative to Makefile).
#   TB_FILES       VHDL sources that make up the testbench (relative).
#   VHDL_STANDARD  Optional. Defaults to 08 (VHDL-2008). Use 93 / 02 / 08.
#   SIM_TIME       Optional. Simulation stop time (e.g. 10us). Default: 1ms.
#
# The tool invocations are deliberately centralised here so that every
# example stays a few lines long and all CI / local runs go through the
# same code path.
# ---------------------------------------------------------------------------

# ---- Tool discovery (overridable from the environment) --------------------
GHDL          ?= ghdl
YOSYS         ?= yosys
NETLISTSVG    ?= netlistsvg
PYTHON        ?= python3

# ---- Per-example defaults --------------------------------------------------
VHDL_STANDARD ?= 08
SIM_TIME      ?= 1ms

# ---- Layout ----------------------------------------------------------------
# Every artifact (work library, VCDs, netlists, screenshots, diagrams) lands
# under build/ so that `make clean` is a single rm -rf and nothing leaks
# into the source tree.
BUILD_DIR      := build
WORK_DIR       := $(BUILD_DIR)/work
VCD_FILE       := $(BUILD_DIR)/$(TB_TOP).vcd
WAVEFORM_PNG   := $(BUILD_DIR)/$(TB_TOP).png
NETLIST_JSON   := $(BUILD_DIR)/$(TOP).json
DIAGRAM_SVG    := $(BUILD_DIR)/$(TOP).svg

# ---- GHDL flags ------------------------------------------------------------
# --std picks the language standard; --workdir keeps the compiled library
# out of the source tree; -fsynopsys allows std_logic_arith-style packages.
GHDL_FLAGS     := --std=$(VHDL_STANDARD) --workdir=$(WORK_DIR) -fsynopsys

# Resolve the repository root so scripts can be called from anywhere.
REPO_ROOT      := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
SCRIPTS_DIR    := $(REPO_ROOT)/scripts

# ---- Phony targets ---------------------------------------------------------
.PHONY: all analyze elaborate simulate waveform diagram screenshot clean help

# `all` is what CI runs per example: everything that produces an artifact.
all: simulate diagram screenshot

help:
	@echo "Targets for example '$(EXAMPLE_NAME)':"
	@echo "  analyze     Parse and type-check the VHDL sources."
	@echo "  elaborate   Elaborate the testbench top ($(TB_TOP))."
	@echo "  simulate    Run the simulation and produce $(VCD_FILE)."
	@echo "  diagram     Synthesise $(TOP) with yosys+ghdl and render an SVG."
	@echo "  screenshot  Render a GTKWave PNG of the simulation waveform."
	@echo "  clean       Remove all build artifacts."

$(BUILD_DIR) $(WORK_DIR):
	@mkdir -p $@

# ---- Analyze ---------------------------------------------------------------
# A single GHDL analyze call per invocation; GHDL handles dependency order
# internally provided all sources are passed together.
analyze: | $(WORK_DIR)
	$(GHDL) -a $(GHDL_FLAGS) $(SRC_FILES) $(TB_FILES)

# ---- Elaborate -------------------------------------------------------------
elaborate: analyze
	$(GHDL) -e $(GHDL_FLAGS) $(TB_TOP)

# ---- Simulate --------------------------------------------------------------
# GHDL produces the VCD directly; we route it into build/ and cap the run
# time so a runaway testbench can't hang CI forever.
simulate: $(VCD_FILE)

$(VCD_FILE): elaborate | $(BUILD_DIR)
	$(GHDL) -r $(GHDL_FLAGS) $(TB_TOP) \
	    --vcd=$@ \
	    --stop-time=$(SIM_TIME)

# ---- Waveform screenshot ---------------------------------------------------
# Delegates to the Python helper which drives GTKWave inside a virtual X
# server. Keeps the render concerns out of the Makefile.
screenshot: $(WAVEFORM_PNG)

$(WAVEFORM_PNG): $(VCD_FILE)
	$(PYTHON) $(SCRIPTS_DIR)/gtkwave_export.py \
	    --input $< \
	    --output $@

# ---- Netlist diagram -------------------------------------------------------
# yosys+ghdl-yosys-plugin synthesises the top entity into a generic netlist
# which netlistsvg then turns into an SVG suitable for the README / CI artifact.
diagram: $(DIAGRAM_SVG)

$(NETLIST_JSON): $(SRC_FILES) | $(BUILD_DIR)
	$(YOSYS) -m ghdl -p \
	    "ghdl --std=$(VHDL_STANDARD) -fsynopsys $(SRC_FILES) -e $(TOP); \
	     write_json $@"

$(DIAGRAM_SVG): $(NETLIST_JSON)
	$(NETLISTSVG) $< -o $@

# ---- Housekeeping ----------------------------------------------------------
clean:
	@rm -rf $(BUILD_DIR)
	@rm -f *.cf *.o $(TB_TOP) $(TOP)
