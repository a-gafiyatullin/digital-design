#!/bin/bash

iverilog -g2012 -o controller.vvp controller.sv
vvp -n controller.vvp