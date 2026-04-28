`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
// 
// Create Date:    21:20:48 12/07/2025 
// Design Name: 
// Module Name:    Adder_Array_RCA_8bit 
// Project Name: FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Devices: XC3S1500 Spartan-3
// Tool versions: Xilinx 14.2
// Description: Adder Array
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Adder_Array_RCA_8bit(
    input [63:0] A,
	 input [63:0] B,
    input [7:0] Cin,
    output [63:0] Sum,
	 output [7:0] Cout
    );
	 
genvar i;
generate 
	for(i = 0; i < 8; i = i + 1) begin : adders
		Ripple_Carry_Adder_8bit Adder(
			.A(A[i*8 +: 8]),
			.B(B[i*8 +: 8]),
			.Cin(Cin[i]),
			.Sum(Sum[i*8 +: 8]),
			.Cout(Cout[i])
		);
	end
endgenerate


endmodule
