#include <iostream>
#include <fstream>
#include <sstream>
#include <assert.h>
#include <vector>
#include <bitset>
#include <stdint.h>
#include <string.h> 
#include <cstring> 
#include <limits.h> 
#include <stdlib.h>
// #include <cstdint> 
#include "simulator.h"

#define FLOAT_TO_FIXED1114(n) ((int)((n) * (float)(1<<(4)))) & 0xffff
#define FIXED_TO_FLOAT1114(n) ((float)(-1*((n>>15)&0x1)*(1<<11)) + (float)((n&(0x7fff)) / (float)(1<<4)))
#define FIXED1114_TO_INT(n) (( (n>>15)&0x1) ?  ((n>>4)|0xf000) : (n>>4)) 
#define DEBUG

using namespace std;

///////////////////////////////////
///  architectural structures /// 
///////////////////////////////////

ScalarRegister g_condition_code_register; // store conditional code 
ScalarRegister g_scalar_registers[NUM_SCALAR_REGISTER];  
VectorRegister g_vector_registers[NUM_VECTOR_REGISTER];

VertexRegister g_gpu_vertex_registers[NUM_VERTEX_REGISTER]; 
ScalarRegister g_gpu_status_register; 
 
unsigned char g_memory[MEMORY_SIZE]; // data memory 

////////////////////////////////////

vector<TraceOp> g_trace_ops;

unsigned int g_instruction_count = 0;
unsigned int g_vertex_id = 0; 
unsigned int g_current_pc = 0; 
unsigned int g_program_halt = 0; 

////////////////////////////////////////////////////////////////////////
// desc: Set g_condition_code_register depending on the values of val1 and val2
// hint: bit0 (N) is set only when val1 < val2
// bit 2: negative 
// bit 1: zero
// bit 0: positive 
////////////////////////////////////////////////////////////////////////
void SetConditionCodeInt(const int16_t val1, const int16_t val2) 
{
	/* fill out the conditional code checking logic */ 
	g_condition_code_register.int_value = 0;
	if (val1 < val2) {
		g_condition_code_register.int_value |= 4; // 0001 
	} else if (val1 == val2) {
		g_condition_code_register.int_value |= 2; // 0010
	} else {
		g_condition_code_register.int_value |= 1; // 0100
	}
}

////////////////////////////////////////////////////////////////////////
// Initialize global variables
////////////////////////////////////////////////////////////////////////
void InitializeGlobalVariables() 
{
  g_vertex_id = 0;  // internal setting variables 
  memset(&g_condition_code_register, 0x00, sizeof(ScalarRegister));
  memset(&g_gpu_status_register, 0x00, sizeof(ScalarRegister));
  memset(g_scalar_registers, 0x00, sizeof(ScalarRegister) * NUM_SCALAR_REGISTER);
  memset(g_vector_registers, 0x00, sizeof(VectorRegister) * NUM_VECTOR_REGISTER);
  memset(g_gpu_vertex_registers, 0x00, sizeof(VertexRegister) * NUM_VERTEX_REGISTER);
  memset(g_memory, 0x00, sizeof(unsigned char) * MEMORY_SIZE);
}

////////////////////////////////////////////////////////////////////////
// desc: Convert 16-bit 2's complement signed integer to 32-bit
////////////////////////////////////////////////////////////////////////
int SignExtension(const int16_t value) 
{
  return (value >> 15) == 0 ? value : ((0xFFFF << 16) | value);
}

