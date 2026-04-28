`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
// 
// Create Date:    02:51:58 11/30/2025 
// Design Name: 
// Module Name:    Requantiser_22to8bit 
// Project Name: FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Devices: XC3S1500 Spartan-3
// Tool versions: Xilinx 14.2
// Description: Requnatiser
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Requantiser_22to8bit(
    input Clk,
    input Reset,
    input Enable,
    input signed [21:0] Input,
    output reg signed [7:0] Output,
    output reg Valid
    );
	 
	localparam Shift = 11; 
	
	wire signed [21:0] InputShifted;
	wire signed [21:0] RoundedInput;
	
	assign RoundedInput = Input + 22'sd64;
	assign InputShifted = RoundedInput >>> Shift;
	
	always @(posedge Clk) begin
		if (Reset) begin
			Output <= 8'sd0;
			Valid <= 1'b0;
		end
		else if (Enable) begin
			if(InputShifted > 127)
				Output <= 8'sd127;
			else if (InputShifted < -128)
				Output <= -8'sd128;
			else 
				Output <= InputShifted[7:0];
				
			Valid <= 1'b1;
		end
		else begin
			Valid <= 1'b0;
		end
	end

endmodule
