`include "global_def.h"

module Decode(
  I_CLOCK,
  I_LOCK,
  I_PC,
  I_IR,
  I_FE_Valid, 	
  I_WriteBackRegIdx,
  I_WriteBackVRegIdx,	      
  I_WriteBackData,
  I_CCValue,
  I_WriteBackPC,
  I_WriteBackPCEn,
  I_VecSrc1Value,
  I_VecSrc2Value,
  I_VecDestValue,
  I_RegWEn, 
  I_VRegWEn, 	 
  I_CCWEn,
  I_EDDestRegIdx,
  I_EDDestVRegIdx,
  I_EDDestWrite,
  I_EDDestVWrite,
  I_MDDestRegIdx,
  I_MDDestVRegIdx,
  I_MDDestWrite,
  I_MDDestVWrite,
  I_EDCCWEn,
  I_MDCCWEn,
  I_GPUStallSignal, 
  O_LOCK,
  O_PC,
  O_Opcode,
  O_IR, 	      
  O_Src1Value,
  O_Src2Value,
  O_DestRegIdx,
  O_DestVRegIdx,
  O_Idx, 
  O_Imm,
  O_DepStallSignal,
  O_BranchStallSignal,
  O_CCValue, 	      
  O_VecSrc1Value,
  O_VecSrc2Value,
  O_DE_Valid
);

reg dep_stall;
reg de_valid;
reg br_stall; 


/////////////////////////////////////////
// IN/OUT DEFINITION GOES HERE
/////////////////////////////////////////

// Inputs from the fetch stage
input I_CLOCK;
input I_LOCK;
input [`PC_WIDTH-1:0] I_PC;
input [`IR_WIDTH-1:0] I_IR;
input I_FE_Valid;
    

// Inputs from the writeback stage
input [3:0] I_WriteBackRegIdx;
input [`VREG_ID_WIDTH-1:0] I_WriteBackVRegIdx;
input [`REG_WIDTH-1:0] I_WriteBackData;
input [2:0] 	       I_CCValue;
input [`PC_WIDTH-1:0] I_WriteBackPC;   
input I_WriteBackPCEn;

input [`VREG_WIDTH-1:0] I_VecSrc1Value; 
input [`VREG_WIDTH-1:0] I_VecSrc2Value; 
input [`VREG_WIDTH-1:0] I_VecDestValue; 

/* input from EX and Mem stage for dependency checking */ 

input I_RegWEn;
input I_VRegWEn;
input I_CCWEn;
input I_EDCCWEn;
input I_MDCCWEn;

input [3:0] I_EDDestRegIdx;
input [`VREG_ID_WIDTH-1:0] I_EDDestVRegIdx;
input [3:0] I_MDDestRegIdx;
input [`VREG_ID_WIDTH-1:0] I_MDDestVRegIdx; 

// Are instructions indeed write to a register ? 

input I_EDDestWrite;   
input I_EDDestVWrite;
input I_MDDestWrite;
input I_MDDestVWrite;

/* pipeline stall due to GPU stage */ 

input I_GPUStallSignal;  
 	
// Outputs to the execude stage
output reg O_LOCK; 
output reg [`PC_WIDTH-1:0] O_PC;
output reg [`OPCODE_WIDTH-1:0] O_Opcode;
output reg [`IR_WIDTH-1:0] O_IR;   
output reg [`REG_WIDTH-1:0] O_Src1Value;
output reg [`REG_WIDTH-1:0] O_Src2Value;
output reg [3:0] O_DestRegIdx; // destination register id 
output reg [`VREG_ID_WIDTH-1:0] O_DestVRegIdx;  // vector destination register id 
output reg [1:0] O_Idx;  // Vec component output id
output reg [`REG_WIDTH-1:0] O_Imm;
output reg [2:0] O_CCValue; // current CC value (source operand)
    
output reg [`VREG_WIDTH-1:0] O_VecSrc1Value; 
output reg [`VREG_WIDTH-1:0] O_VecSrc2Value; 

output reg O_DE_Valid;
   
/////////////////////////////////////////
// ## Note ##
// O_DepStall: Asserted when current instruction should be waiting for data dependency resolves. 
/////////////////////////////////////////
output reg O_DepStallSignal;  

// Outputs to the fetch stage
// Output to the fetch stage should not 
output reg O_BranchStallSignal;

/////////////////////////////////////////
// WIRE/REGISTER DECLARATION GOES HERE
/////////////////////////////////////////
//
// Architectural Registers
reg [`REG_WIDTH-1:0] RF[0:`NUM_RF-1]; // Scalar Register File (R0-R7: Integer, R8-R15: Floating-point)
reg [`VREG_WIDTH-1:0] VRF[0:`NUM_VRF-1]; // Vector Register File

