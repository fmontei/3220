`include "global_def.h"

module Execute(
  I_CLOCK,
  I_LOCK,
  I_PC,	       
  I_Opcode,
  I_IR, 	       
  I_Src1Value,
  I_Src2Value,
  I_DestRegIdx,
  I_DestVRegIdx,
  I_Imm,
  I_CCValue, 	       
  I_Idx, 
  I_VecSrc1Value,
  I_VecSrc2Value,
  I_DE_Valid, 
  I_GPUStallSignal, 
  O_LOCK,
  O_Opcode,
  O_IR, 	 
  O_PC,   
  O_R15PC,
  O_DestRegIdx,
  O_DestVRegIdx,	 
  O_DestValue,
  O_CCValue, 	       
  O_VecSrc1Value,
  O_VecDestValue,
  O_EX_Valid, 
  O_MARValue, 
  O_MDRValue,
  O_BranchPC_Signal, 
  O_BranchAddrSelect_Signal,
  O_RegWEn,
  O_VRegWEn,
  O_CCWEn,
  O_RegWEn_Signal,
  O_VRegWEn_Signal,
  O_CCWEn_Signal  
);

/////////////////////////////////////////
// IN/OUT DEFINITION GOES HERE
/////////////////////////////////////////
// Inputs from the decode stage
input I_CLOCK;
input I_LOCK;
input [`PC_WIDTH-1:0] I_PC;
input [`OPCODE_WIDTH-1:0] I_Opcode;
input [`IR_WIDTH-1:0] I_IR;   

input signed  [`REG_WIDTH-1:0] I_Src1Value;
input signed [`REG_WIDTH-1:0] I_Src2Value;
input [3:0] I_DestRegIdx;
input [`VREG_ID_WIDTH-1:0] I_DestVRegIdx;
input [`REG_WIDTH-1:0] I_Imm;
input [2:0] I_CCValue;

input [1:0] I_Idx; 
input [`VREG_WIDTH-1:0] I_VecSrc1Value; 
input [`VREG_WIDTH-1:0] I_VecSrc2Value; 

input I_DE_Valid;

// Stall signal from GPU stage    
input I_GPUStallSignal; 

// Outputs to the memory stage
output reg O_LOCK;
output reg [`OPCODE_WIDTH-1:0] O_Opcode;
output reg [`PC_WIDTH-1:0] O_PC;
output reg [`PC_WIDTH-1:0] O_R15PC;
output reg [`IR_WIDTH-1:0] O_IR;      
output reg [3:0] O_DestRegIdx;
reg [3:0] ALU_O_DestRegIdx;
output reg [`VREG_ID_WIDTH-1:0] O_DestVRegIdx;
output reg [`REG_WIDTH-1:0] O_DestValue;
reg signed [`REG_WIDTH-1:0] ALU_O_DestValue;
output reg [2:0] O_CCValue;   
output reg [`VREG_WIDTH-1:0] O_VecSrc1Value; 
output reg [`VREG_WIDTH-1:0] O_VecDestValue;
output reg O_EX_Valid;

output reg[`REG_WIDTH-1:0] O_MARValue;
output reg[`REG_WIDTH-1:0] O_MDRValue;
    
output reg O_RegWEn;
output reg O_VRegWEn;
output reg O_CCWEn;
reg RegWEn;
reg CCWEn;
reg [2:0] CCValue;
 		    
// Signals to the front-end  (Note: suffix Signal means the output signal is not from reg) 
output [`PC_WIDTH-1:0] O_BranchPC_Signal;
output O_BranchAddrSelect_Signal;
reg [`PC_WIDTH-1:0] My_O_BranchPC_Signal;
reg My_O_BranchAddrSelect_Signal;
reg [0:0] Branch_Was_Taken = 0;
reg[`REG_WIDTH-1:0] MARValue;
reg[`REG_WIDTH-1:0] MDRValue;

// Signals to the DE stage for dependency checking    
output  O_RegWEn_Signal;
output  O_VRegWEn_Signal;
output  O_CCWEn_Signal;    

/////////////////////////////////////////
// WIRE/REGISTER DECLARATION GOES HERE
/////////////////////////////////////////
wire [`REG_WIDTH-1:0] Imm32;
//assign O_RegWEn_Signal = (I_DE_Valid == 1) ? 1 : 0;

