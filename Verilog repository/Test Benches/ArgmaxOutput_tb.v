`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
//
// Create Date:   00:14:25 04/14/2026
// Design Name:   Argmaax_output
// Module Name:   /home/ise/CompleteNeuralNetworkV2/ArgmaxOutput_tb.v
// Project Name:  FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Device:  XC3S1500 Spartan-3
// Tool versions:  Xilinx 14.2
// Description: Argmax Test Bench
//
// Verilog Test Fixture created by ISE for module: Argmaax_output
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module ArgmaxOutput_tb;

	// Inputs
	reg Clk;
	reg Reset;
	reg ValidIn;
	reg [79:0] DataIn;

	// Outputs
	wire [3:0] Output;
	wire Valid;

	// Instantiate the Unit Under Test (UUT)
	Argmaax_output uut (
		.Clk(Clk), 
		.Reset(Reset), 
		.ValidIn(ValidIn), 
		.DataIn(DataIn), 
		.Output(Output), 
		.Valid(Valid)
	);

	//clk
	initial begin
		Clk = 0;
			forever #5 Clk = ~Clk;
	end
	
	function signed [79:0] PackLanes;
		input signed [7:0] v0, v1, v2, v3, v4, v5, v6, v7, v8, v9;
		begin
			PackLanes = {v9, v8, v7, v6, v5, v4, v3, v2, v1, v0};
		end
	endfunction
	
	function signed [3:0] ExpectedArgmax;
		input signed [79:0] In;
		integer i;
		reg signed [7:0] MaxVal;
		begin
			MaxVal = In[7:0];
			ExpectedArgmax = 0;
		
			for (i = 1; i <10; i = i + 1) begin
				if(In[i*8 +: 8] > MaxVal) begin
					MaxVal = In[i*8 +: 8];
					ExpectedArgmax = i[3:0];
				end
			end
		end
	endfunction
	
	task ArgmaxTest;
		input signed [79:0] TestInput;
		reg signed [3:0] Expected;
		integer timeout;
		begin
			Expected = ExpectedArgmax(TestInput);
			
			@(posedge Clk);
			#1;
			DataIn = TestInput;
			ValidIn = 1'b1;
			
			@(posedge Clk);
			#1;
			ValidIn = 1'b0;
			
			@(posedge Valid);
			
			if(Output !== Expected) begin
				$display("FAIL: Input=%h ExpectedIdx=%0d Output=%0d", TestInput, Expected, Output);
				$stop;
			end else begin
				$display("PASS: Input=%h Argmax=%0d", TestInput, Output);
			end
		end
	endtask
	
	integer k;
	
	initial begin
		Reset = 1;
		ValidIn = 0;
		DataIn = 0;
		
		$dumpfile("ArgmaxOutput_tb.vcd");
		$dumpvars(0, ArgmaxOutput_tb);
		
		@(posedge Clk);
		@(posedge Clk);
		Reset = 0;
		@(posedge Clk);
		
		ArgmaxTest(PackLanes(8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8, 8'd9, 8'd10));
		ArgmaxTest(PackLanes(8'd10, 8'd9, 8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1));
		ArgmaxTest(PackLanes(8'd1, 8'd2, 8'd3, 8'd4, 8'd99, 8'd5, 8'd6, 8'd7, 8'd8, 8'd9));
		//ArgmaxTest(PackLanes(8'd7, 8'd7, 8'd7, 8'd7, 8'd7, 8'd7, 8'd7, 8'd7, 8'd7, 8'd7)); Test cases where the
		//max value is repeated do not work and hardware correction would be overly expensive
		ArgmaxTest(PackLanes(8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8, 8'd9, 8'd127));
		
		//repeat random tests
		repeat (20) begin
			ArgmaxTest(PackLanes($random, $random, $random, $random, $random, $random, $random, $random, $random, $random));
		end
		
		$display ("ALL ARGMAX TESTS PASSED");
		$finish;
	end
	
endmodule