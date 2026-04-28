`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
// 
// Create Date:    18:52:47 02/28/2026 
// Design Name: 
// Module Name:    InputAdapter 
// Project Name: FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Devices: XC3S1500 Spartan-3
// Tool versions: Xilinx 14.2
// Description: Input Adapter
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module InputAdapter(
	input wire SelectMode, //1 = Scratchpad, 0 = InputBuffer
	input wire [3:0] DataInput,
	input wire [63:0] ScratchpadData, // Repurposes this as also a MUX for switching inputs to MAC for layer 2
	output reg [63:0] MACInputBus,
	input wire [3:0] Cycle
    );

wire [7:0] Extended4 = {4'b0, DataInput};
reg [7:0] HiddenValue;
reg [7:0] ScaledInput;

//4-bit scaling LUT
always @(*) begin
	case (DataInput)
		4'd0: ScaledInput = 8'h00;
		4'd1: ScaledInput = 8'h09;
		4'd2: ScaledInput = 8'h11;
		4'd3: ScaledInput = 8'h1A;
		4'd4: ScaledInput = 8'h22;
		4'd5: ScaledInput = 8'h2B;
		4'd6: ScaledInput = 8'h33;
		4'd7: ScaledInput = 8'h3C;
		4'd8: ScaledInput = 8'h44;
		4'd9: ScaledInput = 8'h4D;
		4'd10: ScaledInput = 8'h55;
		4'd11: ScaledInput = 8'h5E;
		4'd12: ScaledInput = 8'h66;
		4'd13: ScaledInput = 8'h6F;
		4'd14: ScaledInput = 8'h77;
		4'd15: ScaledInput = 8'h7F;
		default: ScaledInput = 8'h00;
	endcase
end


always @(*) begin
	if(SelectMode) begin
		HiddenValue = ScratchpadData[(Cycle[2:0] * 8) +: 8];
	
		MACInputBus = {HiddenValue, HiddenValue, HiddenValue, HiddenValue, HiddenValue, HiddenValue, HiddenValue, HiddenValue}; //If Selectmode = 1, then Scratchpad 64bit goes straight to mac input
	end else begin
		MACInputBus = {ScaledInput, ScaledInput, ScaledInput, ScaledInput, ScaledInput, ScaledInput, ScaledInput, ScaledInput};
	end
end

endmodule
