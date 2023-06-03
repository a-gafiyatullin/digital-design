// controller.sv
//
// This file is for HMC E85A Lab 5.
// Place controller.tv in same computer directory as this file to test your multicycle controller.
//
// Starter code last updated by Ben Bracker (bbracker@hmc.edu) 1/14/21
// - added opcodetype enum
// - updated testbench and hash generator to accomodate don't cares as expected outputs
// Solution code by Albert Gafiyatullin

typedef enum logic[6:0] {r_type_op=7'b0110011, i_type_alu_op=7'b0010011, lw_op=7'b0000011, sw_op=7'b0100011, beq_op=7'b1100011, jal_op=7'b1101111} opcodetype;

module controller(input  logic       clk,
                  input  logic       reset,  
                  input  opcodetype  op,
                  input  logic [2:0] funct3,
                  input  logic       funct7b5,
                  input  logic       Zero,
                  output logic [1:0] ImmSrc,
                  output logic [1:0] ALUSrcA, ALUSrcB,
                  output logic [1:0] ResultSrc, 
                  output logic       AdrSrc,
                  output logic [2:0] ALUControl,
                  output logic       IRWrite, PCWrite, 
                  output logic       RegWrite, MemWrite);
  logic Branch, PCUpdate;
  logic [1:0] ALUOp;
  
  MainFSM mainfsm(clk, reset, op,
                  ALUSrcA, ALUSrcB,
                  ResultSrc, AdrSrc,
                  IRWrite, RegWrite, MemWrite,
                  Branch, PCUpdate,
                  ALUOp);
  
  ALUDecoder aludecoder(op[5], funct3, funct7b5, ALUOp, ALUControl);

  InstrDecoder instrdecoder(op, ImmSrc);

  always_comb begin
    PCWrite = PCUpdate || (Branch && (Zero && funct3 == 'b000 || !Zero && funct3 == 'b001));
  end
endmodule

