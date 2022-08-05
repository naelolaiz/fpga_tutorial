# fpga_tutorial
Collecting small FPGA examples as a tutorial
## TOC
* [Example showing different coding styles of VHDL, on a small SOP](src/1-styles-vhdl)
* [Example on how to create a testbench for simulations, on a monostable multivibrator (one-shot timer)](src/3-testbench)
## GHDL github Actions
Added [github actions CI jobs](https://github.com/naelolaiz/fpga_tutorial/actions) for simulating the examples with GHDL!
![screenshot github action](doc/screenshot_ci_job_with_ghdl.png)
### TODO
* integrate https://github.com/ponty/sphinxcontrib-gtkwave to generate screenshots of the simulation with gtkwave  
  * generate .vcd file for gtkwave as
```
ghdl -a input_tb.vhd
ghdl -e input_tb
ghdl -r input_tb --vcd=output.vcd
```