////////////////////////////////////////////////////////////////////////
// desc: Decode binary-encoded instruction and Parse into TraceOp structure
//       which we will use execute later
// input: 32-bit encoded instruction
// output: TraceOp structure filled with the information provided from the input
////////////////////////////////////////////////////////////////////////
TraceOp DecodeInstruction(const uint32_t instruction) 
{
  TraceOp ret_trace_op;
  memset(&ret_trace_op, 0x00, sizeof(ret_trace_op));

  uint8_t opcode = (instruction & 0xFF000000) >> 24;
  ret_trace_op.opcode = opcode;

  switch (opcode) {
   
		case OP_ADD_D: 
		{
			int destination_register_idx = (instruction & 0x00F00000) >> 20;
			int source_register_1_idx = (instruction & 0x000F0000) >> 16;
			int source_register_2_idx = (instruction & 0x00000F00) >> 8;
			ret_trace_op.scalar_registers[0] = destination_register_idx;
			ret_trace_op.scalar_registers[1] = source_register_1_idx;
			ret_trace_op.scalar_registers[2] = source_register_2_idx;
		}
		break;

		case OP_ADD_F: 
		{
			int destination_register_idx = (instruction & 0x00F00000) >> 20;
			int source_register_1_idx = (instruction & 0x000F0000) >> 16;
			int source_register_2_idx = (instruction & 0x00000F00) >> 8;
			ret_trace_op.scalar_registers[0] = destination_register_idx;
			ret_trace_op.scalar_registers[1] = source_register_1_idx;
			ret_trace_op.scalar_registers[2] = source_register_2_idx;
		}		 
		break;

		case OP_ADDI_D:
		{	
			int destination_register_idx = (instruction & 0x00F00000) >> 20;
			int source_register_idx = (instruction & 0x000F0000) >> 16;
			int immediate_value = (instruction & 0x0000FFFF);
			ret_trace_op.scalar_registers[0] = destination_register_idx;
			ret_trace_op.scalar_registers[1] = source_register_idx;
			ret_trace_op.int_value = immediate_value;
		}
		break;

		case OP_ADDI_F: 
		{	
			int destination_register_idx = (instruction & 0x00F00000) >> 20;
			int source_register_idx = (instruction & 0x000F0000) >> 16;
			int immediate_value = (instruction & 0x0000FFFF);
			ret_trace_op.scalar_registers[0] = destination_register_idx;
			ret_trace_op.scalar_registers[1] = source_register_idx;
			ret_trace_op.int_value = immediate_value;
		}
		break;

		case OP_VADD:
		{
			int destination_register_idx = (instruction & 0x003F0000) >> 16;
			int source_register_1_idx = (instruction & 0x00003F00) >> 8;
			int source_register_2_idx = (instruction & 0x0000003F);
			ret_trace_op.vector_registers[0] = destination_register_idx;
			ret_trace_op.vector_registers[1] = source_register_1_idx;
			ret_trace_op.vector_registers[2] = source_register_2_idx;
		}
		break;

		case OP_AND_D:
		{
			int destination_register_idx = (instruction & 0x00F00000) >> 20;
			int source_register_1_idx = (instruction & 0x000F0000) >> 16;
			int source_register_2_idx = (instruction & 0x00000F00) >> 8;
			ret_trace_op.scalar_registers[0] = destination_register_idx;
			ret_trace_op.scalar_registers[1] = source_register_1_idx;
			ret_trace_op.scalar_registers[2] = source_register_2_idx;
		}		 
		break;

		case OP_ANDI_D:
		{	
			int destination_register_idx = (instruction & 0x00F00000) >> 20;
			int source_register_idx = (instruction & 0x000F0000) >> 16;
			int immediate_value = (instruction & 0x0000FFFF);
			ret_trace_op.scalar_registers[0] = destination_register_idx;
			ret_trace_op.scalar_registers[1] = source_register_idx;
			ret_trace_op.int_value = immediate_value;
		}
		break;

		case OP_MOV: 
		{
			int destination_register_idx = (instruction & 0x000F0000) >> 16;
			int source_register_idx = (instruction & 0x00000F00) >> 8;
			ret_trace_op.scalar_registers[0] = destination_register_idx;
			ret_trace_op.scalar_registers[1] = source_register_idx;
		}
		break;

		case OP_MOVI_D:
		{
			int destination_register_idx = (instruction & 0x000F0000) >> 16;
			int immediate_value = (instruction & 0x0000FFFF);
			ret_trace_op.scalar_registers[0] = destination_register_idx;
			ret_trace_op.int_value = immediate_value;
		}
		break;

		case OP_MOVI_F:
		{
			int destination_register_idx = (instruction & 0x000F0000) >> 16;
			int immediate_value = (instruction & 0x0000FFFF);
			ret_trace_op.scalar_registers[0] = destination_register_idx;
			ret_trace_op.int_value = immediate_value;
		}
		break;

		case OP_VMOV:  
		{
			int destination_register_idx = (instruction & 0x003F0000) >> 16;
			int source_register_idx = (instruction & 0x00003F00) >> 8;
			ret_trace_op.vector_registers[0] = destination_register_idx;
			ret_trace_op.vector_registers[1] = source_register_idx;
		}
		break;

		case OP_VMOVI: 
		{
			int destination_register_idx = (instruction & 0x003F0000) >> 16;
			int immediate_value = (instruction & 0x0000FFFF);
			ret_trace_op.vector_registers[0] = destination_register_idx;
			ret_trace_op.int_value = immediate_value;
		}
		break;

		case OP_CMP: 
		{
			int source_register_1_idx = (instruction & 0x000F0000) >> 16;
			int source_register_2_idx = (instruction & 0x00000F00) >> 8;
			ret_trace_op.scalar_registers[0] = source_register_1_idx; 
			ret_trace_op.scalar_registers[1] = source_register_2_idx;
		}
		break; 

		case OP_CMPI:
		{
			int source_register_1_idx = (instruction & 0x000F0000) >> 16;
			int immediate_value = (instruction & 0x0000FFFF);
			ret_trace_op.scalar_registers[0] = source_register_1_idx; 
			ret_trace_op.int_value = immediate_value;
		}
		break; 

		case OP_VCOMPMOV: 
		{
			int index = (instruction & 0x00C00000) >> 22;
			int destination_register_idx = (instruction & 0x003F0000) >> 16;
			int source_register_idx = (instruction & 0x00000F00) >> 8;
			ret_trace_op.vector_registers[0] = destination_register_idx; 
			ret_trace_op.scalar_registers[1] = source_register_idx;
			ret_trace_op.idx = index;
		}
		break; 

		case OP_VCOMPMOVI: 
		{
			int index = (instruction & 0x00C00000) >> 22;
			int destination_register_idx = (instruction & 0x003F0000) >> 16;
			int immediate_value = (instruction & 0x0000FFFF);
			ret_trace_op.vector_registers[0] = destination_register_idx; 
			ret_trace_op.int_value = immediate_value;
			ret_trace_op.idx = index;
		}
		break; 

		case OP_LDB: 
		{
			int destination_register_idx = (instruction & 0x00F00000) >> 20;
			int base = (instruction & 0x000F0000) >> 16;
			int offset = (instruction & 0x0000FFFF);
			ret_trace_op.scalar_registers[0] = destination_register_idx; 
			ret_trace_op.scalar_registers[1] = base;
			ret_trace_op.int_value = offset;
		}
		break;

		/* The notes say "dest <- mem[base+offset+1: base+offset]". What
		* exactly does that mean? */
		case OP_LDW:
		{
			int destination_register_idx = (instruction & 0x00F00000) >> 20;
			int base = (instruction & 0x000F0000) >> 16;
			int offset = (instruction & 0x0000FFFF);
			ret_trace_op.scalar_registers[0] = destination_register_idx; 
			ret_trace_op.scalar_registers[1] = base;
			ret_trace_op.int_value = offset;
		}
		break;

		case OP_STB:
		{
			int source_register_idx = (instruction & 0x00F00000) >> 20;
			int base = (instruction & 0x000F0000) >> 16;
			int offset = (instruction & 0x0000FFFF);
			ret_trace_op.scalar_registers[0] = source_register_idx; 
			ret_trace_op.scalar_registers[1] = base;
			ret_trace_op.int_value = offset;
		}
		break;

		/* The notes say "dest <- mem[base+offset+1: base+offset]". What
		* exactly does that mean? */
		case OP_STW: 
		{
			int source_register_idx = (instruction & 0x00F00000) >> 20;
			int base = (instruction & 0x000F0000) >> 16;
			int offset = (instruction & 0x0000FFFF);
			ret_trace_op.scalar_registers[0] = source_register_idx; 
			ret_trace_op.scalar_registers[1] = base;
			ret_trace_op.int_value = offset;
		}
		break;

		case OP_SETVERTEX: 
		{
			int vector_register_idx = (instruction & 0x003F0000) >> 16;
			ret_trace_op.vector_registers[0] = vector_register_idx;
		}
		break; 

		case OP_SETCOLOR:
		{
			int vector_register_idx = (instruction & 0x003F0000) >> 16;
			ret_trace_op.vector_registers[0] = vector_register_idx;
		}
		break; 

		case OP_ROTATE:  // optional
		{
			int vector_register_idx = (instruction & 0x003F0000) >> 16;
			ret_trace_op.vector_registers[0] = vector_register_idx;
		}
		break; 

		case OP_TRANSLATE: 
		{
			int vector_register_idx = (instruction & 0x003F0000) >> 16;
			ret_trace_op.vector_registers[0] = vector_register_idx;
		}
		break; 

		case OP_SCALE:  // optional 
		{
			int vector_register_idx = (instruction & 0x003F0000) >> 16;
			ret_trace_op.vector_registers[0] = vector_register_idx;
		}
		break; 

		case OP_PUSHMATRIX:       // deprecated 
		break;

		case OP_POPMATRIX:   // deprecated 
		break; 

		case OP_BEGINPRIMITIVE: 
		{
			g_vertex_id = 0;
			int primitive_type = (instruction & 0x000F0000) >> 16;
			ret_trace_op.primitive_type = primitive_type;
		}
		break;

		case OP_ENDPRIMITIVE:
		break;

		case OP_LOADIDENTITY:  // deprecated 
		break;

		case OP_FLUSH: 
		break;

		case OP_DRAW: 
		break;

		case OP_BRN: 
		{
			int pc_offset = (instruction & 0x0000FFFF);
			ret_trace_op.int_value = pc_offset;
		}
		break;

		case OP_BRZ:
		{
			int pc_offset = (instruction & 0x0000FFFF);
			ret_trace_op.int_value = pc_offset;
		}
		break;

		case OP_BRP:
		{
			int pc_offset = (instruction & 0x0000FFFF);
			ret_trace_op.int_value = pc_offset;
		}
		break;

		case OP_BRNZ:
		{
			int pc_offset = (instruction & 0x0000FFFF);
			ret_trace_op.int_value = pc_offset;
		}
		break;

		case OP_BRNP:
		{
			int pc_offset = (instruction & 0x0000FFFF);
			ret_trace_op.int_value = pc_offset;
		}
		break;

		case OP_BRZP:
		{
			int pc_offset = (instruction & 0x0000FFFF);
			ret_trace_op.int_value = pc_offset;
		}
		break;

		case OP_BRNZP:
		{
			int pc_offset = (instruction & 0x0000FFFF);
			ret_trace_op.int_value = pc_offset;
		}
		break;

		/* This op code is equivalent to OP_RET, since OP_RET is a special 
		* case of OP_JIMP, in which PC is loaded with the value in R7. */
		case OP_JMP:
		{
			const int base_reg_idx = (instruction & 0x000F0000) >> 16;
			ret_trace_op.scalar_registers[0] = base_reg_idx ;
		}
		break;

		case OP_JSR: 
		{
			int pc_offset = (instruction & 0x0000FFFF);
			ret_trace_op.int_value = pc_offset;
		}
		break;

		case OP_JSRR: 
		{ 
			int baseR = (instruction & 0x000F0000) >> 16; 
			ret_trace_op.scalar_registers[0] = baseR; 
		} 
		break;

		case OP_HALT: 
		break; 

		default:
		break;
	}

  return ret_trace_op;
}