/////////////////////////////////////////
// ALWAYS STATEMENT GOES HERE
/////////////////////////////////////////
always @(*) begin
	case (I_Opcode)
		`OP_ADD_D: begin 
			ALU_O_DestValue = I_Src1Value + I_Src2Value;
			ALU_O_DestRegIdx = I_DestRegIdx; 
			RegWEn = 1;
			CCWEn = 1;
		end

		`OP_ADD_F: begin 
			ALU_O_DestValue = I_Src1Value + I_Src2Value;
			ALU_O_DestRegIdx = I_DestRegIdx; 
			CCWEn = 1;
			RegWEn = 1;

		end
		  
		`OP_ADDI_D: begin
			ALU_O_DestValue = I_Src1Value + I_Imm;
			ALU_O_DestRegIdx = I_DestRegIdx; 
			CCWEn = 1;
			RegWEn = 1;
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
			ALU_O_DestValue = I_Src1Value;
			ALU_O_DestRegIdx = I_DestRegIdx;
			CCWEn = 1;
			RegWEn = 1;
		end

		`OP_MOVI_D: begin 
			ALU_O_DestValue = I_Imm;
			ALU_O_DestRegIdx = I_DestRegIdx; 
			CCWEn = 1;
			RegWEn = 1;
		end

		`OP_MOVI_F: begin 
			ALU_O_DestValue = I_Imm;
			ALU_O_DestRegIdx = I_DestRegIdx; 
			CCWEn = 1;
			RegWEn = 1;
		end

		`OP_VMOV: begin 
		end
		  
		`OP_VMOVI: begin 
		end
		 
		`OP_CMP: begin
			ALU_O_DestValue = I_Src1Value - I_Src2Value;
			CCWEn = 1;
			RegWEn = 0;
		end

		`OP_CMPI: begin
			ALU_O_DestValue = I_Src1Value - I_Imm;
			CCWEn = 1;
			RegWEn = 0;
		end
		 
		`OP_VCOMPMOV: begin  
		end 

		`OP_VCOMPMOVI: begin  
		end 

		`OP_LDB: begin
		end

		`OP_LDW: begin
			MARValue = I_Src1Value + I_Imm;
			ALU_O_DestRegIdx = I_DestRegIdx; 
			CCWEn = 1;
			RegWEn = 1;
		end

		`OP_STB: begin
		end

		`OP_STW: begin
			MARValue = I_Src1Value + I_Imm;
			MDRValue = I_Src2Value;
			CCWEn = 0;
			RegWEn = 0;
		end

		`OP_BRP: begin
			if (I_CCValue == 3'b001 && I_DE_Valid == 1) begin
				 My_O_BranchPC_Signal = I_PC + (Imm32 * 4); 
				 My_O_BranchAddrSelect_Signal = 1;
				 Branch_Was_Taken = 1; 
			end else begin
				 My_O_BranchAddrSelect_Signal = 0;
				 Branch_Was_Taken = 0; 
			end
		end

		`OP_BRN: begin
			if (I_CCValue == 3'b100 && I_DE_Valid == 1) begin
				My_O_BranchPC_Signal = I_PC + (Imm32 * 4);
				My_O_BranchAddrSelect_Signal = 1;
				Branch_Was_Taken = 1;
			end else begin
				My_O_BranchAddrSelect_Signal = 0;
				Branch_Was_Taken = 0;
			end
		end 

		`OP_BRZ: begin
			if (I_CCValue == 3'b010 && I_DE_Valid == 1) begin
				My_O_BranchPC_Signal = I_PC + (Imm32 * 4);
				My_O_BranchAddrSelect_Signal = 1;
				Branch_Was_Taken = 1;
			end else begin
				My_O_BranchAddrSelect_Signal = 0;
				Branch_Was_Taken = 0;
			end
		end

		`OP_BRNP: begin
			if (((I_CCValue == 3'b100) || (I_CCValue == 3'b001)) && I_DE_Valid == 1) begin
				My_O_BranchPC_Signal = I_PC + (Imm32 * 4);
				My_O_BranchAddrSelect_Signal = 1;
				Branch_Was_Taken = 1;
			end else begin
				My_O_BranchAddrSelect_Signal = 0;
				Branch_Was_Taken = 0;
			end
		end

		`OP_BRZP: begin
			if (((I_CCValue == 3'b010) || (I_CCValue == 3'b001)) && I_DE_Valid == 1) begin
				My_O_BranchPC_Signal = I_PC + (Imm32 * 4);
				My_O_BranchAddrSelect_Signal = 1;
				Branch_Was_Taken = 1;
			end else begin
				My_O_BranchAddrSelect_Signal = 0;
				Branch_Was_Taken = 0;
			end
		end 

		`OP_BRNZ: begin
			if (((I_CCValue == 3'b100) || (I_CCValue == 3'b010)) && I_DE_Valid == 1) begin
				My_O_BranchPC_Signal = I_PC + (Imm32 * 4);
				My_O_BranchAddrSelect_Signal = 1;
				Branch_Was_Taken = 1;
			end else begin
				My_O_BranchAddrSelect_Signal = 0;
				Branch_Was_Taken = 0;
			end
		end 

		`OP_BRNZP: begin
			if (((I_CCValue == 3'b100) || (I_CCValue == 3'b010) || (I_CCValue == 3'b001)) && I_DE_Valid == 1) begin
				My_O_BranchPC_Signal = I_PC + (Imm32 * 4);
				My_O_BranchAddrSelect_Signal = 1;
				Branch_Was_Taken = 1;
			end else begin
				My_O_BranchAddrSelect_Signal = 0;
				Branch_Was_Taken = 0;
			end
		end 

		`OP_JMP: begin
		end

		`OP_JSR: begin
		end

		`OP_JSRR: begin
		end
		
		`OP_HALT: begin
			My_O_BranchPC_Signal = I_PC - 4; // Re-execute the halt instruction ad infinitum
			My_O_BranchAddrSelect_Signal = 1;
		end
		  
		default: begin
		end 
	endcase
	
	if (ALU_O_DestValue > 0)
		CCValue = 3'b001;
	else if (ALU_O_DestValue < 0)
		CCValue = 3'b100;
	else if (ALU_O_DestValue == 0)
		CCValue = 3'b010;
end // always @ begin

assign O_BranchPC_Signal = My_O_BranchPC_Signal;
assign O_BranchAddrSelect_Signal = (I_IR[31:27] == 5'b11011 || I_Opcode == `OP_HALT) 
											? My_O_BranchAddrSelect_Signal : 0;
	
assign O_RegWEn_Signal = (I_DE_Valid) ? RegWEn : 0;
assign O_CCWEn_Signal = (I_DE_Valid) ? CCWEn : 0;

/////////////////////////////////////////
// ## Note ##
// - Do the appropriate ALU operations.
/////////////////////////////////////////

always @(negedge I_CLOCK) begin
	O_LOCK <= I_LOCK;
	O_Opcode <= I_Opcode;

	if (I_LOCK == 1'b1) begin
		O_PC <= I_PC;
		O_IR <= I_IR;
		
		// Checking if last instruction was a branch instruction &
		// if it was taken, then clearly the instruction right after the branch instruction is invalid
		if (O_IR[31:27] == 5'b11011 && Branch_Was_Taken == 1) begin 
			O_EX_Valid <= 0;
		end else begin
			O_EX_Valid <= I_DE_Valid;
		end

		O_DestRegIdx <= ALU_O_DestRegIdx;
		O_DestValue <= ALU_O_DestValue;
		O_RegWEn <= O_RegWEn_Signal; 
		O_CCWEn <= O_CCWEn_Signal;
		O_MARValue <= MARValue;
		O_MDRValue <= MDRValue;
		if (O_CCWEn_Signal == 1) begin
			O_CCValue <= CCValue;
		end else begin
			O_CCValue <= I_CCValue;
		end
		 
	end else begin // I_LOCK = 1'b0  
		O_EX_Valid <= 1'b0;
		O_RegWEn <= 1'b0;
		O_VRegWEn <= 1'b0; 
		O_CCWEn <= 1'b0; 
	end 
end

SignExtension SE0(.In(I_IR[15:0]), .Out(Imm32));


endmodule // module Execute



