`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
// 
// Create Date:    17:24:00 02/28/2026 
// Design Name: 
// Module Name:    MACInputDataPath 
// Project Name: FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Devices: XC3S1500 Spartan-3
// Tool versions: Xilinx 14.2
// Description: Neural Network Interconnect Layer
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module MACInputDataPath(
	input wire Clk,
	input wire Reset,

	//input buffer control
	input wire WriteValid,
	input wire [3:0] WriteData,
	input wire Commit,
	
	input wire ReadEnable,
	input wire [5:0] ReadAddress,
	output wire [3:0] ReadData,

	//scratchpad control
	input wire ScratchpadWriteEnable,
	input wire [4:0] ScratchpadWriteAddress,
	input wire [4:0] ScratchpadReadAddress,
	output wire [63:0] ScratchpadReadData,

	//input mux
	input wire SelectMode,

	//weight bais control
	input wire [7:0] WeightAddress,
	input wire [7:0] BiasAddress,
	
	//mac control
	input wire MACEnable,
	input wire MACClear,
	input wire [15:0] CountConfigure,
	
	//outputs
	output wire [63:0] ReLUOut,
	output wire [7:0] MACOutValid,
	
	input wire [3:0] Cycle,
	
	output wire [5:0] WriteIndex,
	output wire WriteReady,
	output wire AllValid
   );
	
//input buffer
wire BufferFull;

InputBuffer InputBuffer (
	.Clk(Clk),
	.Reset(Reset),
	
	.WriteValid (WriteValid),
	.WriteData (WriteData),
	.WriteReady (WriteReady),
	
	.Commit (Commit),
	.BufferFull (BufferFull),
	.ReadEnable (ReadEnable),
	.ReadAddress (ReadAddress),
	.ReadData (ReadData),
	
	.WriteIndex (WriteIndex)
);

//scratchpad 32 64-bit values
wire [63:0] ScratchpadData;

wire [63:0] OutputLayerOut;

Scratchpad Scratchpad (
	.Clk (Clk),
	.Reset (Reset),
	.WriteEnable (ScratchpadWriteEnable),
	.WriteAddress (ScratchpadWriteAddress),
	.WriteData (OutputLayerOut),
	.ReadAddress (ScratchpadReadAddress),
	.ReadData (ScratchpadData)
);

assign ScratchpadReadData = ScratchpadData;

//input adapter expands + mux
wire [63:0] MACInputBus;

InputAdapter InputAdapter (
	.SelectMode (SelectMode),
	.DataInput (ReadData), //4 bit source
	.ScratchpadData (ScratchpadData), //64 bit source
	.MACInputBus (MACInputBus),
	.Cycle (Cycle)
);	

//BRAM
wire [63:0] WeightData;
wire [63:0] BiasDataInternal;

NNPackedMemory BRAM (
	//Port A
	.clka(Clk),
	.wea (1'b0),
	.addra(WeightAddress),
	.dina(64'd0),
	.douta(WeightData),
		
	//Port B
	.clkb(Clk),
	.web (1'b0),
	.addrb(BiasAddress),
	.dinb(64'd0),
	.doutb(BiasDataInternal)
);

//bias latch
reg [63:0] BiasLatch;

always @(posedge Clk) begin
	if(Reset)
		BiasLatch <= 64'd0;
	else
		BiasLatch <= BiasDataInternal;
end

//MAC Array
wire [63:0] MACOut;

MA_Array MAC(
	.Clk (Clk),
	.Reset (Reset),
	
	.Enable (MACEnable),
	.Clear (MACClear),
	
	.Input (MACInputBus),
	.Weight (WeightData),
	
	.CountConfigure (CountConfigure),
	.MACOut (MACOut),
	.Valid (MACOutValid),
	.AllValid(AllValid)
);

//Adder macout + bias
wire [63:0] AdderOutput;

assign OutputLayerOut = (SelectMode == 1'b1) ? AdderOutput : ReLUOut;

Adder_Array_RCA_8bit AdderArray (
	.A (MACOut),
	.B (BiasLatch),
	.Cin (8'd0),
	.Sum (AdderOutput),
	.Cout ()
);

//ACtivation function
Activation_Function_Block ReLU(
	.Clk (Clk),
	.Reset (Reset),
	.Input (AdderOutput),
	.Output (ReLUOut)
);

endmodule
