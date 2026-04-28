==================================================================================
Lewis Hunton Beng Electronics Engineering University of Manchester 
3rd Year Individual Project Software Repository 
FPGA Implementation of a MLP Artificial Neural Network Optimised for Size
==================================================================================

This repository contains
	1) Software reference models referred to within the report
	2) All Verilog design files 
		(excluding files containing copyrighted Opal Kelly files)
	3) All verification test benches and VHD exports
	4) User constraints file for XC3S1500 Spartan-3
	5) Synthesised full system .bit file
	6) A full system level diagram	




==================================================================================
What this software does
1) Contains 3 programs:
	A) main.py: First neural network model, floating point precision, exports weights. This is the "software reference model" in the report used for hardware decision making.

	B) NearHardwareAccurateNetwork.py: Emulates hardware system implemented, built off of the original main.py network model. Program produced evidence in Section 5.4 showing that the requantiser location caused collapsed of hardware accuracy.

	C) CompleteNNTest.py: Python front end for testing hardware file. Contains 2 functions, one for dataset testing of variable size and another for test case of full 0s




==================================================================================
Verilog file hierarchy
Counters.v (Copyright - Not provided)
	|-TopLevelNN.v
		|-NN_FSM.v
		|-Argmaax_output.v
		|-MACInputDataPath.v
			|-InputBuffer.v
			|-Scratchpad.v
			|-InputAdapter.v
			|-NNPackedMemory.xco
			|-MA_Array.v
				|-MAC_Unit.v
					|-BaughWooley_Multiplier_8bit.v
					|-MAC_Accumulator_64_16bit.v
					|-Requantiser_22to8bit.v
			|-Adder_array_RCA_8bit.v
				|-Ripple_Carry_Adder_8bit.v
					|-Full_adder.v
			|-Activation_Function_Block.v





==================================================================================
Software Model Install Instructions

This model was written in Python 3.13.7

///Prerequisites
- Visual Studio Code (https://code.visualstudio.com/)
- Python (https://www.python.org/downloads/)

///Step 1: Create a Virtual Environment
python -m venv venv

///Step 2: Activate the Virtual Environment
venv\Scripts\activate

///Step 3: Install Dependencies
pip install -r requirements.txt

///Step 5: Open in VS Code
main.py
NearHardwareAccurateNetwork.py
CompleteNNTest.py

///Step 5.5: If Testing CompleteNNTest.py with Hardware
• .bit file is required in the same directory as .py
• OpalKelly files are also required in the same directory:
	• ok.py
	• okFrontPanel.dll

///Step 6: Interpreter selection
1) Press Ctrl+Shift+P
2) Type "Python: Select Interpreter"
3) Choose venv

///Step 7: Running
Press "Run Python File"



==================================================================================
Xilinx ISE 14.2 Install Instructions

///Prerequisites
Oracle Virtual Box
Xilinx ISE 14.2 Installer 
(https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive.html)
At least 20GB of free disk space
Sufficient Allocated RAM to the VM

///Step 1
Run the Xilinx ISE 14.2 installer

///Step 2
• Follow the on-screen prompts
• After the VM is configured, verify sufficient RAM to prevent crashes.

///Step 3
Once complete, launch the VM and open Xilinx Project Navigator

///Step 4
Move all required files into the shared folder to access inside the ISE

///Step 5
Select new project and configure the project with the following settings:
	• Family: Spartan3
	• Device XC3S1500
	• Package: FG320
	• Speed: -4
	• Synthesis tool: XST
	• Simulator: ISim
	• Preferred Language: Verilog

///Step 6
Add all Verilog files as new sources
Aditionally (OpalKelly files):
	• Counters.v
	• okLibrary.v 

///Step 7: 
To Run Simulations: 
• Go to simulation view in left hand hierarchy
• Select the test bench to run
• Select simulate behavioral model



==================================================================================
Expected Software Outputs
• main.py:
9 Output graphs plotted together with exported weights and biases demonstrating hidden node count vs bit width vs activation function represented as accuracy.

• NearHardwareAccurateNetwork.py:
3 consecutive plots demonstrating expected hardware level accuracy as a matrix of hidden layer bit shifts against output layer bit shifts

• CompleteNNTest.py:
True value of inputs and hardware decisions and the total accuracy of the system 



==================================================================================
Known limitation:
• main.py computes serially and takes a long time to compute on slower processors