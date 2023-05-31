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
    PCWrite = PCUpdate || (Branch && Zero);
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

  flipflop flop(clk, reset, next_state, state);

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

module flipflop(input  logic       clk,
                input  logic       reset,
                input  logic [3:0] data,
                output logic [3:0] out);
  always_ff @(posedge clk or posedge reset)
    if (reset) out <= 'b0000;
    else out <= data;
endmodule

module testbench();

  logic        clk;
  logic        reset;
  
  opcodetype  op;
  logic [2:0] funct3;
  logic       funct7b5;
  logic       Zero;
  logic [1:0] ImmSrc;
  logic [1:0] ALUSrcA, ALUSrcB;
  logic [1:0] ResultSrc;
  logic       AdrSrc;
  logic [2:0] ALUControl;
  logic       IRWrite, PCWrite;
  logic       RegWrite, MemWrite;
  
  logic [31:0] vectornum, errors;
  logic [39:0] testvectors[10000:0];
  
  logic        new_error;
  logic [15:0] expected;
  logic [6:0]  hash;


  // instantiate device to be tested
  controller dut(clk, reset, op, funct3, funct7b5, Zero,
                 ImmSrc, ALUSrcA, ALUSrcB, ResultSrc, AdrSrc, ALUControl, IRWrite, PCWrite, RegWrite, MemWrite);
  
  // generate clock
  always 
    begin
      clk = 1; #5; clk = 0; #5;
    end

  // at start of test, load vectors and pulse reset
  initial
    begin
      $dumpfile("controller.vcd");
      $dumpvars(0, dut);

      $readmemb("controller.tv", testvectors);
      vectornum = 0; errors = 0; hash = 0;
      reset = 1; #22; reset = 0;
    end
	 
  // apply test vectors on rising edge of clk
  always @(posedge clk)
    begin
      #1; {op, funct3, funct7b5, Zero, expected} = testvectors[vectornum];
    end

  // check results on falling edge of clk
  always @(negedge clk)
    if (~reset) begin // skip cycles during reset
      new_error=0; 

      if ((ImmSrc!==expected[15:14])&&(expected[15:14]!==2'bxx))  begin
        $display("   ImmSrc = %b      Expected %b", ImmSrc,     expected[15:14]);
        new_error=1;
      end
      if ((ALUSrcA!==expected[13:12])&&(expected[13:12]!==2'bxx)) begin
        $display("   ALUSrcA = %b     Expected %b", ALUSrcA,    expected[13:12]);
        new_error=1;
      end
      if ((ALUSrcB!==expected[11:10])&&(expected[11:10]!==2'bxx)) begin
        $display("   ALUSrcB = %b     Expected %b", ALUSrcB,    expected[11:10]);
        new_error=1;
      end
      if ((ResultSrc!==expected[9:8])&&(expected[9:8]!==2'bxx))   begin
        $display("   ResultSrc = %b   Expected %b", ResultSrc,  expected[9:8]);
        new_error=1;
      end
      if ((AdrSrc!==expected[7])&&(expected[7]!==1'bx))           begin
        $display("   AdrSrc = %b       Expected %b", AdrSrc,     expected[7]);
        new_error=1;
      end
      if ((ALUControl!==expected[6:4])&&(expected[6:4]!==3'bxxx)) begin
        $display("   ALUControl = %b Expected %b", ALUControl, expected[6:4]);
        new_error=1;
      end
      if ((IRWrite!==expected[3])&&(expected[3]!==1'bx))          begin
        $display("   IRWrite = %b      Expected %b", IRWrite,    expected[3]);
        new_error=1;
      end
      if ((PCWrite!==expected[2])&&(expected[2]!==1'bx))          begin
        $display("   PCWrite = %b      Expected %b", PCWrite,    expected[2]);
        new_error=1;
      end
      if ((RegWrite!==expected[1])&&(expected[1]!==1'bx))         begin
        $display("   RegWrite = %b     Expected %b", RegWrite,   expected[1]);
        new_error=1;
      end
      if ((MemWrite!==expected[0])&&(expected[0]!==1'bx))         begin
        $display("   MemWrite = %b     Expected %b", MemWrite,   expected[0]);
        new_error=1;
      end

      if (new_error) begin
        $display("Error on vector %d: inputs: op = %h funct3 = %h funct7b5 = %h", vectornum, op, funct3, funct7b5);
        errors = errors + 1;
      end
      vectornum = vectornum + 1;
      hash = hash ^ {ImmSrc&{2{expected[15:14]!==2'bxx}}, ALUSrcA&{2{expected[13:12]!==2'bxx}}} ^ {ALUSrcB&{2{expected[11:10]!==2'bxx}}, ResultSrc&{2{expected[9:8]!==2'bxx}}} ^ {AdrSrc&{expected[7]!==1'bx}, ALUControl&{3{expected[6:4]!==3'bxxx}}} ^ {IRWrite&{expected[3]!==1'bx}, PCWrite&{expected[2]!==1'bx}, RegWrite&{expected[1]!==1'bx}, MemWrite&{expected[0]!==1'bx}};
      hash = {hash[5:0], hash[6] ^ hash[5]};
      if (testvectors[vectornum] === 40'bx) begin 
        $display("%d tests completed with %d errors", vectornum, errors);
	      $display("hash = %h", hash);
        $stop;
      end
    end
endmodule