module ALUDecoder(input  logic       op5,
                  input  logic [2:0] funct3,
                  input  logic       funct7b5,
                  input  logic [1:0] ALUOp,
                  output logic [2:0] ALUControl);
  always_comb begin
    case (ALUOp)
      'b00: ALUControl = 'b000;
      'b01: ALUControl = 'b001;
      'b10: begin
              case (funct3)
                'b000: begin
                        if ({op5, funct7b5} == 'b11)
                          ALUControl = 'b001;
                        else
                          ALUControl = 'b000;
                       end
                'b010: ALUControl   = 'b101;
                'b110: ALUControl   = 'b011;
                'b111: ALUControl   = 'b010;
                default: ALUControl = 'b000;
              endcase
            end
    endcase
  end
endmodule

module InstrDecoder(input  opcodetype  op,
                    output logic [1:0] ImmSrc);
  always_comb begin
    case (op)
      'b0000011:  ImmSrc = 'b00;
      'b0100011:  ImmSrc = 'b01;
      'b0110011:  ImmSrc = 'b00;
      'b1100011:  ImmSrc = 'b10;
      'b0010011:  ImmSrc = 'b00;
      'b1101111:  ImmSrc = 'b11;
      default:    ImmSrc = 'b00;
    endcase
  end
endmodule

module MainFSM(input  logic       clk,
               input  logic       reset,
               input  opcodetype  op,
               output logic [1:0] ALUSrcA, ALUSrcB,
               output logic [1:0] ResultSrc,
               output logic       AdrSrc,
               output logic       IRWrite,
               output logic       RegWrite, MemWrite,
               output logic       Branch,
               output logic       PCUpdate,
               output logic [1:0] ALUOp);
  logic [3:0] state;
  logic [3:0] next_state;

  flopr #(4) flop(clk, reset, next_state, state);

  logic [13:0] signals;

  assign {AdrSrc, IRWrite, ALUSrcA, ALUSrcB, ALUOp,
          ResultSrc, PCUpdate, RegWrite, MemWrite,
          Branch} = signals;
  
  always_comb begin
    case (state)
      'b0000: begin
                // AdrSrc, IRWrite, ALUSrcA, ALUSrcB, ALUOp, ResultSrc, PCUpdate, RegWrite, MemWrite, Branch
                signals = 'b0_1_00_10_00_10_1_0_0_0;
                next_state = 'b0001;
              end
      'b0001: begin
                // AdrSrc, IRWrite, ALUSrcA, ALUSrcB, ALUOp, ResultSrc, PCUpdate, RegWrite, MemWrite, Branch
                signals = 'b0_0_01_01_00_00_0_0_0_0;

                case (op)
                  'b0000011: next_state = 'b0010;
                  'b0100011: next_state = 'b0010;
                  'b0110011: next_state = 'b0110;
                  'b0010011: next_state = 'b1000;
                  'b1101111: next_state = 'b1001;
                  'b1100011: next_state = 'b1010;
                  default:   next_state = 'b0000;
                endcase
              end
      'b0010: begin
                // AdrSrc, IRWrite, ALUSrcA, ALUSrcB, ALUOp, ResultSrc, PCUpdate, RegWrite, MemWrite, Branch
                signals = 'b0_0_10_01_00_00_0_0_0_0;

                case (op)
                  'b0000011: next_state = 'b0011;
                  'b0100011: next_state = 'b0101;
                  default:   next_state = 'b0000;
                endcase
              end
      'b0011: begin
                // AdrSrc, IRWrite, ALUSrcA, ALUSrcB, ALUOp, ResultSrc, PCUpdate, RegWrite, MemWrite, Branch
                signals = 'b1_0_00_00_00_00_0_0_0_0;
                next_state = 'b0100;
              end
      'b0100: begin
                // AdrSrc, IRWrite, ALUSrcA, ALUSrcB, ALUOp, ResultSrc, PCUpdate, RegWrite, MemWrite, Branch
                signals = 'b0_0_00_00_00_01_0_1_0_0;
                next_state = 'b0000;
              end
      'b0101: begin
                // AdrSrc, IRWrite, ALUSrcA, ALUSrcB, ALUOp, ResultSrc, PCUpdate, RegWrite, MemWrite, Branch
                signals = 'b1_0_00_00_00_00_0_0_1_0;
                next_state = 'b0000;
              end
      'b0110: begin
                // AdrSrc, IRWrite, ALUSrcA, ALUSrcB, ALUOp, ResultSrc, PCUpdate, RegWrite, MemWrite, Branch
                signals = 'b0_0_10_00_10_00_0_0_0_0;
                next_state = 'b0111;
              end
      'b0111: begin
                // AdrSrc, IRWrite, ALUSrcA, ALUSrcB, ALUOp, ResultSrc, PCUpdate, RegWrite, MemWrite, Branch
                signals = 'b0_0_00_00_00_00_0_1_0_0;
                next_state = 'b0000;
              end
      'b1000: begin
                // AdrSrc, IRWrite, ALUSrcA, ALUSrcB, ALUOp, ResultSrc, PCUpdate, RegWrite, MemWrite, Branch
                signals = 'b0_0_10_01_10_00_0_0_0_0;
                next_state = 'b0111;
              end
      'b1001: begin
                // AdrSrc, IRWrite, ALUSrcA, ALUSrcB, ALUOp, ResultSrc, PCUpdate, RegWrite, MemWrite, Branch
                signals = 'b0_0_01_10_00_00_1_0_0_0;
                next_state = 'b0111;
              end
      'b1010: begin
                // AdrSrc, IRWrite, ALUSrcA, ALUSrcB, ALUOp, ResultSrc, PCUpdate, RegWrite, MemWrite, Branch
                signals = 'b0_0_10_00_01_00_0_0_0_1;
                next_state = 'b0000;
              end
      default: begin
                // AdrSrc, IRWrite, ALUSrcA, ALUSrcB, ALUOp, ResultSrc, PCUpdate, RegWrite, MemWrite, Branch
                signals = 'b0_0_00_00_00_00_0_0_0_0;
                next_state = 'b0000;
              end
    endcase
  end
endmodule