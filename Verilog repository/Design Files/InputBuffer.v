`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
// 
// Create Date:    00:15:17 02/27/2026 
// Design Name: 
// Module Name:    InputBuffer 
// Project Name: FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Devices: XC3S1500 Spartan-3
// Tool versions: Xilinx 14.2
// Description: Input Buffer
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module InputBuffer #(
	parameter W = 4,
	parameter N = 64,
	parameter DoubleBuffer = 0
)(
	input wire Clk,
	input wire Reset,
	
	//Host write controls (python stuff)
	input wire WriteValid,
	input wire [W-1:0] WriteData,
	output wire WriteReady,
	input wire Commit,
	
	output reg BufferFull,
	
	
	//MAC read side (on fpga)
	input wire ReadEnable,
	input wire [5:0] ReadAddress,
	output reg [W-1:0] ReadData,
	
	output reg [5:0] WriteIndex
    );
	 
	 reg [5:0] WriteCount;
	 reg Loaded;
	 
	 reg [W-1:0] Memory [0:N-1];
	 
	 reg WriteACK;
	 
	 assign WriteReady = WriteACK;
	 
	 integer i;
	 always @ (posedge Clk) begin
		if (Reset) begin
			WriteCount <= 6'd0;
			Loaded <= 1'b0;
			BufferFull <= 1'b0;
			WriteIndex <= 0;
			WriteACK <= 0;
		end else begin
			WriteACK <= 0;
		
			if (WriteValid && !BufferFull) begin
				Memory[WriteIndex] <= WriteData;
				WriteIndex <= WriteIndex + 6'd1;
				
				WriteACK <= 1;
				
				if (WriteIndex == N-1)
					Loaded <= 1'b1;
			end
			if (Commit && Loaded) begin
				BufferFull <= 1'b1;
			end
			//Clears flags when compute side consumes
			//external logic should clear via reset
		end
	end
			
	always @ (posedge Clk) begin
		if(ReadEnable) begin
			ReadData <= Memory[ReadAddress];
		end
	end

endmodule
