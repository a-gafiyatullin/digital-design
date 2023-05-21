#!/bin/bash

iverilog -g2012 -o riscvsingle.vvp riscvsingle.sv
vvp -n riscvsingle.vvp