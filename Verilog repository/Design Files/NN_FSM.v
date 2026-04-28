`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
// 
// Create Date:    10:01:27 03/01/2026 
// Design Name: 
// Module Name:    NN_FSM 
// Project Name: FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Devices: XC3S1500 Spartan-3
// Tool versions: Xilinx 14.2
// Description: Finite State Machine
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module NN_FSM(
	input wire Clk,
	input wire Reset,
	
	output reg ReadEnable,
	output reg [5:0] ReadAddress,
	input wire [3:0] ReadData,
	
	output reg ScratchpadWriteEnable,
	output reg [4:0] ScratchpadWriteAddress,
	output reg [4:0] ScratchpadReadAddress,
	input wire [63:0] ScratchpadReadData,
	
	output reg SelectMode, // 0 = input buffer, 1 = scratchpad	

	output reg MACEnable,
	output reg MACClear,
	input wire [7:0] MACOutValid,
	
	output reg [7:0] WeightAddress,
	output reg [7:0] BiasAddress,
	
	output reg [15:0] CountConfigure,
	
	input wire [63:0] ReLUOut,
	
	output reg Done,
	
	output wire [3:0] Cycle,
	
	output reg ArgmaxValidIn,
	output reg [79:0] ArgmaxDataIn,
	input wire ArgmaxDone,
	input wire AllValid,
	
	output wire [3:0] DebugState
    );

//fsm state declares
localparam [6:0] StateReset = 6'd0;
localparam [6:0] StateLoadInputs = 6'd1;
localparam [6:0] StateWaitCommit = 6'd2;
	
localparam [6:0] StateHiddenStart = 6'd3;
localparam [6:0] StateHiddenWait = 6'd23;
localparam [6:0] StateHiddenMAC = 6'd4;
localparam [6:0] StateHiddenStore = 6'd5;
localparam [6:0] StateHiddenClear = 6'd6;
localparam [6:0] StateHiddenNext = 6'd7;
localparam [6:0] StateHiddenDone = 6'd8;
	
localparam [6:0] StateOutputStart = 6'd9;
localparam [6:0] StateOutputWait = 6'd24;
localparam [6:0] StateOutputMAC = 6'd10;
localparam [6:0] StateOutputStore = 6'd11;
localparam [6:0] StateOutputClear = 6'd12;
localparam [6:0] StateOutputNext = 6'd13;
	
localparam [6:0] StateOutputDone = 6'd14;

//argmax states
localparam [6:0] StateArgReadSP2 = 6'd15;
localparam [6:0] StateArgWaitSP2 = 6'd16;
localparam [6:0] StateArgReadSP3 = 6'd17;
localparam [6:0] StateArgWaitSP3 = 6'd18;
localparam [6:0] StateArgPacked = 6'd19;
localparam [6:0] StateArgStart = 6'd20;
localparam [6:0] StateArgWait = 6'd21;
localparam [6:0] StateArgDone = 6'd22;


reg [4:0] State;
reg [4:0] StateNext;

//internal counters
reg [5:0] InputIdx; //0-63
reg [3:0] HiddenBlock; //0-8
reg [4:0] OutputBlock;
reg [4:0] WritePointer;
reg [4:0] ReadPointer; 
reg [3:0] CycleCount;
assign Cycle = CycleCount;

assign DebugState = State;

wire [7:0] HiddenBaseAddress = (HiddenBlock == 0) ? 8'd0 : 8'd64;
wire [7:0] OutputBaseAddress = (OutputBlock == 0) ? 8'd128 : 8'd144;

always @(posedge Clk) begin
	if (Reset || State == StateOutputStart || State == StateHiddenStart)
		CycleCount <= 0;
	else if (State == StateOutputMAC || State == StateHiddenMAC)
		CycleCount <= CycleCount + 1;
end

//argmax handling
reg [63:0] OutLowBits;
reg [15:0] OutHighBits;
reg [5:0] Offset;

//State change register
always @(posedge Clk) begin
	if (Reset)
		State <= StateReset;
	else
		State <= StateNext;
end

reg MACDone;
reg [7:0] MACSeen;

always @(posedge Clk) begin
	if(Reset || State == StateHiddenStart || State == StateOutputStart || State == StateHiddenClear || State == StateOutputClear) begin
		MACDone <= 1'b0;
		MACSeen <= 8'b0;
	end else begin
		MACSeen <= MACSeen | MACOutValid;
		if (&MACSeen)
			MACDone <= 1'b1;
	end
end

//Next state logic
always @(*) begin
	StateNext = State;
	
	case (State)
	
		StateReset:
			StateNext = StateLoadInputs;
				
		StateLoadInputs:
			if (InputIdx == 6'd63)
				StateNext = StateWaitCommit;
		
		StateWaitCommit:
			if (1'b1)
				StateNext = StateHiddenStart;
				
		//Hidden layer states
		StateHiddenStart:
			StateNext = StateHiddenWait;
			
		StateHiddenWait:
			StateNext = StateHiddenMAC;
			
		StateHiddenMAC:
			if (MACDone)
				StateNext = StateHiddenStore;
			else
				StateNext = StateHiddenMAC;
				
		StateHiddenStore:
			StateNext = StateHiddenClear;
			
		StateHiddenClear:
			StateNext = StateHiddenNext;
			
		StateHiddenNext:
			if (HiddenBlock == 0)
				StateNext = StateHiddenStart;
			else
				StateNext = StateHiddenDone;
				
		StateHiddenDone:
			StateNext = StateOutputStart;
			
		//Output layer states
		StateOutputStart:
			StateNext = StateOutputWait;
			
		StateOutputWait:
			StateNext = StateOutputMAC;
			
		StateOutputMAC:
			if (MACDone)
				StateNext = StateOutputStore;
			else
				StateNext = StateOutputMAC;
				
		StateOutputStore:
			StateNext = StateOutputClear;
			
		StateOutputClear:
			StateNext = StateOutputNext;
			
		StateOutputNext:
			if (OutputBlock == 0)
				StateNext = StateOutputStart;
			else
				StateNext = StateOutputDone;
				
		StateOutputDone:
			StateNext = StateArgReadSP2;
			
		StateArgReadSP2:
			StateNext = StateArgWaitSP2;
			
		StateArgWaitSP2:
			StateNext = StateArgReadSP3;
			
		StateArgReadSP3:
			StateNext = StateArgWaitSP3;
		
		StateArgWaitSP3:
			StateNext = StateArgPacked;
			
		StateArgPacked:
			StateNext = StateArgStart;
			
		StateArgStart:
			StateNext = StateArgWait;
			
		StateArgWait:
			if (ArgmaxDone)
				StateNext = StateArgDone;
			else
				StateNext = StateArgWait;
			
		StateArgDone:
			StateNext = StateArgDone;
		
		default: 
			StateNext = StateReset;
		
		
	endcase
end

//Output logic
always @(posedge Clk) begin
	if(Reset) begin
		InputIdx <= 0;
		HiddenBlock <= 0;
		OutputBlock <= 0;
		
		ReadEnable <= 0;
		ReadAddress <= 0;
		
		MACEnable <= 0;
		MACClear <= 1;
		
		SelectMode <= 0;
		
		WritePointer <= 0;
		ReadPointer <= 0;
		
		ScratchpadWriteEnable <= 0;
		ScratchpadWriteAddress <= 0;
		ScratchpadReadAddress <= 0;
		
		WeightAddress <= 0;
		BiasAddress <= 160;
		
		Done <= 0;
		
		CountConfigure <= 16'd64;
		
		OutLowBits <= 0;
		OutHighBits <= 0;
		
		ArgmaxValidIn <= 0;
		ArgmaxDataIn <= 0;
	end else begin
		ScratchpadWriteEnable <= 0;
		
		CountConfigure <= CountConfigure;
		MACEnable <= MACEnable;
		MACClear <= MACClear;
		
		case (State)
			
			//Input laoding
			StateLoadInputs: begin
				ReadEnable <= 1;
				ReadAddress <= InputIdx;
				SelectMode <= 0; //input buffer mode
				
				if (InputIdx != 63)
					InputIdx <= InputIdx + 1;
			end
			
			StateWaitCommit: begin
				//MACClear <= 1;
			end
			
			//hidden layer
			StateHiddenStart: begin
				MACClear <= 1'b1;
				SelectMode <= 0; // input buffer mode
				MACEnable <= 1'b0;
				CountConfigure <= 16'd64;
				
				WeightAddress <= HiddenBaseAddress;
				Offset <= 0;
			end
			
			StateHiddenMAC: begin
				MACClear <= 1'b0;
				MACEnable <= 1'b1;
				
				if (CycleCount <63) begin
					WeightAddress <= WeightAddress + 1;
					Offset <= Offset + 1;
				end
				
				BiasAddress <= 160 + HiddenBlock;
			end
			
			StateHiddenStore: begin
				MACEnable <= 1'b0;
				ScratchpadWriteEnable <= 1'b1;
				ScratchpadWriteAddress <= WritePointer;
				WritePointer <= WritePointer + 1;
			end
			
			StateHiddenClear: begin
				MACClear <= 1'b1;
			end
			
			StateHiddenNext: begin
				HiddenBlock <= HiddenBlock + 1;
			end
			
			//output layer
			StateOutputStart: begin
				SelectMode <= 1; //Scratchpad mode
				ReadPointer <= 0;
				MACClear <= 1;
				MACEnable <= 1'b0;
				CountConfigure <= 16'd16;
				
				WeightAddress <= OutputBaseAddress;
				Offset <= 0;
			end
			
			StateOutputMAC: begin
				MACClear <= 0;
				MACEnable <= 1;
				
				
				ScratchpadReadAddress <= (CycleCount < 8) ? 0 : 1;
				
				if (CycleCount < 15) begin
					WeightAddress <= WeightAddress + 1;
					Offset <= Offset + 1;
				end
				
				BiasAddress <= 162 + OutputBlock;
			end
			
			StateOutputStore: begin
				MACEnable <= 1'b0;
				ScratchpadWriteEnable <= 1;
				ScratchpadWriteAddress <= WritePointer;
				WritePointer <= WritePointer + 1;
			end
			
			StateOutputClear: begin
				MACClear <= 1'b1;
			end
			
			StateOutputNext: begin
				MACEnable <= 0;
				OutputBlock <= OutputBlock + 1;
			end
			
			StateOutputDone: begin
				MACEnable <= 0;
			end
			
			StateArgReadSP2: begin
				ScratchpadReadAddress <= 5'd2;
			end
			
			StateArgWaitSP2: begin
				OutLowBits <= ScratchpadReadData;
			end
			
			StateArgReadSP3: begin
				ScratchpadReadAddress <= 5'd3;
			end
			
			StateArgWaitSP3: begin
				OutHighBits <= ScratchpadReadData;
			end
			
			StateArgPacked: begin
				ArgmaxDataIn <= {OutHighBits, OutLowBits};
			end
			
			StateArgStart: begin
				ArgmaxValidIn <= 1'b1;
			end
			
			StateArgDone: begin
				Done <= 1;
			end
			
		endcase
	end
end

endmodule
