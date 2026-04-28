`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
// 
// Create Date:    02:47:06 12/15/2025 
// Design Name: 
// Module Name:    Argmaax_output 
// Project Name: FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Devices: XC3S1500 Spartan-3
// Tool versions: Xilinx 14.2
// Description: Argmax block
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Argmaax_output(
    input wire Clk,
    input wire Reset,

	 input wire ValidIn,
	 input wire [79:0] DataIn,
	 
	 output reg [3:0] Output,
	 output reg Valid
    );

reg [7:0] Stage1Max [0:4];
reg [3:0] Stage1Idx [0:4];
reg [79:0] Stage1Data;

reg Stage1Valid;

reg [7:0] Stage2Max [0:2];
reg [3:0] Stage2Idx [0:2];

reg Stage2Valid;

reg [7:0] Stage3Max [0:1];
reg [3:0] Stage3Idx [0:1];

reg Stage3Valid;

reg [7:0] Stage4Max;
reg [3:0] Stage4Idx;

reg Stage4Valid;

integer i;

always @(posedge Clk) begin
	if(Reset) begin
		Stage1Valid <= 1'b0;
        for(i = 0; i < 5; i = i + 1) begin
            Stage1Max[i] <= 8'b0;
            Stage1Idx[i] <= 4'b0;
        end
	end else begin
		Stage1Valid <= ValidIn;
		Stage1Data <= DataIn;
		
		if (ValidIn) begin
		//Pair 1
			if(DataIn[7:0] > DataIn[15:8]) begin
                Stage1Max[0] <= DataIn[7:0];
                Stage1Idx[0] <= 4'd0;
            end else begin
                Stage1Max[0] <= DataIn[15:8];
                Stage1Idx[0] <= 4'd1;
            end
				
		//pair 2
			if(DataIn[23:16] > DataIn[31:24]) begin
                Stage1Max[1] <= DataIn[23:16];
                Stage1Idx[1] <= 4'd2;
            end else begin
                Stage1Max[1] <= DataIn[31:24];
                Stage1Idx[1] <= 4'd3;
            end
				
			//pair 3
			if(DataIn[39:32] > DataIn[47:40]) begin
                Stage1Max[2] <= DataIn[39:32];
                Stage1Idx[2] <= 4'd4;
            end else begin
                Stage1Max[2] <= DataIn[47:40];
                Stage1Idx[2] <= 4'd5;
            end
			
			//pair 4
			if(DataIn[55:48] > DataIn[63:56]) begin
                Stage1Max[3] <= DataIn[55:48];
                Stage1Idx[3] <= 4'd6;
            end else begin
                Stage1Max[3] <= DataIn[63:56];
                Stage1Idx[3] <= 4'd7;
            end
			
			//pair 5
			if(DataIn[71:64] > DataIn[79:72]) begin
                Stage1Max[4] <= DataIn[71:64];
                Stage1Idx[4] <= 4'd8;
            end else begin
                Stage1Max[4] <= DataIn[79:72];
                Stage1Idx[4] <= 4'd9;
            end
			end
		end
	end


always @(posedge Clk) begin
	if(Reset) begin
		Stage2Valid <= 1'b0;
        for(i = 0; i < 3; i = i + 1) begin
            Stage2Max[i] <= 8'b0;
            Stage2Idx[i] <= 4'b0;
        end
	end else begin
		Stage2Valid <= Stage1Valid;
		
		if (Stage1Valid) begin
			if(Stage1Max[0] > Stage1Max[1]) begin
				Stage2Max[0] <= Stage1Max[0];
            Stage2Idx[0] <= Stage1Idx[0];
         end else begin
            Stage2Max[0] <= Stage1Max[1];
				Stage2Idx[0] <= Stage1Idx[1];
         end
				
			if(Stage1Max[2] > Stage1Max[3]) begin
            Stage2Max[1] <= Stage1Max[2];
            Stage2Idx[1] <= Stage1Idx[2];
         end else begin
            Stage2Max[1] <= Stage1Max[3];
            Stage2Idx[1] <= Stage1Idx[3];
         end
				
			Stage2Max[2] <= Stage1Max[4];
			Stage2Idx[2] <= Stage1Idx[4];
		end
	end
end

always @(posedge Clk) begin
	if(Reset) begin
		Stage3Valid <= 1'b0;
        for(i = 0; i < 2; i = i + 1) begin
            Stage3Max[i] <= 8'b0;
            Stage3Idx[i] <= 4'b0;
        end
	end else begin
		Stage3Valid <= Stage2Valid;
		
		if (Stage2Valid) begin
			if(Stage2Max[0] > Stage2Max[1]) begin
				Stage3Max[0] <= Stage2Max[0];
            Stage3Idx[0] <= Stage2Idx[0];
         end else begin
            Stage3Max[0] <= Stage2Max[1];
				Stage3Idx[0] <= Stage2Idx[1];
         end
				
			Stage3Max[1] <= Stage2Max[2];
			Stage3Idx[1] <= Stage2Idx[2];
		end
	end
end

always @(posedge Clk) begin
	if(Reset) begin
		Stage4Valid <= 1'b0;
		Stage4Max <= 8'b0;
		Stage4Idx <= 4'b0;
	end else begin
		Stage4Valid <= Stage3Valid;
		
		if (Stage3Valid) begin
			if(Stage3Max[0] > Stage3Max[1]) begin
				Stage4Max <= Stage3Max[0];
            Stage4Idx <= Stage3Idx[0];
         end else begin
            Stage4Max <= Stage3Max[1];
				Stage4Idx <= Stage3Idx[1];
         end
		end
	end
end

always @(posedge Clk) begin
	if(Reset) begin
		Output <= 4'b0;
		Valid <= 1'b0;
	end else begin
		Output <= Stage4Idx;
		Valid <= Stage4Valid;
	end
end

endmodule