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
reg [2:0] CCValue;
output reg [`VREG_WIDTH-1:0] O_VecSrc1Value; 
output reg [`VREG_WIDTH-1:0] O_VecDestValue;
output reg O_EX_Valid;

output reg[`REG_WIDTH-1:0] O_MARValue;
output reg[`REG_WIDTH-1:0] O_MDRValue;
    
output reg O_RegWEn;
output reg O_VRegWEn;
output reg O_CCWEn;
reg RegWEn, CCWEn;
 		    
// Signals to the front-end  (Note: suffix Signal means the output signal is not from reg) 
output reg [`PC_WIDTH-1:0] O_BranchPC_Signal;
output reg O_BranchAddrSelect_Signal;

reg [`PC_WIDTH-1:0] BranchPCAddress;
reg Branch_Signal_EF;

// Signals to the DE stage for dependency checking    
output O_RegWEn_Signal;
output O_VRegWEn_Signal;
output O_CCWEn_Signal;    

/////////////////////////////////////////
// WIRE/REGISTER DECLARATION GOES HERE
/////////////////////////////////////////
//assign O_RegWEn_Signal = (I_DE_Valid == 1) ? 1 : 0;

/////////////////////////////////////////
// ALWAYS STATEMENT GOES HERE
/////////////////////////////////////////
always @(*) begin
	Branch_Signal_EF = 0;
	BranchPCAddress = 0;

	case (I_Opcode)
		`OP_ADD_D: begin 
			ALU_O_DestValue = I_Src1Value + I_Src2Value;
			ALU_O_DestRegIdx = I_DestRegIdx; 
			CCValue = (ALU_O_DestValue < 0) ? 0 : (ALU_O_DestValue == 0) ? 1 : 2;
			RegWEn = 1; 
			CCWEn = 1;
		end

		`OP_ADD_F: begin 
			ALU_O_DestValue = I_Src1Value + I_Src2Value;
			ALU_O_DestRegIdx = I_DestRegIdx; 
			CCValue = (ALU_O_DestValue < 0) ? 0 : (ALU_O_DestValue == 0) ? 1 : 2;
			RegWEn = 1; 
			CCWEn = 1;
		end
		  
		`OP_ADDI_D: begin
			ALU_O_DestValue = I_Src1Value + I_Imm;
			ALU_O_DestRegIdx = I_DestRegIdx; 
			CCValue = (ALU_O_DestValue < 0) ? 0 : (ALU_O_DestValue == 0) ? 1 : 2;
			RegWEn = 1; 
			CCWEn = 1;
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
		end

		`OP_MOVI_F: begin 
		end

		`OP_VMOV: begin 
		end
		  
		`OP_VMOVI: begin 
		end
		 
		`OP_CMP: begin
		end

		`OP_CMPI: begin		  
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
			if (I_CCValue == 2) begin
				BranchPCAddress = I_PC + (I_Imm * 4);
				Branch_Signal_EF = 1;
			end
			CCValue = I_CCValue;
			CCWEn = 0;
		end

		`OP_BRN: begin
		end 

		`OP_BRZ: begin
		end

		`OP_BRNP: begin
		end

		`OP_BRZP: begin
		end 

		`OP_BRNZ: begin
		end 

		`OP_BRNZP: begin
		end 

		`OP_JMP: begin
		end

		`OP_JSR: begin
		end

		`OP_JSRR: begin
		end
		  
		default: begin
		end 
		
	endcase
end // always @ begin
   
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
		O_EX_Valid <= I_DE_Valid;

		O_DestRegIdx <= ALU_O_DestRegIdx;
		O_DestValue <= ALU_O_DestValue;
		O_RegWEn <= O_RegWEn_Signal;  
		O_CCWEn <= O_CCWEn_Signal;
		
		O_BranchPC_Signal <= BranchPCAddress;
		O_BranchAddrSelect_Signal <= Branch_Signal_EF;
		O_CCValue <= CCValue;
	end
	else begin // I_LOCK = 1'b0  
		O_EX_Valid <=1'b0;
		O_RegWEn <= 1'b0;
		O_VRegWEn <= 1'b0; 
		O_CCWEn <= 1'b0; 
	end 
end

endmodule // module Execute



