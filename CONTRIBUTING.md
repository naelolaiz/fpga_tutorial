# Contributing

Thanks for wanting to extend the tutorial! The project is organised so that
adding a new example is a five-minute job.

## Adding an example

1. Create a directory under `src/`, prefixed with the next ordinal number:

   ```
   src/4-my-new-example/
   ```

2. Drop your VHDL sources and testbench inside it.

3. Create a `Makefile` in that directory. It only needs to declare what the
   example is — the `include` at the bottom pulls in every build rule:

   ```make
   EXAMPLE_NAME := 4-my-new-example

   TOP     := my_entity
   TB_TOP  := my_entity_tb

   SRC_FILES := my_entity.vhd
   TB_FILES  := my_entity_tb.vhd

   include ../../mk/common.mk
   ```

4. Run locally to confirm everything builds:

   ```
   make -C src/4-my-new-example all
   ```

5. Push. The CI workflow auto-discovers the new directory; no YAML changes
   required.

## Local development

Install the toolchain (tested on Ubuntu 22.04+):

```
sudo apt-get install ghdl yosys yosys-plugin-ghdl gtkwave xvfb nodejs npm
sudo npm install -g netlistsvg
python -m pip install -r scripts/requirements.txt
```

Useful targets:

| Command                       | What it does                                  |
| ----------------------------- | --------------------------------------------- |
| `make`                        | Runs `simulate`, `diagram`, `screenshot` for every example |
| `make list`                   | Lists the auto-discovered examples            |
| `make 1-styles-vhdl`          | Builds just that one example                  |
| `make -C src/3-testbench simulate` | Simulate a single example                |
| `make clean`                  | Removes every `build/` directory              |

## Style

- VHDL is checked with [VSG](https://vhdl-style-guide.readthedocs.io/);
  see `.vsg.yaml`. The lint job is currently informational (`continue-on-error`)
  and will become blocking once the tree is clean.
- Python files are formatted to be `ruff`-clean and carry type hints. New
  helper scripts go under `scripts/`.
