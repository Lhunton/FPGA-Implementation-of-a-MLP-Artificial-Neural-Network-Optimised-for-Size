`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
//
// Create Date:   03:01:14 04/14/2026
// Design Name:   Scratchpad
// Module Name:   /home/ise/CompleteNeuralNetworkV2/Scratchpad_tb.v
// Project Name:  FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Device:  XC3S1500 Spartan-3
// Tool versions:  Xilinx 14.2
// Description: Scratchpad Test Bench
//
// Verilog Test Fixture created by ISE for module: Scratchpad
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module Scratchpad_tb;

	// Inputs
	reg Clk;
	reg Reset;
	reg WriteEnable;
	reg [4:0] WriteAddress;
	reg [63:0] WriteData;
	reg [4:0] ReadAddress;

	// Outputs
	wire [63:0] ReadData;

	// Instantiate the Unit Under Test (UUT)
	Scratchpad uut (
		.Clk(Clk), 
		.Reset(Reset), 
		.WriteEnable(WriteEnable), 
		.WriteAddress(WriteAddress), 
		.WriteData(WriteData), 
		.ReadAddress(ReadAddress), 
		.ReadData(ReadData)
	);
	
initial begin
	Clk = 0;
	forever #5 Clk = ~Clk;
end

integer Failed;
integer i;

task Write;
	input [4:0] Addr;
	input [63:0] Data;
	begin
		@(posedge Clk);
		#1;
		WriteEnable = 1;
		WriteAddress = Addr;
		WriteData = Data;
		@(posedge Clk);
		#1;
		WriteEnable = 0;
	end
endtask

task CheckRead;
	input [4:0] Addr;
	input [63:0] Expected;
	begin
		ReadAddress = Addr;
		#1;
		if(ReadData !== Expected) begin
			$display("FAIL (read): ADDR=%0d Expected=%h Output=%h", Addr, Expected, ReadData);
			Failed = Failed + 1;
		end else begin
			$display("PASS (read): Addr=%0d Data=%h", Addr, ReadData);
		end
	end
endtask

initial  begin
	Failed = 0;
	Reset = 1;
	WriteEnable = 0;
	WriteAddress = 0;
	WriteData = 0;
	ReadAddress = 0;
	
	$dumpfile("Scratchpad_tb.vcd");
	$dumpvars(0, Scratchpad_tb);
	
	@(posedge Clk)
	#1;
	@(posedge Clk)
	#1;
	Reset = 0;
	@(posedge Clk)
	#1;
	
	$display("Test 1: Reset Clears all locations");
	for (i = 0; i < 32; i = i + 1)
		CheckRead(i[4:0], 64'd0);
	
	$display("Test 2: Write and Readback all locations");
	for(i = 0; i < 32; i = i + 1)
		Write(i[4:0], 64'hDEADBEEFCAFE0000 | i);
		
	for (i = 0; i < 32; i = i + 1)
		CheckRead(i[4:0], 64'hDEADBEEFCAFE0000 | i);
	
	$display("Test 3: Asynch read updates immediatly on address cahnge");
	Write(5'd5, 64'hAAAAAAAAAAAAAAAA);
	Write (5'd6, 64'hBBBBBBBBBBBBBBBB);
	
	ReadAddress = 5'd5;
	#1;
	
	if(ReadData !== 64'hAAAAAAAAAAAAAAAA) begin
		$display("FAIL (asynch): Addr=5 expected 16*A Output=%h", ReadData);
		Failed = Failed + 1;
	end else 
		$display("PASS (asynch): Addr=5 immediate read correct");
		
	ReadAddress = 5'd6;
	#1;
	
	if(ReadData !== 64'hBBBBBBBBBBBBBBBB) begin
		$display("FAIL (asynch): Addr=6 expected 16*B Output=%h", ReadData);
		Failed = Failed + 1;
	end else 
		$display("PASS (asynch): Addr=6 immediate read correct");	
		
	$display("Test 4: WriteEnable gate");
	Write(5'd10, 64'hCAFECAFECAFECAFE);
	
	@(posedge Clk);
	#1;
	WriteEnable = 0;
	WriteAddress = 5'd10;
	WriteData = 64'hDEADDEADDEADDEAD;
	@(posedge Clk);
	#1;
	
	CheckRead(5'd10, 64'hCAFECAFECAFECAFE);
	
	$display("Test 5: Overwrite");
	Write(5'd15, 64'h1111111111111111);
	CheckRead(5'd15, 64'h1111111111111111);
	Write(5'd15, 64'h2222222222222222);
	CheckRead(5'd15, 64'h2222222222222222);

	$display("Test 6: Boundary addresses");
	Write(5'd0, 64'hFFFFFFFFFFFFFFFF);
	Write(5'd31, 64'h0000000000000001);
	CheckRead(5'd0, 64'hFFFFFFFFFFFFFFFF);
	CheckRead(5'd31, 64'h0000000000000001);
	
	$display("Test 7: Reset after writes");
	Reset = 1;
	@(posedge Clk);
	#1;
	@(posedge Clk);
	#1;
	Reset = 0;
	@(posedge Clk);
	#1;
	for(i = 0; i < 32; i = i + 1)
		CheckRead(i[4:0], 64'd0);
	
	$display("Test 8: Read whioe writing different address");
	Write(5'd20, 64'hFACEFACEFACEFACE);
	ReadAddress = 5'd20;
	
	@(posedge Clk);
	#1;
	WriteEnable = 1;
	WriteAddress = 5'd21;
	WriteData = 64'h9999999999999999;
	#1;
	if(ReadData !== 64'hFACEFACEFACEFACE) begin
		$display("FAIL (concurrent): Read distributed by write to a different address, Output=%h", ReadData);
		Failed = Failed + 1;
	end else
		$display("PASS (concurrent): Read unaffected by write to different address");
	@(posedge Clk);
	#1;
	WriteEnable = 0;
	
	if (Failed == 0)
		$display ("ALL scratchpad tests passed");
	else
		$display ("FAILED: 0%d tests failed", Failed);
		
	$finish;
end
      
endmodule

