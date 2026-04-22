# ---------------------------------------------------------------------------
# Example 1: VHDL coding styles (behavioural / dataflow / structural) on
# a small sum-of-products function.
#
# This Makefile only declares *what* this example is. Every *how* lives
# in ../../mk/common.mk.
# ---------------------------------------------------------------------------

EXAMPLE_NAME := 1-styles-vhdl

# Top-level entity exercised by the diagram generator.
TOP     := dataflow_example

# Testbench top used by the simulator.
TB_TOP  := sop_tb

# Source files (design under test).
SRC_FILES := \
    behavioral_example.vhd \
    dataflow_example.vhd \
    structural_example.vhd

# Testbench files.
TB_FILES := sop_tb.vhd

# Inherit all rules.
include ../../mk/common.mk
