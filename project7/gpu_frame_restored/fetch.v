`include "global_def.h"

module Fetch(
  I_CLOCK,
  I_LOCK,
  I_BranchPC,
  I_BranchAddrSelect,
  I_BranchStallSignal,
  I_DepStallSignal,
  I_GPUStallSignal, 
  O_LOCK,
  O_PC,
  O_IR,
  O_FE_Valid 	     
);

/////////////////////////////////////////
// IN/OUT DEFINITION GOES HERE
/////////////////////////////////////////

// Inputs from high-level module (lg_highlevel)
input I_CLOCK;
input I_LOCK;

// Inputs from the memory stage 
input [`PC_WIDTH-1:0] I_BranchPC; // Branch Target Address
input I_BranchAddrSelect; // Asserted only when Branch Target Address resolves

// Inputs from the decode stage
input I_BranchStallSignal; // Asserted from when branch instruction is decoded; 
input I_DepStallSignal; // Asserted when register dependency is detected in the decode stage 
input I_GPUStallSignal; // Assserted when a GPU stall the piepline in the GPU stage  

// Outputs to the decode stage
output reg O_LOCK;
output reg [`PC_WIDTH-1:0] O_PC;
output reg [`IR_WIDTH-1:0] O_IR;
output reg  O_FE_Valid;
reg [`PC_WIDTH-1:0] PC_Inc;
 
/////////////////////////////////////////
// WIRE/REGISTER DECLARATION GOES HERE
/////////////////////////////////////////
reg[`INST_WIDTH-1:0] InstMem[0:`INST_MEM_SIZE-1];

/////////////////////////////////////////
// INITIAL/ASSIGN STATEMENT GOES HERE
/////////////////////////////////////////
initial begin
	$readmemh("test_branch.hex", InstMem);

	O_LOCK = 1'b0;
	O_PC = 16'h0;
	O_IR = 32'hFF000000;
end


wire [`INST_MEM_ADDR_SIZE-3:0] PC_line;
wire FE_valid_out;
//wire [`INST_MEM_ADDR_SIZE-3:0]PC_4_Value;
//wire latch_keep;
wire [`IR_WIDTH-1:0] IR_out;

assign PC_line = O_PC[`INST_MEM_ADDR_SIZE-1:2];
assign IR_out = InstMem[PC_line];
//assign PC_4_Value = O_PC + 4;
//assign latch_keep  = ((I_DepStallSignal == 1 && I_BranchStallSignal == 0) || (I_DepStallSignal == 1 && I_BranchStallSignal ==1)) ? 1 : 0;
reg latch_keep;
reg fe_valid;
reg branch;
reg [2:0] branch_bubble_count = 0;
reg [0:0] branch_detected = 0;

//always*
always @(*) begin
	PC_Inc = O_PC + 4;
	if (I_BranchAddrSelect == 1)
		PC_Inc = I_BranchPC;
	if (I_BranchStallSignal == 0 && I_DepStallSignal == 0) begin
		fe_valid = 1;
		latch_keep = 0;
	end else if (I_BranchStallSignal == 0 && I_DepStallSignal == 1) begin
		fe_valid = 1;
		latch_keep = 1;
	end else if (I_BranchStallSignal == 1 && I_DepStallSignal == 0) begin
		fe_valid = 0;
		latch_keep = 0;
	end else if (I_BranchStallSignal == 1 && I_DepStallSignal == 1) begin
		fe_valid = 1;
		latch_keep = 1;
	end 
	
end
//  
/////////////////////////////////////////
// ## Note ##
// 1. Update output values (O_PC, O_IR) and PC.
// 2. You should be careful about STALL signals.
/////////////////////////////////////////
always @(negedge I_CLOCK) begin      
	O_LOCK <= I_LOCK;

	if (I_LOCK == 0) begin
		O_PC <= 0;
		O_IR <= IR_out;
		if (I_BranchStallSignal == 1)
			O_FE_Valid <= 1; 
	end else begin // if (I_LOCK == 1)
		/////////////////////////////////////////////
		// TODO: Complete here
		/////////////////////////////////////////////
		
		/* This code memorizes a read-in branch instruction. Then, it introduces 
		 * 2 bubbles into the pipeline (O_IR <= 32'hFF000000: this opcode does
		 * not exist, so does nothing. 
		 *
		 * Blocking and non-blocking assignments are "mixed together" but this
		 * is just to make the code more readable. The assignments should
		 * remain exactly as they are for this to work. branch_detected 
		 * must be immediately initialized to 1 following a BranchStallSignal.
		 */
		if (I_BranchStallSignal == 1) begin
			branch_detected = 1;
			branch_bubble_count <= 0;
		end else if (I_BranchStallSignal == 0 && branch_detected == 1) begin
			branch_bubble_count <= branch_bubble_count + 1;
			if (branch_bubble_count == 2) begin
				branch_detected = 0;
			end
		end
		
		if (I_BranchAddrSelect == 1) begin
			O_PC <= I_BranchPC;
			O_IR <= IR_out;
		end else begin
			if (I_BranchStallSignal == 0 && branch_detected == 1) begin
				O_PC <= O_PC;
				O_IR <= 32'hFF000000; // NOP
			end else begin
				O_PC <= (latch_keep) ? O_PC : PC_Inc;
				O_IR <= (latch_keep) ? O_IR : IR_out; 
			end
		end
		
//		if (I_BranchStallSignal == 1 && I_DepStallSignal == 0)
//			O_FE_Valid <= 0;
//		else
//			O_FE_Valid <= 1;
		O_FE_Valid <= fe_valid;
	end // if (I_LOCK == 0)
end // always @(negedge I_CLOCK)

endmodule // module Fetch
