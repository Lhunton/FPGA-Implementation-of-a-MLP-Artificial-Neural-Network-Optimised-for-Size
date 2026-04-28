`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
// 
// Create Date:    19:47:43 11/29/2025 
// Design Name: 
// Module Name:    BaughWooley_Multiplier_8bit 
// Project Name: FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Devices: XC3S1500 Spartan-3
// Tool versions: Xilinx 14.2
// Description: Baugh-Wooley Multiplier
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module BaughWooley_Multiplier_8bit(
    input signed [7:0] A,
    input signed [7:0] B,
	 input Clk,
	 input Enable,
    output reg [15:0] Product,
	 output reg Valid
    );

	wire [7:0] partialProducts [7:0]; //makes 8 partial products each 8 bits long

genvar i, j;
generate
	for (i = 0; i < 8; i = i + 1) begin : PartialProductRow
		for (j = 0; j < 8; j = j + 1) begin : PartialProductCol
			if (i == 7 && j < 7) begin
				assign partialProducts[i][j] = ~(A[7] & B[j]); //last row except last bit
			end
			else if (i < 7 && j == 7) begin
				assign partialProducts[i][j] = ~(A[i] & B[7]); //last COL except last bit
			end
			else if (i == 7 && j == 7) begin
				assign partialProducts[i][j] = (A[i] & B[j]); //Bottom corner  of array
			end
			else begin
				assign partialProducts[i][j] = (A[i] & B[j]); //nominal position AND
			end
		end
	end
endgenerate

wire [15:0] Shifted [7:0];

generate
    for (i = 0; i < 8; i = i + 1) begin : ShiftedRows
        wire [7:0] row;
        for (j = 0; j < 8; j = j + 1) begin : AssignBits
            assign row[j] = partialProducts[i][j];
        end
        assign Shifted[i] = {8'b0, row} << i;
    end
endgenerate

wire signed [15:0] intermediaryOne [3:0];
wire signed [15:0] intermediaryTwo [1:0];
wire signed [15:0] intermediaryThree;

assign intermediaryOne[0] = Shifted[0] + Shifted[1];
assign intermediaryOne[1] = Shifted[2] + Shifted[3];
assign intermediaryOne[2] = Shifted[4] + Shifted[5];
assign intermediaryOne[3] = Shifted[6] + Shifted[7];

assign intermediaryTwo[0] = intermediaryOne[0] + intermediaryOne[1];
assign intermediaryTwo[1] = intermediaryOne[2] + intermediaryOne[3];

assign intermediaryThree = intermediaryTwo[0] + intermediaryTwo[1];

wire [15:0] correctionBit = 16'b1000000100000000;
wire signed [15:0] ProductWire = intermediaryThree + correctionBit;

always@(posedge Clk) begin
	Valid <= Enable;
	if(Enable)
		Product <= ProductWire;
end

endmodule
