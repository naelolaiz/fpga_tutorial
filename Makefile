# ---------------------------------------------------------------------------
# Top-level Makefile.
#
# Auto-discovers every subdirectory under src/ that has a Makefile and
# forwards targets to it. Running `make` at the repo root therefore
# exercises every example the same way CI does.
# ---------------------------------------------------------------------------

# Every directory under src/ that ships its own Makefile.
EXAMPLES := $(patsubst src/%/Makefile,%,$(wildcard src/*/Makefile))

# Targets we forward to each example. Keep in sync with mk/common.mk.
FORWARDED_TARGETS := all analyze elaborate simulate waveform diagram screenshot clean

.PHONY: help list $(FORWARDED_TARGETS) $(EXAMPLES)

help:
	@echo "fpga_tutorial - top-level orchestration"
	@echo ""
	@echo "Discovered examples:"
	@$(foreach e,$(EXAMPLES),echo "  - $(e)";)
	@echo ""
	@echo "Targets (run against every example):"
	@echo "  all         simulate + diagram + screenshot"
	@echo "  analyze     ghdl -a"
	@echo "  elaborate   ghdl -e"
	@echo "  simulate    ghdl -r (emits a VCD)"
	@echo "  diagram     yosys + netlistsvg (emits an SVG)"
	@echo "  screenshot  gtkwave headless (emits a PNG)"
	@echo "  clean       remove every build/ directory"
	@echo ""
	@echo "You can also target a single example: make 1-styles-vhdl"

list:
	@$(foreach e,$(EXAMPLES),echo $(e);)

# Forward each top-level target to every example.
$(FORWARDED_TARGETS):
	@for dir in $(EXAMPLES); do \
	    echo "==> src/$$dir: make $@"; \
	    $(MAKE) -C src/$$dir $@ || exit $$?; \
	done

# Allow `make <example-name>` as shorthand for `make -C src/<example-name> all`.
$(EXAMPLES):
	$(MAKE) -C src/$@ all
