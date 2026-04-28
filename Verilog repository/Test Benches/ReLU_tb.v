`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
//
// Create Date:   23:20:36 04/13/2026
// Design Name:   Activation_Function_Block
// Module Name:   /home/ise/CompleteNeuralNetworkV2/ReLU_tb.v
// Project Name:  FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Device:  XC3S1500 Spartan-3
// Tool versions:  Xilinx 14.2
// Description: Activation Function Test Bench
//
// Verilog Test Fixture created by ISE for module: Activation_Function_Block
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module ReLU_tb;

	// Inputs
	reg Clk;
	reg Reset;
	reg signed [63:0] Input;

	// Outputs
	wire signed [63:0] Output;

	// Instantiate the Unit Under Test (UUT)
	Activation_Function_Block uut (
		.Clk(Clk), 
		.Reset(Reset), 
		.Input(Input), 
		.Output(Output)
	);

	//clk
	initial begin
		Clk = 0;
			forever #5 Clk = ~Clk;
	end
	
	function signed [63:0] PackLanes;
		input signed [7:0] v0, v1, v2, v3, v4, v5, v6, v7;
		begin
			PackLanes = {v7, v6, v5, v4, v3, v2, v1, v0};
		end
	endfunction
	
	function signed [63:0] ExpectedReLU;
		input signed [63:0] In;
		integer j;
		reg signed [7:0] Lane;
		begin
			for (j = 0; j <8; j = j + 1) begin
				Lane = In[j*8 +: 8];
				ExpectedReLU[j*8 +: 8] = (Lane < 0) ? 8'sd0 : Lane;
			end
		end
	endfunction
	
	task ReLUTest;
		input signed [63:0] TestInput;
		reg signed [63:0] Expected;
		begin
			Input = TestInput;
			@(posedge Clk);
			#1
			
			Expected = ExpectedReLU(TestInput);
			
			if (Output !== Expected) begin
				$display("FAIL: Input=%h Expected=%h Output=%h", TestInput, Expected, Output);
				$stop;
			end else begin
				$display("PASS: Input=%h Expected=%h Output=%h", TestInput, Expected, Output);
			end
		end
	endtask
		
	initial begin
		Reset = 1;
		Input = 64'd0;
		
		$dumpfile("ReLU_tb.vcd");
		$dumpvars(0, ReLU_tb);
		
		@(posedge Clk);
		@(posedge Clk);
		Reset = 0;
		@(posedge Clk);
		
		//Test values
		ReLUTest(PackLanes(8'sd1, 8'sd2, 8'sd3, 8'sd4, 8'sd5, 8'sd6, 8'sd7, 8'sd8));
		ReLUTest(PackLanes(-8'sd1, -8'sd2, -8'sd3, -8'sd4, -8'sd5, -8'sd6, -8'sd7, -8'sd8));
		ReLUTest(PackLanes(8'sd10, -8'sd20, 8'sd30, -8'sd40, 8'sd50, -8'sd60, 8'sd70, -8'sd80));
		ReLUTest(PackLanes(8'sd127, -8'sd128, 8'sd0, -8'sd1, 8'sd1, 8'sd127, -8'sd128, 8'sd0));
		ReLUTest(PackLanes(8'sd0, 8'sd0, 8'sd0, 8'sd0, 8'sd0, 8'sd0, 8'sd0, 8'sd0));
		ReLUTest(PackLanes(8'sd127, 8'sd127, 8'sd127, 8'sd127, 8'sd127, 8'sd127, 8'sd127, 8'sd127));
		ReLUTest(PackLanes(-8'sd128, -8'sd128, -8'sd128, -8'sd128, -8'sd128, -8'sd128, -8'sd128, -8'sd128));
		
		//random tests
		repeat (50) begin
			ReLUTest($random);
		end
		
		$display("ALL mac tests passed");
		$finish;
	end

		
endmodule

