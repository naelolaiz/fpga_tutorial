# ---------------------------------------------------------------------------
# Example 3: Monostable multivibrator (one-shot timer) + testbench.
# ---------------------------------------------------------------------------

EXAMPLE_NAME := 3-testbench

TOP     := monostable
TB_TOP  := monostable_tb

SRC_FILES := monostable.vhd
TB_FILES  := monostable_tb.vhd

# One-shot examples typically need a longer observation window than a
# combinational circuit; override the default here.
SIM_TIME := 10ms

include ../../mk/common.mk
