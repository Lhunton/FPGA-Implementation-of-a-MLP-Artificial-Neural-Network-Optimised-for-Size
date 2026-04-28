`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
// 
// Create Date:    16:56:39 12/14/2025 
// Design Name: 
// Module Name:    Activation_Function_Block 
// Project Name: FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Devices: XC3S1500 Spartan-3
// Tool versions: Xilinx 14.2
// Description: ReLU block
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Activation_Function_Block(
    input Clk,
    input Reset,
    input wire signed [63:0] Input,
    output reg signed[63:0] Output
    );

integer i;
reg signed [7:0] Lane;
reg signed [63:0] ReLURecombined;

always @(*) begin
	for (i = 0; i < 8; i = i + 1) begin
		Lane = Input[i*8 +: 8];
		ReLURecombined[i*8 +: 8] = (Lane < 0) ? 8'sd0 : Lane;
	end
end

always @(posedge Clk) begin
	if(Reset)
		Output <= 64'd0;
	else 
		Output <= ReLURecombined;
end

endmodule
