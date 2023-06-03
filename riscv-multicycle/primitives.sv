module flop   #(parameter N = 1)
               (input  logic           clk,
                input  logic [N - 1:0] data,
                output logic [N - 1:0] out);
  always_ff @(posedge clk)
    out <= data;
endmodule

module flopr  #(parameter N = 1)
               (input  logic           clk,
                input  logic           reset,
                input  logic [N - 1:0] data,
                output logic [N - 1:0] out);
  always_ff @(posedge clk or posedge reset)
    if (reset) out <= 0;
    else       out <= data;
endmodule

module flopen #(parameter N = 1)
               (input  logic           clk,
                input  logic           enable,
                input  logic [N - 1:0] data,
                output logic [N - 1:0] out);
  always_ff @(posedge clk)
    if (enable) out <= data;
    else        out <= out;
endmodule

module flopenr #(parameter N = 1)
                (input  logic           clk,
                 input  logic           reset,
                 input  logic           enable,
                 input  logic [N - 1:0] data,
                 output logic [N - 1:0] out);
  always_ff @(posedge clk or posedge reset)
    if (reset)  out <= 0;
    else
      begin
        if (enable) out <= data;
        else        out <= out;
      end
endmodule

module mux2 #(parameter WIDTH = 32)
             (input  logic [WIDTH-1:0] d0, d1, 
              input  logic             s, 
              output logic [WIDTH-1:0] y);

  assign y = s ? d1 : d0; 
endmodule

module mux3 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, d2,
              input  logic [1:0]       s, 
              output logic [WIDTH-1:0] y);

  assign y = s[1] ? d2 : (s[0] ? d1 : d0); 
endmodule