// Valid bits for tracking the register dependence information
reg RF_VALID[0:`NUM_RF-1]; // Valid bits for Scalar Register File
reg VRF_VALID[0:`NUM_VRF-1]; // Valid bits for Vector Register File

wire [`REG_WIDTH-1:0] Imm32; // Sign-extended immediate value
reg [2:0] ConditionalCode; // Set based on the written-back result



/////////////////////////////////////////
// INITIAL/ASSIGN STATEMENT GOES HERE
/////////////////////////////////////////
//
reg[7:0] trav;

initial begin
	dep_stall = 0;
	br_stall = 0;
	for (trav = 0; trav < `NUM_RF; trav = trav + 1'b1) begin
		RF[trav] = 0;
		RF_VALID[trav] = 1;  
	end 

	for (trav = 0; trav < `NUM_VRF; trav = trav + 1'b1) begin
		VRF[trav] = 0;
		VRF_VALID[trav] = 1;  
	end 

	ConditionalCode = 0;
	RF[0] = 16'b0000000000000010;

	O_PC = 0;
	O_Opcode = 0;
	O_DepStallSignal = 0;
end // Initial

// Decode module
reg [3:0] I_DestRegIdx;
reg [`REG_WIDTH-1:0] Src1Value;
reg [`REG_WIDTH-1:0] Src2Value;
reg [`REG_WIDTH-1:0] Imm;
reg [3:0] DestRegIdx;   

wire [2:0] CCValue;
reg [1:0] Idx; 
reg [`VREG_WIDTH-1:0] VecSrc1Value; 
reg [`VREG_WIDTH-1:0] VecSrc2Value; 
wire [`OPCODE_WIDTH-1:0] Opcode;
reg [`VREG_ID_WIDTH-1:0] DestVRegIdx;   
assign CCValue = ConditionalCode;
assign Opcode = I_IR[31:24];

/////////////////////////////////////////
// ALWAYS STATEMENT GOES HERE
/////////////////////////////////////////
always @(*) begin
	//O_DE_Valid <= I_FE_Valid;
	case (Opcode)
		`OP_ADD_D: begin 
			Src1Value = RF[I_IR[19:16]];
			Src2Value = RF[I_IR[11:8]];
			DestRegIdx = I_IR[23:20];
			/* Check both source registers for a RAW data dependency */
			if (((I_IR[19:16] == I_EDDestRegIdx) && I_EDDestWrite)  || 
				((I_IR[19:16] == I_MDDestRegIdx) && I_MDDestWrite) ||
				((I_IR[11:8] == I_EDDestRegIdx)  && I_EDDestWrite) || 
				((I_IR[11:8] == I_MDDestRegIdx)  && I_MDDestWrite))
				dep_stall = 1;
			else 
				dep_stall = 0;
		end

		`OP_ADD_F: begin 
			Src1Value = RF[I_IR[19:16]];
			Src2Value = RF[I_IR[11:8]];
			DestRegIdx = I_IR[23:20];
			if (((I_IR[19:16] == I_EDDestRegIdx) && I_EDDestWrite)  || 
				((I_IR[19:16] == I_MDDestRegIdx) && I_MDDestWrite) ||
				((I_IR[11:8] == I_EDDestRegIdx)  && I_EDDestWrite) || 
				((I_IR[11:8] == I_MDDestRegIdx)  && I_MDDestWrite))
				dep_stall = 1;
			else 
				dep_stall = 0;
		end
		  
		`OP_ADDI_D: begin
			Src1Value = RF[I_IR[19:16]];
			DestRegIdx = I_IR[23:20];
			/* Only one source register exists for this instruction */
			if (((I_IR[19:16] == I_EDDestRegIdx) && I_EDDestWrite) || 
				((I_IR[19:16] == I_MDDestRegIdx) && I_MDDestWrite))
				dep_stall = 1;
			else 
				dep_stall = 0;
		end

		`OP_ADDI_F: begin

		end

		`OP_VADD: begin 

		end

		`OP_AND_D: begin

		end

		`OP_ANDI_D: begin

		end
		
		`OP_MOV: begin 
		end

		`OP_MOVI_D: begin 
			DestRegIdx = I_IR[19:16];
		end

		`OP_MOVI_F: begin 
			DestRegIdx = I_IR[19:16];
		end

		`OP_VMOV: begin 
		end
		  
		`OP_VMOVI: begin 
		end
		 
		`OP_CMP: begin
		end

		`OP_CMPI: begin	
			Src1Value = RF[I_IR[19:16]];
			if (((I_IR[19:16] == I_EDDestRegIdx) && I_EDDestWrite) || 
				((I_IR[19:16] == I_MDDestRegIdx) && I_MDDestWrite))
				dep_stall = 1;
			else 
				dep_stall = 0;
		end
		 
		`OP_VCOMPMOV: begin  
		end 

		`OP_VCOMPMOVI: begin  
		end 

		`OP_LDB: begin
		end

		`OP_LDW: begin
		end

		`OP_STB: begin
		end

		`OP_STW: begin
		end

		`OP_BRP: begin
			//br_stall = 1;
			if (I_EDCCWEn == 1 || I_MDCCWEn == 1)
		       dep_stall = 1;
			else
				 dep_stall = 0;
		end

		`OP_BRN: begin
			//br_stall = 1;
			if (I_EDCCWEn == 1 || I_MDCCWEn == 1)
		       dep_stall = 1;
			else
				 dep_stall = 0;
		end 

		`OP_BRZ: begin
			//br_stall = 1;
			if (I_EDCCWEn == 1 || I_MDCCWEn == 1)
		       dep_stall = 1;
			else
				 dep_stall = 0;
		end

		`OP_BRNP: begin
			//br_stall = 1;
			if (I_EDCCWEn == 1 || I_MDCCWEn == 1)
		       dep_stall = 1;
			else
				 dep_stall = 0;
		end

		`OP_BRZP: begin
			//br_stall = 1;
			if (I_EDCCWEn == 1 || I_MDCCWEn == 1)
		       dep_stall = 1;
			else
				 dep_stall = 0;
		end 

		`OP_BRNZ: begin
			//br_stall = 1;
			if (I_EDCCWEn == 1 || I_MDCCWEn == 1)
		        dep_stall = 1;
			else
				 dep_stall = 0;
		end 

		`OP_BRNZP: begin
			//br_stall = 1;
			if (I_EDCCWEn == 1 || I_MDCCWEn == 1)
		       dep_stall = 1;
			else
				 dep_stall = 0;
		end 

		`OP_JMP: begin
		end

		`OP_JSR: begin
		end

		`OP_JSRR: begin
		end
		  
		default: begin
			dep_stall = 0;
			br_stall = 0;
		end
		
	endcase // case (IR[31:24])
	
 
	if ((I_IR[31:27] == 5'b11011) ||
		 (I_IR[31:24] == `OP_JMP) ||
		 (I_IR[31:24] == `OP_JSR) ||
		 (I_IR[31:24] == `OP_JSRR))
		br_stall = 1;
	else
		br_stall = 0;
		
  if (I_FE_Valid == 1) begin
		O_BranchStallSignal = br_stall;
		O_DepStallSignal = dep_stall;
   end else begin 
		O_BranchStallSignal = 0;
		O_DepStallSignal = 0;
	end

end

   
/////////////////////////////////////////
// ## Note ##
// First half clock cycle to write data back into the register file 
// 1. To write data back into the register file
// 2. Update Conditional Code to the following branch instruction to refer
/////////////////////////////////////////
always @(posedge I_CLOCK) begin
	/////////////////////////////////////////////
	// TODO: Complete here 
	/////////////////////////////////////////////
	if (I_LOCK == 1'b1) begin
		// Register write should come here 
		if (I_RegWEn == 1) begin
			RF[I_WriteBackRegIdx] = I_WriteBackData;
		end
		if (I_CCWEn == 1) begin
			ConditionalCode = I_CCValue;
		end
	end // if (I_LOCK == 1'b1)
end // always @(posedge I_CLOCK)

/////////////////////////////////////////
// ## Note ##
// Second half clock cycle to read data from the register file
// 1. To read data from the register file
// 2. To update valid bit for the corresponding register (for both writeback instruction and current instruction) 
/////////////////////////////////////////
always @(negedge I_CLOCK) begin
	O_LOCK <= I_LOCK;

	if (I_LOCK == 1'b1) begin
		O_PC <= I_PC;
		O_IR <= I_IR;
		O_Opcode <= I_IR[31:24];
		/////////////////////////////////////////////
		// TODO: Complete here 
		/////////////////////////////////////////////
		O_Src1Value <= Src1Value;
		O_Src2Value <= Src2Value;
		O_DestRegIdx <= DestRegIdx;
		O_Imm <= Imm32;
		//O_DE_Valid <= I_FE_Valid
		//O_DE_Valid <= (dep_stall == 1) ? 0 : 1;
		if (dep_stall == 0 && br_stall == 0) begin
			O_DE_Valid <= 1;
		end else if (dep_stall == 1 && br_stall == 0) begin 
			O_DE_Valid <= 0;
		end else if (dep_stall == 1 && br_stall == 1) begin
			O_DE_Valid <= 0;
		end else if (dep_stall == 0 && br_stall == 1) begin
			O_DE_Valid <= 1;
		end
		O_CCValue <= I_CCValue;
	end // if (I_LOCK == 1'b1)
	else begin 
	end 
end // always @(negedge I_CLOCK)

SignExtension SE0(.In(I_IR[15:0]), .Out(Imm32));

endmodule // module Decode
