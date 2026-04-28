`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
//
// Create Date:   01:15:36 04/14/2026
// Design Name:   InputAdapter
// Module Name:   /home/ise/CompleteNeuralNetworkV2/InputAdapter_tb.v
// Project Name:  FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Device:  XC3S1500 Spartan-3
// Tool versions:  Xilinx 14.2
// Description: Input Adapter Test Bench
//
// Verilog Test Fixture created by ISE for module: InputAdapter
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module InputAdapter_tb;

	// Inputs
	reg SelectMode;
	reg [3:0] DataInput;
	reg [63:0] ScratchpadData;
	reg [3:0] Cycle;

	// Outputs
	wire [63:0] MACInputBus;

	// Instantiate the Unit Under Test (UUT)
	InputAdapter uut (
		.SelectMode(SelectMode), 
		.DataInput(DataInput), 
		.ScratchpadData(ScratchpadData), 
		.MACInputBus(MACInputBus), 
		.Cycle(Cycle)
	);


	function [7:0] ExpectedScale;
		input [3:0] In;
		begin
			case(In)
				4'd0: ExpectedScale = 8'h00;
				4'd1: ExpectedScale = 8'h09;
				4'd2: ExpectedScale = 8'h11;
				4'd3: ExpectedScale = 8'h1A;
				4'd4: ExpectedScale = 8'h22;
				4'd5: ExpectedScale = 8'h2B;
				4'd6: ExpectedScale = 8'h33;
				4'd7: ExpectedScale = 8'h3C;
				4'd8: ExpectedScale = 8'h44;
				4'd9: ExpectedScale = 8'h4D;
				4'd10: ExpectedScale = 8'h55;
				4'd11: ExpectedScale = 8'h5E;
				4'd12: ExpectedScale = 8'h66;
				4'd13: ExpectedScale = 8'h6F;
				4'd14: ExpectedScale = 8'h77;
				4'd15: ExpectedScale = 8'h7F;
				default: ExpectedScale = 8'h00;
			endcase
		end
	endfunction
	
	function [63:0] PackReplicated;
		input [7:0] Val;
		begin
			PackReplicated = {Val, Val, Val, Val, Val, Val, Val, Val};
		end
	endfunction
	
	integer Failed;
	
	task CheckInputBufferMode;
		input [3:0] Data;
		reg [63:0] Expected;
		begin
			SelectMode = 0;
			DataInput = Data;
			#10;
			
			Expected = PackReplicated(ExpectedScale(Data));
			
			if (MACInputBus !== Expected) begin
				$display("FAIL (SM = 0): DataInput=%0d Expected=%h Output = %h", Data, Expected, MACInputBus);
				Failed = Failed + 1;
			end else begin
				$display("PASS (SM = 0): DataInput=%0d ScaledOutput=%h", Data, MACInputBus[7:0]);
			end
		end
	endtask
	
	task CheckScratchpadMode;
		input [63:0] Scratchpad;
		input [2:0] CycleIn;
		reg [7:0] ExpectedByte;
		reg [63:0] ExpectedBus;
		begin
			SelectMode = 1;
			ScratchpadData = Scratchpad;
			Cycle = {1'b0, CycleIn};
			#10;
			
			ExpectedByte = Scratchpad[CycleIn * 8 +: 8];
			ExpectedBus = PackReplicated(ExpectedByte);
			
			if(MACInputBus !== ExpectedBus) begin
				$display("FAIL (SM =  1): Cycle=%0d Expected=%h Output=%h", Cycle, ExpectedBus, MACInputBus);
				Failed = Failed + 1;
			end else begin
				$display("PASS (SM = 1): Cycle=%0d ByteSelected=%h", Cycle, ExpectedByte);
			end
		end
	endtask
	
	integer i;
	
	initial begin
		Failed = 0;
		SelectMode = 0;
		DataInput = 0;
		ScratchpadData = 0;
		Cycle = 0;
		
		$dumpfile("InputAdapter_tb.vcd");
		$dumpvars(0, InputAdapter_tb);
		
		$display("InputBuffer mode test");
		for(i = 0; i < 16; i = i + 1)
			CheckInputBufferMode(i[3:0]);
		
		$display("Scratchpad modetest");
		ScratchpadData = 64'h0102030405060708;
		for(i = 0; i < 8; i = i + 1)
			CheckScratchpadMode(64'h0102030405060708, i[2:0]);
			
		for(i = 0; i < 8; i = i + 1)
			CheckScratchpadMode(64'hAAAAAAAAAAAAAAAA, i[2:0]);
		
		$display("Mode switch tests");
		ScratchpadData = 64'hDEADBEEFCAFEBABE;
		Cycle = 4'd3;
		DataInput = 4'd7;
		
		SelectMode = 1;
		#10;
		$display("Scratchpad Mode: MACInputBus=%h", MACInputBus);
		
		SelectMode = 0;
		#10;
		$display("InputBuffer Mode: MACInputBus=%h", MACInputBus);
		
		if(Failed == 0)
			$display("All inputadapter tests passed");
		else
			$display("Failed: %0d tests failed", Failed);
		
		$finish;
	end
		
		
	
			

      
endmodule

