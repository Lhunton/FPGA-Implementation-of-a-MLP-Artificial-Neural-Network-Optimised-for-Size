`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
//
// Create Date:   18:29:22 04/13/2026
// Design Name:   MAC_Unit
// Module Name:   /home/ise/CompleteNeuralNetworkV2/MacUnit_tb.v
// Project Name:  FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Device:  XC3S1500 Spartan-3
// Tool versions:  Xilinx 14.2
// Description: MAC Unit Test Bench
//
// Verilog Test Fixture created by ISE for module: MAC_Unit
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module MacUnit_tb;

	// Inputs
	reg Clk;
	reg Reset;
	reg Enable;
	reg Clear;
	reg signed [7:0] A;
	reg signed [7:0] B;
	reg [15:0] CountConfigure;

	// Outputs
	wire signed [7:0] Output;
	wire Valid;

	// Instantiate the Unit Under Test (UUT)
	MAC_Unit uut (
		.Clk(Clk), 
		.Reset(Reset), 
		.Enable(Enable), 
		.Clear(Clear), 
		.A(A), 
		.B(B), 
		.CountConfigure(CountConfigure), 
		.Output(Output), 
		.Valid(Valid)
	);

	//clk
	initial begin
		Clk = 0;
			forever #5 Clk = ~Clk;
	end

	integer Acc;
	integer i;
	
	task RunMACTest;
		input signed [7:0] aVal;
		input signed [7:0] bVal;
		input integer Length;
		integer Product;
		integer Expected;
		begin
			Acc = 0;
			Enable = 0;
			CountConfigure = Length;
			Clear = 1;
			@(posedge Clk);
			@(posedge Clk);
			Clear = 0;
			@(posedge Clk);
			
			for (i = 0; i < Length; i = i + 1) begin
				Enable = 1;
				A = aVal;
				B = bVal;
				@(posedge Clk);
				
				Product = aVal * bVal;
				Acc = Acc + Product;
			end
			
			Enable = 0;
			
			@(posedge Valid);
			
			Expected = (Acc+64) >>> 11;
			
			if (Output !== Expected[7:0]) begin
				$display("FAIL: A=%0d B=%0d Len=%0d Expec=%0d Out=%0d", aVal, bVal, Length, Expected, Output);
				$stop;
			end
			else begin
				$display("PASS: A=%0d B=%0d Len=%0d Expec=%0d Out=%0d", aVal, bVal, Length, Expected, Output);
			end
		end
	endtask
			
	//Test patterns
	initial begin
		Reset = 1;
		Enable = 0;
		Clear = 0;
		A = 0;
		B = 0;
		CountConfigure =0;
		
		$dumpfile("MacUnit_tb.vcd");
		$dumpvars(0, MacUnit_tb);
		
		@(posedge Clk);
		Reset = 0;
		
		//Test values
		RunMACTest(8'sd64, 8'sd64, 4);
		RunMACTest(8'sd32, 8'sd64, 8);
		RunMACTest(-8'sd64, 8'sd64, 4);
		
		//random tests
		repeat (20) begin
			RunMACTest($random, $random, 8);
		end
		
		$display("ALL mac tests passed");
		$finish;
	end

		
endmodule

