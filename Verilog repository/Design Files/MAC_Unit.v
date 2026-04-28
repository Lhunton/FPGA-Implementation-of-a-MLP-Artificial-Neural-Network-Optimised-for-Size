`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
// 
// Create Date:    03:03:49 11/30/2025 
// Design Name: 
// Module Name:    MAC_Unit 
// Project Name: FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Devices: XC3S1500 Spartan-3
// Tool versions: Xilinx 14.2
// Description: MAC Unit
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module MAC_Unit(
    input Clk,
    input Reset,
    input Enable,
    input Clear,
    input signed [7:0] A,
    input signed [7:0] B,
	 input [15:0] CountConfigure,
    output signed [7:0] Output,
    output Valid
    );

wire [15:0] MultiplierOutWire;
wire [21:0] AccumulatorOutWire;
wire MultiplierValid;
wire AccumulatorValid;

BaughWooley_Multiplier_8bit Multiplier(
	.Clk(Clk),
	.A(A),
	.B(B),
	.Enable(Enable),
	.Product(MultiplierOutWire),
	.Valid(MultiplierValid)
);

MAC_Accumulator_64_16bit Accumulator(
	.Clk(Clk),
	.Reset(Reset),
	.Enable(Enable),
	.Clear(Clear),
	.MultiplierValid(MultiplierValid),
	.In(MultiplierOutWire),
	.CountConfigure(CountConfigure),
	.Output(AccumulatorOutWire),
	.Valid(AccumulatorValid)
);

Requantiser_22to8bit Requantiser(
	.Clk(Clk),
	.Reset(Reset),
	.Enable(AccumulatorValid),
	.Input(AccumulatorOutWire),
	.Output(Output),
	.Valid(Valid)
);



endmodule