////////////////////////////////////////////////////////////////////////
// desc: Execute the behavior of the instruction (Simulate)
// input: Instruction to execute 
// output: Non-branch operation ? -1 : OTHER (PC-relative or absolute address)
////////////////////////////////////////////////////////////////////////
int ExecuteInstruction(const TraceOp &trace_op) 
{
	int ret_next_instruction_idx = -1;

	uint8_t opcode = trace_op.opcode;
	switch (opcode) {
		case OP_ADD_D: 
		{
			int source_value_1 = g_scalar_registers[trace_op.scalar_registers[1]].int_value;
			int source_value_2 = g_scalar_registers[trace_op.scalar_registers[2]].int_value;
			g_scalar_registers[trace_op.scalar_registers[0]].int_value = source_value_1 + source_value_2;
			SetConditionCodeInt(g_scalar_registers[trace_op.scalar_registers[0]].int_value, 0);
		}
		break;

		case OP_ADD_F:  
		{
			int source_value_1 = g_scalar_registers[trace_op.scalar_registers[1]].int_value;
			int source_value_2 = g_scalar_registers[trace_op.scalar_registers[2]].int_value;
			g_scalar_registers[trace_op.scalar_registers[0]].int_value = source_value_1 + source_value_2;
			SetConditionCodeInt(g_scalar_registers[trace_op.scalar_registers[0]].int_value, 0);
		}
		break; 

		case OP_ADDI_D:
		{
			int source_value_1 = g_scalar_registers[trace_op.scalar_registers[1]].int_value;
			int immediate_value = trace_op.int_value;
			g_scalar_registers[trace_op.scalar_registers[0]].int_value = source_value_1 + immediate_value;
			SetConditionCodeInt(g_scalar_registers[trace_op.scalar_registers[0]].int_value, 0);
		}
		break;

		case OP_ADDI_F: 
		{
			int source_value_1 = g_scalar_registers[trace_op.scalar_registers[1]].int_value;
			int immediate_value = trace_op.int_value;
			g_scalar_registers[trace_op.scalar_registers[0]].int_value = source_value_1 + immediate_value;
			SetConditionCodeInt(g_scalar_registers[trace_op.scalar_registers[0]].int_value, 0);
		}
		break;

		case OP_VADD:
		{
			VectorRegister *destination = &g_vector_registers[trace_op.vector_registers[0]];
			VectorRegister *source1 = &g_vector_registers[trace_op.vector_registers[1]];
			VectorRegister *source2 = &g_vector_registers[trace_op.vector_registers[2]];
			for (int i = 0; i < NUM_VECTOR_ELEMENTS; i++) {
				destination->element[i].int_value = source1->element[i].int_value + source2->element[i].int_value;
			}
		}
		break;
		
		case OP_AND_D:
		{
			int source_value_1 = g_scalar_registers[trace_op.scalar_registers[1]].int_value;
			int source_value_2 = g_scalar_registers[trace_op.scalar_registers[2]].int_value;  
			int destination_idx = trace_op.scalar_registers[0];
			int result = source_value_1 & source_value_2;
			g_scalar_registers[destination_idx].int_value = result;
			SetConditionCodeInt(result, 0);
		}
		break;
		
		case OP_ANDI_D:
		{
			int source_value_1 = g_scalar_registers[trace_op.scalar_registers[1]].int_value;
			int immediate_value = trace_op.int_value;
			g_scalar_registers[trace_op.scalar_registers[0]].int_value = source_value_1 & immediate_value;
			SetConditionCodeInt(g_scalar_registers[trace_op.scalar_registers[0]].int_value, 0);
		}
		break; 
		
		case OP_MOV: 
		{
			int dest_idx = trace_op.scalar_registers[0];
			int source_idx = trace_op.scalar_registers[1];
			g_scalar_registers[dest_idx].int_value = g_scalar_registers[source_idx].int_value;
			SetConditionCodeInt(g_scalar_registers[dest_idx].int_value, 0);
		}
		break;

		case OP_MOVI_D:
		{
			int immediate_value = trace_op.int_value;
			g_scalar_registers[trace_op.scalar_registers[0]].int_value = immediate_value;
			SetConditionCodeInt(g_scalar_registers[trace_op.scalar_registers[0]].int_value, 0);
		}
		break;

		case OP_MOVI_F: 
		{
			int immediate_value = trace_op.int_value;
			int dest_idx = trace_op.scalar_registers[0];
			g_scalar_registers[dest_idx].int_value = immediate_value;
			SetConditionCodeInt(g_scalar_registers[dest_idx].int_value, 0);
		}
		break; 
		
		case OP_VMOV:  
		{
			VectorRegister *source = &g_vector_registers[trace_op.vector_registers[1]];
			VectorRegister *destination = &g_vector_registers[trace_op.vector_registers[0]];
			for (int idx = 0; idx < NUM_VECTOR_ELEMENTS; idx++) {
				destination->element[idx] = source->element[idx];
			}
		}
		break; 
		
		case OP_VMOVI: 
		{ 
			int immediate_value = trace_op.int_value;
			int dest_vertex_idx = trace_op.vector_registers[0];
			for (int i = 0; i < NUM_VECTOR_ELEMENTS; i++) {
				g_vector_registers[dest_vertex_idx].element[i].int_value = immediate_value;
			}
		}
		break;
		
		case OP_CMP: 
		{
			int source_value_1 = g_scalar_registers[trace_op.scalar_registers[0]].int_value;
			int source_value_2 = g_scalar_registers[trace_op.scalar_registers[1]].int_value;
			SetConditionCodeInt(source_value_1, source_value_2);
		}
		break;
		
		case OP_CMPI:
		{
			int source_idx = trace_op.scalar_registers[0];
			int immediate_value = trace_op.int_value;
			int source_value = g_scalar_registers[source_idx].int_value;
			SetConditionCodeInt(source_value, immediate_value);
		}
		break;
		
		case OP_VCOMPMOV: 
		{
			ScalarRegister *source = &g_scalar_registers[trace_op.scalar_registers[1]];
			VectorRegister *destination = &g_vector_registers[trace_op.vector_registers[0]];
			const int idx = trace_op.idx;
			destination->element[idx].int_value = source->int_value;
		}
		break;
		
		case OP_VCOMPMOVI: 
		{
			VectorRegister *destination = &g_vector_registers[trace_op.vector_registers[0]];
			const int immediate_value = trace_op.int_value;
			const int idx = trace_op.idx;
			destination->element[idx].int_value = immediate_value;
		}
		break;		
		
		case OP_LDB: 
		{
			ScalarRegister *base = &g_scalar_registers[trace_op.scalar_registers[1]];
			ScalarRegister *destination = &g_scalar_registers[trace_op.scalar_registers[0]];
			const int memory_address = base->int_value + trace_op.int_value;
			assert(memory_address < MEMORY_SIZE);
			destination->int_value = g_memory[memory_address];
		}
		break;
		
		case OP_LDW:
		{
			int dest_idx = trace_op.scalar_registers[0];
			int base_reg_idx = trace_op.scalar_registers[1];
			int offset = trace_op.int_value;
			int address = g_scalar_registers[base_reg_idx].int_value + offset;
			int first_byte = g_memory[address];
			int second_byte = g_memory[address + 1];
			g_scalar_registers[dest_idx].int_value = (first_byte << 8) | second_byte;
			SetConditionCodeInt(g_scalar_registers[dest_idx].int_value, 0);
		}
		break;
		
		case OP_STB:  
		{
			ScalarRegister *base = &g_scalar_registers[trace_op.scalar_registers[1]];
			ScalarRegister *source = &g_scalar_registers[trace_op.scalar_registers[0]];
			const int memory_address = base->int_value + trace_op.int_value;
			assert(memory_address < MEMORY_SIZE);
			g_memory[memory_address] = source->int_value;
		}
		break;
		
		case OP_STW: 
		{
			int source_idx = trace_op.scalar_registers[0];
			int first_byte = g_scalar_registers[source_idx].int_value & 0xFF;
			int second_byte = g_scalar_registers[source_idx].int_value >> 8;
			int base_reg_idx = trace_op.scalar_registers[1];
			int offset = trace_op.int_value;
			int address = g_scalar_registers[base_reg_idx].int_value + offset;
			g_memory[address] = first_byte;
			g_memory[address + 1] = second_byte;
		}
		break;
		
		case OP_SETVERTEX: 
		{
			int primitive_type = (g_gpu_status_register.int_value >> 2) & 0x3;
			assert(primitive_type >= 0 || primitive_type <= 2);
			VectorRegister *vector = &g_vector_registers[trace_op.vector_registers[0]];
			VertexRegister *current_vertex = &g_gpu_vertex_registers[g_vertex_id];
			current_vertex->x_value = FIXED1114_TO_INT(vector->element[1].int_value); 
			current_vertex->y_value = FIXED1114_TO_INT(vector->element[2].int_value); 
			current_vertex->z_value = FIXED1114_TO_INT(vector->element[3].int_value);
			printf("SET VERTEX, old g_vertex_id = %d\n", g_vertex_id);
			g_vertex_id = (g_vertex_id + 1) % 3;
		}
		break; 
		
		case OP_SETCOLOR:
		{
			VectorRegister *vector = &g_vector_registers[trace_op.vector_registers[0]];
			VertexRegister *current_vertex = &g_gpu_vertex_registers[0];
			current_vertex->r_value = FIXED1114_TO_INT(vector->element[0].int_value); 
			current_vertex->g_value = FIXED1114_TO_INT(vector->element[1].int_value); 
			current_vertex->b_value = FIXED1114_TO_INT(vector->element[2].int_value); 
		}
		break; 
		
		case OP_ROTATE:  // optional  
		break; 
		
		case OP_TRANSLATE:
		{
			VectorRegister *vector = &g_vector_registers[trace_op.vector_registers[0]];
			VertexRegister *current_vertex = &g_gpu_vertex_registers[g_vertex_id];
			current_vertex->x_value = current_vertex->x_value + FIXED1114_TO_INT(vector->element[1].int_value);
			current_vertex->y_value = current_vertex->y_value + FIXED1114_TO_INT(vector->element[2].int_value);
			printf("current_vertex->x_value = %d\n", current_vertex->x_value);
			printf("current_vertex->y_value = %d\n", current_vertex->y_value);
		}
		break; 
		
		case OP_SCALE:  // optional 
		break;
		
		case OP_PUSHMATRIX:       // deprecated 
		break;
		
		case OP_POPMATRIX:   // deprecated 
		break;
		
		case OP_BEGINPRIMITIVE: 
		{
			const int primitive_type = trace_op.primitive_type;
			assert(primitive_type == 0 || primitive_type == 1);
			if (primitive_type == 0) { // Lines
				g_gpu_status_register.int_value &= 0xFFFFFFF3; // LSB bits: 0011
			} else if (primitive_type == 1) { // Triangles
				g_gpu_status_register.int_value &= 0xFFFFFFF7; // LSB bits: 0111
			}
		}
		break; 
		
		case OP_ENDPRIMITIVE: // deprecated
		break;
		
		case OP_LOADIDENTITY: // deprecated 
		break;
		
		/* Flush (Empty) the contents of the frame buffer. */
		case OP_FLUSH: 
		{
			g_gpu_status_register.int_value &= 0xFFFFFFFE; // LSB bits: 1110 
		}
		break;
		
		/* Draw the contents of the frame buffer on a screen (if available).
		 * Also, this instruction indicates the beginning of frame.
		 */
		case OP_DRAW:
		{
			g_gpu_status_register.int_value &= 0xFFFFFFFD; // LSB bits: 1101 
		}
		break; 
		
		case OP_BRN: 
		{
			const int pc_offset = trace_op.int_value;
			if (g_condition_code_register.int_value == 4) {
				return SignExtension(pc_offset);	
			}
		}
		break; 
		
		case OP_BRZ:
		{
			const int pc_offset = trace_op.int_value;
			if (g_condition_code_register.int_value == 2) {
				return SignExtension(pc_offset);	
			}
		}
		break; 
		
		case OP_BRP:
		{
			if (g_condition_code_register.int_value == 1) {
				const int pc_offset = trace_op.int_value;
				return SignExtension(pc_offset);				
			}
		}
		break; 
		
		case OP_BRNZ:
		{
			const int pc_offset = trace_op.int_value;
			if (g_condition_code_register.int_value == 4 || 
				g_condition_code_register.int_value == 2) {
				return SignExtension(pc_offset);	
			}
		}
		break; 
		
		case OP_BRNP:
		{
			const int pc_offset = trace_op.int_value;
			if (g_condition_code_register.int_value == 1 || 
				g_condition_code_register.int_value == 4) {
				return SignExtension(pc_offset);	
			}
		}
		break; 
		
		case OP_BRZP:
		{
			const int pc_offset = trace_op.int_value;
			if (g_condition_code_register.int_value == 2 || 
				g_condition_code_register.int_value == 1) {
				return SignExtension(pc_offset);	
			}
		}
		break; 
		
		case OP_BRNZP:
		{
			const int pc_offset = trace_op.int_value;
			if (g_condition_code_register.int_value == 1 || 
				g_condition_code_register.int_value == 2 ||
				g_condition_code_register.int_value == 4) {
				return SignExtension(pc_offset);	
			}
		}
		break; 
		
		case OP_JMP:
		{
			const int base_reg_value = g_scalar_registers[trace_op.scalar_registers[0]].int_value;
			return base_reg_value / 4;
		}
		break;
		
		case OP_JSR: 
		{
			const int pc_offset = trace_op.int_value;
			return pc_offset;
		}
		break; 
		
		case OP_JSRR: 
		{
			const int base_reg_value = g_scalar_registers[trace_op.scalar_registers[0]].int_value;
			return base_reg_value / 4;
		}
		break; 
		  
		case OP_HALT: 
			g_program_halt = 1; 
		break; 

		default:
		break;
	}

	return ret_next_instruction_idx;
}

