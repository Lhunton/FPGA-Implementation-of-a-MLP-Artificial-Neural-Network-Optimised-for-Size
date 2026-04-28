`timescale 1ns/1ps
////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
//
// Create Date:   --/--
// Design Name:   TopLevelNN_tb
// Module Name:   /home/ise/CompleteNeuralNetworkV2/TopLevelNN_tb.v
// Project Name:  FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Device:  XC3S1500 Spartan-3
// Tool versions:  Xilinx 14.2
// Description: Top Level Test Bench
//
// Verilog Test Fixture created by ISE for module: TopLevel.v
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////
module TopLevelNN_tb;

	//Clk and reset
    reg Clk = 0;
    always #5 Clk = ~Clk;   // 100 MHz clock

    reg Reset = 1;
    initial begin
        #40 Reset = 0;
    end

	//dut inputs
    reg WriteValid = 0;
    reg [3:0] WriteData = 0;
    reg Commit = 0;

	//dut outputs
    wire Done;
	 wire [3:0] Classification;
	 wire ClassificationValid;
	 wire [3:0] DebugFSMState;
	 wire WriteReady;

	//instantation
    TopLevelNN DUT (
        .Clk(Clk),
        .Reset(Reset),
        .WriteValid(WriteValid),
        .WriteData(WriteData),
        .Commit(Commit),
		  
        .DoneSignal(Done),
		  .Classification (Classification),
		  .ClassificationValid (ClassificationValid),
		  
		  .WriteReady (WriteReady),
		  .DebugFSMState (DebugFSMState)
    );

    //datapath taps
    wire [3:0]  ReadData          = DUT.NNDatapath.ReadData;
    wire [63:0] ScratchpadReadData= DUT.NNDatapath.ScratchpadReadData;
    wire [63:0] ReLUOut           = DUT.NNDatapath.ReLUOut;
    wire [7:0]  MACOutValid       = DUT.NNDatapath.MACOutValid;

    //fSM taps
	 wire [4:0] FSMState = DUT.FSM.State;
	 wire [3:0] HiddenBlock = DUT.FSM.HiddenBlock;
	 wire [4:0] OutputBlock  =DUT.FSM.OutputBlock;
	 wire [4:0] WritePointer = DUT.FSM.WritePointer;
	 wire [7:0] MACSeen = DUT.FSM.MACSeen;
	 wire MACDone = DUT.FSM.MACDone;

	function [127:0] StateName;
		input [4:0] S;
		case (S)
			0: StateName = "Reset";
			1: StateName = "LoadInputs";
			2: StateName = "WaitCommit";
			3: StateName = "HiddenStart";
			4: StateName = "HiddenMAC";
			5: StateName = "HiddenStore";
			6: StateName = "HiddenClear";
			7: StateName = "HiddenNext";
			8: StateName = "HiddenDone";
			9: StateName = "OutputStart";
			10: StateName = "OutputMAC";
			11: StateName = "OutputStore";
			12: StateName = "OutputClear";
			13: StateName = "OutputNext";
			14: StateName = "OutputDone";
			15: StateName = "ArgReadSP2";
			16: StateName = "ArgWaitSP2";
			17: StateName = "ArgReadSP3";
			18: StateName = "ArgWaitSP3";
			19: StateName = "ArgPacked";
			20: StateName = "ArgStart";
			21: StateName = "ArgWait";
			22: StateName = "ArgDone";
			23: StateName = "HiddenWait";
			24: StateName = "OutputWait";
			default: StateName = "Unknown";
		endcase
	endfunction
	
	reg [4:0] PrevState = 0;
	integer StateEntryTime;
	integer CycleCount;
	
	always @(posedge Clk) begin
		if(FSMState != PrevState) begin
			$display("[%0t] STATE: %s -> %s | HiddenBlock=%0d OutputBlock=%0d WritePointer=%0d", $time, StateName(PrevState), StateName(FSMState), HiddenBlock, OutputBlock, WritePointer);
			PrevState <= FSMState;
			StateEntryTime <= $time;
		end
	end
	
	always @(posedge Clk) begin
		if (!Reset && WritePointer > 4)
			$display("Assertion Fail [%0t]: WritePointer=%0d exceeded max of 4", $time, WritePointer);
	end
	
	always @(posedge Clk) begin
		if(!Reset && HiddenBlock > 2)
			$display("Assertion Fail [%0t]: HiddenBlock=%0d exceeded max of 1", $time, HiddenBlock);
	end
	
	always @(posedge Clk) begin
		if(!Reset && OutputBlock > 2)
			$display("Assertion Fail [%0t]: OutputBlock=%0d exceeded max of 1", $time, OutputBlock);
	end
	
	reg [4:0] LastFSMState;
	
	always @(posedge Clk) begin
		LastFSMState <= FSMState;
	end
	
	integer StateHoldCycles = 0;
	always @(posedge Clk) begin
		if(FSMState != LastFSMState)
			StateHoldCycles <= 0;
		else
			StateHoldCycles <= StateHoldCycles + 1;
		
		if (StateHoldCycles > 300)
			$display("Assertion Fail [%0t]: Stuck in state %s for %0d cycles", $time, StateName(FSMState), StateHoldCycles);
	end
	
	integer i;
	
	task SendPixels;
		input [3:0] Val;
		begin
			for (i = 0; i < 64; i = i + 1) begin
				@(posedge Clk)
				WriteValid <= 1;
				WriteData <= Val;
			end
			@(posedge Clk);
			WriteValid <= 0;
		end
	endtask
	
	integer CycleCounter = 0;
	integer Run1StartCycle;
	integer Run1EndCycle;
	integer Run2StartCycle;
	integer Run2EndCycle;
	
	always@(posedge Clk) begin
		if(!Reset)
			CycleCounter <= CycleCounter + 1;
	end
	
	initial begin
		@(negedge Reset);
		
		//Test 1
		$display("Test 1: all zeros");
		Run1StartCycle = CycleCounter;
		SendPixels(4'd0);
		@(posedge Clk);
		Commit <= 1;
		@(posedge Clk);
		Commit <= 0;
		wait(Done==1);
		Run1EndCycle = CycleCounter;
		$display("Test 1 Result: Classification=%0d Valid=%0b | Cycles=%0d", Classification, ClassificationValid, (Run1EndCycle - Run1StartCycle));
		@(posedge Clk);
		
		//Test 2: all max val
		Reset <= 1;
		# 20;
		Reset <= 0;
		$display("Test 2: all max val");
		Run2StartCycle = CycleCounter;
		@(posedge Clk);
		SendPixels(4'hF);
		@(posedge Clk);
		Commit <= 1;
		@(posedge Clk);
		Commit <= 0;
		wait(Done==1);
		Run2EndCycle = CycleCounter;
		$display("Test 2 Result: Classification=%0d Valid=%0b | Cycles=%0d", Classification, ClassificationValid, (Run2EndCycle - Run2StartCycle));
		
		$display("CPR Run1=%0d CPR Run2=%0d", (Run1EndCycle - Run1StartCycle), (Run2EndCycle - Run2StartCycle));
		
		#200;
		$finish;
	end
	
	initial begin
		#5000000;
		$display("TB timeout");
		$finish;
	end
	
	initial begin
		@(negedge Reset);
		$dumpfile("TopLevelNN.vcd");
		$dumpvars(0, DUT);
	end
endmodule