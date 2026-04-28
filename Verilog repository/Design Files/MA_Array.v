`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
// 
// Create Date:    17:36:45 12/07/2025 
// Design Name: 
// Module Name:    MA_Array 
// Project Name: FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Devices: XC3S1500 Spartan-3
// Tool versions: Xilinx 14.2
// Description: MAC Array
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module MA_Array(
	input Clk,
   input Reset,
   input Enable,
	input Clear,
   input signed [63:0] Input,
   input signed [63:0] Weight,
   input [15:0] CountConfigure,
   output signed [63:0] MACOut,
   output [7:0] Valid,
	output AllValid
);

genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin : MACArray
        MAC_Unit MAC(
            .Clk(Clk),
            .Reset(Reset),
            .Enable(Enable),
            .Clear(Clear),
            .A(Input[i*8 +: 8]),
            .B(Weight[i*8 +: 8]),
            .CountConfigure(CountConfigure),
            .Output(MACOut[i*8 +: 8]),
            .Valid(Valid[i])
        );

    end
endgenerate

assign AllValid = &Valid;

endmodule