////////////////////////////////////////////////////////////////////////
// desc: Dump given trace_op
////////////////////////////////////////////////////////////////////////
void PrintTraceOp(const TraceOp &trace_op) 
{  
  cout << "  opcode: " << SignExtension(trace_op.opcode);
  cout << ", scalar_register[0]: " << (int) trace_op.scalar_registers[0];
  cout << ", scalar_register[1]: " << (int) trace_op.scalar_registers[1];
  cout << ", scalar_register[2]: " << (int) trace_op.scalar_registers[2];
  cout << ", vector_register[0]: " << (int) trace_op.vector_registers[0];
  cout << ", vector_register[1]: " << (int) trace_op.vector_registers[1];
  cout << ", idx: " << (int) trace_op.idx;
  cout << ", primitive_index: " << (int) trace_op.primitive_type;
  cout << ", int_value: " << (int) trace_op.int_value << endl; 
  //c  cout << ", float_value: " << (float) trace_op.float_value << endl;
}

////////////////////////////////////////////////////////////////////////
// desc: This function is called every trace is executed
//       to provide the contents of all the registers
////////////////////////////////////////////////////////////////////////
void PrintContext(const TraceOp &current_op)
{

  cout << "--------------------------------------------------" << endl;
  cout << "3220X-Instruction Count: " << g_instruction_count
       << " C_PC: " << (g_current_pc *4)
       << " C_PC_IND: " << g_current_pc 
       << ", Curr_Opcode: " << current_op.opcode
       << " NEXT_PC: " << ((g_scalar_registers[PC_IDX].int_value)<<2) 
       << " NEXT_PC_IND: " << (g_scalar_registers[PC_IDX].int_value)
       << ", Next_Opcode: " << g_trace_ops[g_scalar_registers[PC_IDX].int_value].opcode 
       << endl;
  cout <<"3220X-"; 
  for (int srIdx = 0; srIdx < NUM_SCALAR_REGISTER; srIdx++) {
    cout << "R" << srIdx << ":" 
         << ((srIdx < 8 || srIdx == 15) ? SignExtension(g_scalar_registers[srIdx].int_value) : (float) FIXED_TO_FLOAT1114(g_scalar_registers[srIdx].int_value)) 
         << (srIdx == NUM_SCALAR_REGISTER-1 ? "" : ", ");
  }

  cout << " CC :N: " << ((g_condition_code_register.int_value &0x4) >>2) << " Z: " 
       << ((g_condition_code_register.int_value &0x2) >>1) << " P: " << (g_condition_code_register.int_value &0x1) << "  "; 
  cout << " draw: " << (g_gpu_status_register.int_value &0x01) << " fush: " << ((g_gpu_status_register.int_value & 0x2)>>1) ;
  cout << " prim_type: "<< ((g_gpu_status_register.int_value & 0x4) >> 2)  << " "; 
   
  cout << endl;
  
  // for (int vrIdx = 0; vrIdx < NUM_VECTOR_REGISTER; vrIdx++) {
  
  for (int vrIdx = 0; vrIdx < 6; vrIdx++) {
    cout <<"3220X-"; 
    cout << "V" << vrIdx << ":";
    for (int elmtIdx = 0; elmtIdx < NUM_VECTOR_ELEMENTS; elmtIdx++) { 
      cout << "Element[" << elmtIdx << "] = " 
           << (float)FIXED_TO_FLOAT1114(g_vector_registers[vrIdx].element[elmtIdx].int_value) 
           << (elmtIdx == NUM_VECTOR_ELEMENTS-1 ? "" : ",");
    }
    cout << endl;
  }
  cout << endl;
  cout <<"3220X-"; 
  cout <<" vertices P1_X: " << g_gpu_vertex_registers[0].x_value; 
  cout <<" vertices P1_Y: " << g_gpu_vertex_registers[0].y_value; 
  cout <<" r: " << g_gpu_vertex_registers[0].r_value; 
  cout <<" g: " << g_gpu_vertex_registers[0].g_value; 
  cout <<" b: " << g_gpu_vertex_registers[0].b_value; 
  cout <<" P2_X: " << g_gpu_vertex_registers[1].x_value; 
  cout <<" P2_Y: " << g_gpu_vertex_registers[1].y_value; 
  cout <<" r: " << g_gpu_vertex_registers[1].r_value; 
  cout <<" g: " << g_gpu_vertex_registers[1].g_value; 
  cout <<" b: " << g_gpu_vertex_registers[1].b_value; 
  cout <<" P3_X: " << g_gpu_vertex_registers[2].x_value; 
  cout <<" P3_Y: " << g_gpu_vertex_registers[2].y_value; 
  cout <<" r: " << g_gpu_vertex_registers[2].r_value; 
  cout <<" g: " << g_gpu_vertex_registers[2].g_value; 
  cout <<" b: " << g_gpu_vertex_registers[2].b_value << endl; 
  
  cout << "--------------------------------------------------" << endl;
}

