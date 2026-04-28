`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
// 
// Create Date:    20:57:39 11/29/2025 
// Design Name: 
// Module Name:    Ripple_Carry_Adder_8bit 
// Project Name: FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Devices: XC3S1500 Spartan-3
// Tool versions: Xilinx 14.2
// Description: Ripple Carry Adder
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Ripple_Carry_Adder_8bit(
    input [7:0] A,
    input [7:0] B,
    input Cin,
    output [7:0] Sum,
    output Cout
    );

wire [7:0] Carry;

//initial adder
Full_adder FA0(
	.A(A[0]),
	.B(B[0]),
	.Cin(Cin),
	.Sum(Sum[0]),
	.Cout(Carry[0])
);

//intermediary steps
genvar i;
generate
	for (i = 1; i < 7; i = i + 1) begin : intermediary_Adders
		Full_adder fa(
			.A(A[i]),
			.B(B[i]),
			.Cin(Carry[i-1]),
			.Sum(Sum[i]),
			.Cout(Carry[i])
		);
	end
endgenerate

//last stage adder
Full_adder fa8(
	.A(A[7]),
	.B(B[7]),
	.Cin(Carry[6]),
	.Sum(Sum[7]),
	.Cout(Cout)
);

endmodule
