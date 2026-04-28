`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
//
// Create Date:   01:54:37 04/14/2026
// Design Name:   InputBuffer
// Module Name:   /home/ise/CompleteNeuralNetworkV2/InputBuffer_tb.v
// Project Name:  FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Device:  XC3S1500 Spartan-3
// Tool versions:  Xilinx 14.2
// Description: Input Buffer Test Bench
//
// Verilog Test Fixture created by ISE for module: InputBuffer
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module InputBuffer_tb;

	// Inputs
	reg Clk;
	reg Reset;
	reg WriteValid;
	reg [3:0] WriteData;
	reg Commit;
	reg ReadEnable;
	reg [5:0] ReadAddress;

	// Outputs
	wire WriteReady;
	wire BufferFull;
	wire [3:0] ReadData;
	wire [5:0] WriteIndex;

	// Instantiate the Unit Under Test (UUT)
	InputBuffer uut (
		.Clk(Clk), 
		.Reset(Reset), 
		.WriteValid(WriteValid), 
		.WriteData(WriteData), 
		.WriteReady(WriteReady), 
		.Commit(Commit), 
		.BufferFull(BufferFull), 
		.ReadEnable(ReadEnable), 
		.ReadAddress(ReadAddress), 
		.ReadData(ReadData), 
		.WriteIndex(WriteIndex)
	);
	
	initial begin
		Clk = 0;
		forever #5 Clk = ~Clk;
	end
	
	integer Failed;
	integer i;
	
	task WriteWord;
		input [3:0] Data;
		begin
			@(posedge Clk);
			#1;
			WriteValid = 1;
			WriteData = Data;
			@(posedge Clk);
			#1;
			if(!WriteReady) begin
				$display("FAIL: WriteReady not asserted for Data=%0d", Data);
				Failed = Failed + 1;
			end
			WriteValid = 0;
		end
	endtask
	
	task FillBuffer;
		begin
			for (i = 0; i < 64; i = i + 1) begin
				@(posedge Clk); 
				#1;
				WriteValid = 1;
				WriteData = i[3:0];
			end
			@(posedge Clk); 
			#1;
			WriteValid = 0;
		end
	endtask
	
	task CommitAndWait;
		begin
			@(posedge Clk);
			#1;
			Commit = 1;
			@(posedge Clk);
			#1;
			Commit = 0;
			
			if(!BufferFull) begin
				$display("FAIL: BufferFull not asserted after commit");
				Failed = Failed + 1;
			end else begin
				$display("PASS: BufferFUll Asserted after Commit");
			end
		end
	endtask
	
	task VerifyReadback;
		reg [3:0] Expected;
		begin
			for (i = 0; i < 64; i = i + 1) begin
				@(posedge Clk);
				#1;
				ReadEnable = 1;
				ReadAddress = i[5:0];
				@(posedge Clk);
				#1;
				ReadEnable = 0;
				
				Expected = i[3:0];
				if(ReadData !== Expected) begin
					$display("FAIL (readback): Addr=%0d Expected=%0d Output=%0d", i, Expected, ReadData);
					Failed = Failed + 1;
				end else begin
					$display("PASS (readback): Addr=%0d Data=%0d", i, ReadData);
				end
			end
		end
	endtask
	
	initial begin
		Failed = 0;
		Reset = 1;
		WriteValid = 0;
		WriteData = 0;
		Commit = 0;
		ReadEnable = 0;
		ReadAddress = 0;
		
		$dumpfile("InputBuffer_tb.vcd");
		$dumpvars(0, InputBuffer_tb);
		
		@(posedge Clk);
		#1;
		@(posedge Clk);
		#1;
		Reset = 0;
		@(posedge Clk);
		#1;
		
		$display("Test 1: Fill and readback");
		FillBuffer;
		CommitAndWait;
		VerifyReadback;
		
		$display("Test 2: No write when bufferfull");
		@(posedge Clk);
		#1;
		WriteValid = 1;
		WriteData = 4'hF;
		@(posedge Clk);
		#1;
		if(WriteReady) begin
			$display("FAIL: WriteReady asserted when bufferfull - should be blocked");
			Failed = Failed + 1;
		end else begin
			$display("PASS: Write correctly blocked when BufferFull");
		end
		WriteValid = 0;
		
		$display("Test 3: Reset");
		@(posedge Clk);
		#1;
		Reset = 1;
		@(posedge Clk);
		#1;
		@(posedge Clk);
		#1;
		Reset = 0;
		@(posedge Clk);
		#1;
		
		
		if(BufferFull) begin
			$display("FAIL: BufferFull not cleared after Reset");
			Failed = Failed + 1;
		end else begin
			$display("PASS: BufferFUll cleared after Reset");
		end
		
		if(WriteIndex !== 0) begin
			$display("FAIL: WriteIndex not cleared after Reset, output=%0d", WriteIndex);
			Failed = Failed + 1;
		end else begin
			$display("PASS: WriteIndex cleared after Reset");
		end
		
		$display("Test 4: Partial write then commit");
		for(i = 0; i < 4; i = i + 1)
			WriteWord(i[3:0]);
			
		@(posedge Clk);
		#1;
		Commit = 1;
		@(posedge Clk);
		#1;
		Commit = 0;
		
		if(BufferFull) begin
			$display("FAIL: Bufferfull set after partial write");
			Failed = Failed + 1;
		end else begin
			$display("PASS: Bufferfull not set after partial write");
		end
		
		$display("Test 5: Complete fill after partial");
		for(i = 4; i < 64; i = i + 1)
			WriteWord(i[3:0]);
		CommitAndWait;
		
		if(Failed == 0)
			$display("ALL inputbuffer tests passed");
		else 
			$display("FAILED: %0d tests failed", Failed);
		
		$finish;
	end
	
endmodule