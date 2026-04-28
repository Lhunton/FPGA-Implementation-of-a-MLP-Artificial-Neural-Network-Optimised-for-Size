`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
// 
// Create Date:    00:10:32 11/30/2025 
// Design Name: 
// Module Name:    MAC_Accumulator_64_16bit 
// Project Name: FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Devices: XC3S1500 Spartan-3
// Tool versions: Xilinx 14.2
// Description: MAC Accumulator
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module MAC_Accumulator_64_16bit #(
	parameter WIDTH = 22,
	parameter COUNTW = 16
)(
    input Clk,
    input Reset,
    input Enable,
    input Clear,
	 input MultiplierValid,
    input signed [15:0] In,
	 input [15:0] CountConfigure,
    output reg signed [21:0] Output,
    output reg Valid
    );

reg signed [21:0] Accumulator;
reg [15:0] Count;

always@(posedge Clk) begin
	if(Reset || Clear) begin
		Accumulator <= 22'b0;
		Count <= 16'b0;
		Output <= 22'b0;
		Valid <= 1'b0;
	end
	else if (MultiplierValid) begin
		if(Count == CountConfigure -1) begin
			Output <= Accumulator + In;
			Accumulator <= 22'b0;
			Count <= 16'b0;
			Valid <= 1'b1;
		end else begin
			Accumulator <= Accumulator + In;
			Count <= Count + 1'b1;
			Valid <= 1'b0;
		end
	end
	else begin
		Valid <= 1'b0;
	end
end

endmodule