int main(int argc, char **argv) 
{
  ///////////////////////////////////////////////////////////////
  // Initialize Global Variables
  ///////////////////////////////////////////////////////////////
  //
  InitializeGlobalVariables();

  ///////////////////////////////////////////////////////////////
  // Load Program
  ///////////////////////////////////////////////////////////////
  //
  if (argc != 2) {
    cerr << "Usage: " << argv[0] << " <input>" << endl;
    return 1;
  }

  ifstream infile(argv[1]);
  if (!infile) {
    cerr << "Error: Failed to open input file " << argv[1] << endl;
    return 1;
  }
  vector< bitset<sizeof(uint32_t)*CHAR_BIT> > instructions;
  while (!infile.eof()) {
    bitset<sizeof(uint32_t)*CHAR_BIT> bits;
    infile >> bits;
    if (infile.eof())  break;
    instructions.push_back(bits);
  }
  
  infile.close();

#ifdef DEBUG
  cout << "The contents of the instruction vectors are :" << endl;
  for (vector< bitset<sizeof(uint32_t)*CHAR_BIT> >::iterator ii =
      instructions.begin(); ii != instructions.end(); ii++) {
    cout << "  " << *ii << endl;
  }
#endif // DEBUG

  ///////////////////////////////////////////////////////////////
  // Decode instructions into g_trace_ops
  ///////////////////////////////////////////////////////////////
  //
  for (vector< bitset<sizeof(uint32_t)*CHAR_BIT> >::iterator ii =
      instructions.begin(); ii != instructions.end(); ii++) {
    uint32_t inst = (uint32_t) ((*ii).to_ulong());
    TraceOp trace_op = DecodeInstruction(inst);
    g_trace_ops.push_back(trace_op);
  }

#ifdef DEBUG
  cout << "The contents of the g_trace_ops vectors are :" << endl;
  for (vector<TraceOp>::iterator ii = g_trace_ops.begin();
      ii != g_trace_ops.end(); ii++) {
    PrintTraceOp(*ii);
  }
#endif // DEBUG

  ///////////////////////////////////////////////////////////////
  // Execute 
  ///////////////////////////////////////////////////////////////
  //
  g_scalar_registers[PC_IDX].int_value = 0;
  for (;;) {
    TraceOp current_op = g_trace_ops[g_scalar_registers[PC_IDX].int_value];
    int idx = ExecuteInstruction(current_op);
    g_current_pc = g_scalar_registers[PC_IDX].int_value; // debugging purpose only 
    if (current_op.opcode == OP_JSR || current_op.opcode == OP_JSRR)
      g_scalar_registers[LR_IDX].int_value = (g_scalar_registers[PC_IDX].int_value + 1) << 2 ;
    
    g_scalar_registers[PC_IDX].int_value += 1; 
    if (idx != -1) { // Branch
      if (current_op.opcode == OP_JMP || current_op.opcode == OP_JSRR) // Absolute addressing
        g_scalar_registers[PC_IDX].int_value = idx; 
      else // PC-relative addressing (OP_JSR || OP_BRXXX)
        g_scalar_registers[PC_IDX].int_value += idx; 
    }

#ifdef DEBUG
    g_instruction_count++;
    PrintContext(current_op);
#endif // DEBUG

    if (g_program_halt == 1) 
      break;
  }

  return 0;
}

