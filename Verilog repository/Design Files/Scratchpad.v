`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
// 
// Create Date:    00:50:48 02/27/2026 
// Design Name: 
// Module Name:    Scratchpad 
// Project Name: FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Devices: XC3S1500 Spartan-3
// Tool versions: Xilinx 14.2
// Description: Scratchpad
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Scratchpad(
	input wire Clk,
	input wire Reset,
	
	input wire WriteEnable, 
	input wire [4:0] WriteAddress,
	input wire [63:0] WriteData,
	
	input wire [4:0] ReadAddress,
	output wire [63:0] ReadData
    );

	reg [63:0] ScratchPadMemory [0:31];
	reg toggle; 
	
	integer i;
	
	always @ (posedge Clk) begin
		if (Reset) begin
			for (i=0 ; i<32; i = i + 1)
				ScratchPadMemory[i] <= 64'd0;
				
		end else if (WriteEnable) begin
			ScratchPadMemory[WriteAddress] <= WriteData;
		end
	end
			
	assign ReadData = ScratchPadMemory[ReadAddress];
		
endmodule
