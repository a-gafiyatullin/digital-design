#!/bin/bash

iverilog -g2012 -o testbench.vvp testbench.sv
vvp -n testbench.vvp