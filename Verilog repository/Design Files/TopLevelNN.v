`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Manchester
// Engineer: Lewis Hunton
// 
// Create Date:    03:52:36 02/27/2026 
// Design Name: 
// Module Name:    TopLevelNN 
// Project Name: FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
// Target Devices: XC3S1500 Spartan-3
// Tool versions: Xilinx 14.2
// Description: Top Level Neural Network
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module TopLevelNN(
	//Primary signals
	input Clk,
	input Reset,
	input Enable,
	input Clear,

	//Weight Memory Signals
	input wire WeightStart,
	output wire WeightDone,
	output wire WeightValid,
	
	//Bias Memory Connections
	input wire [7:0] BiasAddress,
	input wire BiasReadRequest,
	output wire BiasValid,
	
	//MAC Connections
	output wire MACValid,
	input wire [3:0] MACAccCount,
	
	//Input Buffer connections
	input wire InputBufferWriteValid,
	input wire [3:0] InputBufferWriteData,
	input wire InputBufferCommit,
	input wire InputBufferReadEnable,
	input wire [5:0] InputBufferReadAddress,
	output wire InputBufferFull,
	output wire InputBufferWriteReady,
	
	//Scratchpad Connections
	input wire ScratchpadWriteEnable,
	input wire [3:0] ScratchpadReadAddress,
	output wire [7:0] ScratchpadReadDataOut,

	//Mux Controls
	//MACSelectSource
	// 0 = InputBuffer
	// 1 = Scratchpad (Vector)
	input wire MACSelectSource,			
	
	//ScratchpadSelectSource
	// 0 = ReadFUll SCratchpadVector
	// 1 = Read scalar broadcast
	input wire ScratchpadSelectSource,	
	
	//ArgmaxFromScratchpad
	//Select between scratchpad or mac output for argmax
	input wire ArgmaxFromScratchpad,
	
	output wire [7:0] ArgmaxDataOut,
	
	//Debug
	output wire [7:0] ReLuOutputByte
    );
	 
	 wire [63:0] BRAMDoutA; //weight data
	 wire [63:0] BRAMDoutB; //Bias data 
	 wire [7:0] WeightAddress;  //address from weightmemory
	 wire [7:0] BiasAddressToBRAM;
	 
	 NNPackedMemory BRAM (
		//Port A - Not used here. its for weight memory
		.clka(Clk),
		.wea (1'b0),
		.addra(WeightAddress),
		.dina(64'd0),
		.douta(BRAMDoutA),
		
		//port B - used here
		.clkb(Clk),
		.web (1'b0),
		.addrb(BiasAddressToBRAM),
		.dinb(64'd0),
		.doutb(BRAMDoutB)
	);
	
	//Weight Memory	
	wire WeightValidI;
	
	WeightMemory WeightMemoryTopLevel (
		.Clk (Clk),
		.Reset (Reset),
		.Start (WeightStart),
		.WeightData (BRAMDoutA),
		.WeightAddress (WeightAddress),
		.Valid (WeightValidI),
		.Done (WeightDone)
	);
	
	assign WeightValid = WeightValidI;
	
	//Bias Memory
	BiasMemory BiasMemoryTopLevel (
		.Clk (Clk),
		.Reset (Reset),
		.ReadRequest (BiasReadRequest),
		.BiasAddressIn (BiasAddress),
		.BiasDataIn (BRAMDoutB),
		.BiasValid (BiasValid),
		.BiasAddress (BiasAddressToBRAM)
	);
	 
	 wire [63:0] BiasData = BRAMDoutB;
	 
	 //Input Buffer
	 
	 wire [63:0] InputBufferReadData;
	 
	 InputBuffer InputBufferTopLevel (
		.Clk (Clk),
		.Reset (Reset),
		
		.WriteValid (InputBufferWriteValid),
		.WriteData (InputBufferWriteData),
		.WriteReady (InputBufferWriteReady),
		.Commit (InputBufferCommit),
		.BufferFull (InputBufferFull),
		
		.ReadEnable (InputBufferReadEnable),
		.ReadAddress (InputBufferReadAddress),
		.ReadData (InputBufferReadData)
	);
	
	 //Scratchpad
	 wire [63:0] ScratchpadReadData;
	 wire [63:0] ReLuOutput;
	 
	 	
	Scratchpad ScratchpadTopLevel (
		.Clk (Clk),
		.Reset (Reset),
		.WriteEnable (ScratchpadWriteEnable),
		.WriteData (ReLuOutput),
		.ReadAddress (ScratchpadReadAddress),
		.ReadData (ScratchpadReadData)
	);
	assign ScratchpadReadDataOut = ScratchpadReadData[7:0];
	 
	 //MUX logic
	 //Full 64-bit scratchpad vector
	 wire [63:0] ScratchpadVec = ScratchpadReadData;
	 
	 //Broadcast scalar mode
	 wire [63:0] ScratchpadScalar = {8{ScratchpadReadData[7:0]}};
	 
	 //Multi-level mux
	 wire [63:0] ScratchpadSelected = (ScratchpadSelectSource == 1'b0) ? ScratchpadVec : ScratchpadScalar;
	 
	 //final MAC input A
	 wire [63:0] MACInputA = (MACSelectSource == 1'b0) ? InputBufferReadData : ScratchpadSelected;
	 
	 //MACInputB = weights
	 wire [63:0] MACInputB = BRAMDoutA;
	 
	 //MACArray
	 wire [63:0] MACOutput;
	 wire  [7:0] MACValidBus;
	 
	 MA_Array MACAR (
		.Clk (Clk),
		.Reset (Reset),
		.Enable (Enable),
		.Clear (Clear),
		.Input (MACInputA),
		.Weight (MACInputB),
		.CountConfigure (MACAccCount),
		.MACOut (MACOutput),
		.Valid (MACValidBus)
	);
	 
	assign MACValid = &MACValidBus;
	
	//Adder to ReLu
	wire [63:0] AdderOutput;
	wire [7:0] AdderCout;
	
	Adder_Array_RCA_8bit AdderAR (
		.A (BiasData),
		.B (MACOutput),
		.Cin (8'd0),
		.Sum (AdderOutput),
		.Cout (AdderCout)
	);
		
	Activation_Function_Block ReLu (
		.Clk (Clk),
		.Reset (Reset),
		.Input (AdderOutput),
		.Output (ReLuOutput)
	);

	wire [7:0] ArgmaxInputInternal;
	//if argmaxfromscratchpad = 1 -> use final layer outputs from scratchpad
	//else feed layuer outputs directly (macoutput or reluoutput)
	assign ArgmaxInputInternal = (ArgmaxFromScratchpad == 1'b1) ? ScratchpadReadData[7:0] : ReLuOutput[7:0];
	assign ArgmaxDataOut = ArgmaxInputInternal;
	
	assign ReLuOutputByte = ReLuOutput[7:0];

endmodule
