`timescale 1ns/1ps
module gpu_test();
wire I_GPU_DATA, O_GPU_DATA, O_GPU_ADDR,
  O_GPU_READ,
  O_GPU_WRITE,
  O_HEX0,
  O_HEX1, 
  O_HEX2, 
  O_HEX3;
reg I_CLK, I_RST_N, I_VIDEO_ON;

Gpu gpu(
  I_CLK, 
  I_RST_N,
  I_VIDEO_ON, 
  // GPU-SRAM interface
  I_GPU_DATA, 
  O_GPU_DATA,
  O_GPU_ADDR,
  O_GPU_READ,
  O_GPU_WRITE,
  O_HEX0,
  O_HEX1, 
  O_HEX2, 
  O_HEX3);
  
  initial begin
		#1 I_CLK <= 1;
		#1 I_VIDEO_ON <= 0;
		#1 I_RST_N <= 0;
  end
  
  always
  #1 I_CLK = ~I_CLK;
  
  endmodule 

