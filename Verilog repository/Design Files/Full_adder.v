`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
// 
// Create Date:    18:04:38 11/29/2025 
// Design Name: 
// Module Name:    Full_adder 
// Project Name: FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Devices: XC3S1500 Spartan-3
// Tool versions: Xilinx 14.2
// Description: Full Adder
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Full_adder(
    input A,
    input B,
    input Cin,
    output Sum,
    output Cout
    );
	 
	 assign Sum = A ^ B ^ Cin;
	 assign Cout = (A & B) | (A & Cin) | (B & Cin);


endmodule
