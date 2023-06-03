`include "primitives.sv"
`include "controller.sv"

///////////////////////////////////////////////////////////////
// mem
//
// Single-ported RAM with read and write ports
// Initialized with machine language program
///////////////////////////////////////////////////////////////
module mem
         #(parameter N = 64)
          (input  logic        clk, we,
           input  logic [31:0] a, wd,
           output logic [31:0] rd);

  logic [31:0] RAM[N - 1:0];
  
  initial
      $readmemh("tests/riscvtest-exam.txt",RAM);
      //$readmemh("tests/riscvtest.txt",RAM);

  assign rd = RAM[a[31:2]]; // word aligned

  always_ff @(posedge clk)
    if (we) RAM[a[31:2]] <= wd;
endmodule

///////////////////////////////////////////////////////////////
// top
//
// Instantiates multicycle RISC-V processor and memory
///////////////////////////////////////////////////////////////
module top(input  logic        clk, reset, 
           output logic [31:0] WriteData, DataAdr, 
           output logic        MemWrite);

  logic [31:0] ReadData;
  
  // instantiate processor and memories
  riscvmulti rvmulti(clk, reset, MemWrite, DataAdr, 
                     WriteData, ReadData);
  mem mem(clk, MemWrite, DataAdr, WriteData, ReadData);
endmodule

module regfile(input  logic        clk, 
               input  logic        we3, 
               input  logic [ 4:0] a1, a2, a3, 
               input  logic [31:0] wd3, 
               output logic [31:0] rd1, rd2);

  logic [31:0] rf[31:0];

  // three ported register file
  // read two ports combinationally (A1/RD1, A2/RD2)
  // write third port on rising edge of clock (A3/WD3/WE3)
  // register 0 hardwired to 0

  always_ff @(posedge clk)
    if (we3) rf[a3] <= wd3;	

  assign rd1 = (a1 != 0) ? rf[a1] : 0;
  assign rd2 = (a2 != 0) ? rf[a2] : 0;
endmodule

///////////////////////////////////////////////////////////////
// extend
//
// Gather bits to 32 bit immediate
///////////////////////////////////////////////////////////////
module extend(input  logic [31:7] instr,
              input  logic [1:0]  immsrc,
              output logic [31:0] immext);
 
  always_comb
    case(immsrc) 
               // I-type 
      2'b00:   immext = {{20{instr[31]}}, instr[31:20]};  
               // S-type (stores)
      2'b01:   immext = {{20{instr[31]}}, instr[31:25], instr[11:7]}; 
               // B-type (branches)
      2'b10:   immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; 
               // J-type (jal)
      2'b11:   immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; 
      default: immext = 32'bx; // undefined
    endcase             
endmodule

///////////////////////////////////////////////////////////////
// alu
//
// Arithmetics
///////////////////////////////////////////////////////////////
module alu(input  logic [31:0] a, b,
           input  logic [2:0]  alucontrol,
           output logic [31:0] result,
           output logic        zero);

  logic [31:0] condinvb, sum;

  assign condinvb = alucontrol[0] ? ~b : b;
  assign sum = a + condinvb + alucontrol[0];

  always_comb
    case (alucontrol)
      3'b000:  result = sum;       // add
      3'b001:  result = sum;       // subtract
      3'b010:  result = a & b;     // and
      3'b011:  result = a | b;     // or
      3'b101:  result = sum[31];   // slt
      3'b110:  result = a << b;
      default: result = 32'bx;
    endcase

  assign zero = (result == 32'b0);
endmodule

///////////////////////////////////////////////////////////////
// riscvmulti
//
// Multicycle RISC-V microprocessor
///////////////////////////////////////////////////////////////
module riscvmulti(input  logic        clk, reset,
                  output logic        MemWrite,
                  output logic [31:0] Adr, WriteData,
                  input  logic [31:0] ReadData);
  
  logic PCwrite, AddrSrc, IRWrite, RegWrite, Zero;
  
  logic [31:0] Result,
               PC, Instr, OldPC, Data,
               RD1, RD2, RD1RegRes, RD2RegRes, ImmExt,
               SrcA, SrcB, ResultALU, ALUOut;
  
  logic [1:0]  ImmSrc, ResultSrc, ALUSrcA, ALUSrcB;
  
  logic [2:0]  ALUControl;

  // controller
  controller control(clk, reset, Instr[6:0], Instr[14:12], Instr[30], Zero,
                    ImmSrc, ALUSrcA, ALUSrcB, ResultSrc, AddrSrc, ALUControl,
                    IRWrite, PCWrite, RegWrite, MemWrite);

  // register file
  regfile regs(clk, RegWrite, Instr[19:15], Instr[24:20], Instr[11:7], Result, RD1, RD2);  
  
  // ---- stages ----
  
  // fetch
  flopenr #(32) PCNextReg(clk, reset, PCWrite, Result, PC);
  flopenr #(32) InstrReg(clk, reset, IRWrite, ReadData, Instr);
  flopenr #(32) OldPCReg(clk, reset, IRWrite, PC, OldPC);
  flop    #(32) DataReg(clk, ReadData, Data);
  mux2    #(32) PCmux(PC, Result, AddrSrc, Adr);

  // decode
  extend extender(Instr[31:7], ImmSrc, ImmExt);
  flop    #(32) RD1Reg(clk, RD1, RD1RegRes);
  flop    #(32) RD2Reg(clk, RD2, WriteData);

  //execute
  mux3  #(32) SrcAMux(PC, OldPC, RD1RegRes, ALUSrcA, SrcA);
  mux3  #(32) SrcBMux(WriteData, ImmExt, 32'd4, ALUSrcB, SrcB);
  alu ALU(SrcA, SrcB, ALUControl, ResultALU, Zero);
  flop  #(32) ResultReg(clk, ResultALU, ALUOut);

  // Next Cycle
  mux3  #(32) ResultMux(ALUOut, Data, ResultALU, ResultSrc, Result);
endmodule