
module Gpu (
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
  O_HEX3, 
);

input	I_CLK;
input I_RST_N;
input	I_VIDEO_ON;

// GPU-SRAM interface
input       [15:0] I_GPU_DATA;
output reg  [15:0] O_GPU_DATA;
output reg  [17:0] O_GPU_ADDR;
output reg         O_GPU_WRITE;
output reg         O_GPU_READ;

// 7-segment display interface 

output [6:0] O_HEX0, O_HEX1, O_HEX2, O_HEX3;

/////////////////////////////////////////
// Example code goes here 
//
// ## Note
// It is highly recommended to play with this example code first so that you
// could get familiarized with a set of output ports. By doing so, you would
// get the hang of dealing with vector (graphics) objects in pixel frame.
/////////////////////////////////////////

/* Provided registers */
reg [26:0] count;
reg [9:0]  rowInd;
reg [9:0]  colInd;
reg init_phase; 

/* Our registers */
parameter x1 = 0;
parameter x2 = 200;
parameter y1 = 0;
parameter y2 = 200;

wire dy, dx;
reg [31:0] x, y, x1_new, x2_new, y1_new, y2_new;
reg [31:0] delta, offset, threshold, threshold_inc;
reg signed [31:0] m;
reg [31:0] abs_dy, abs_dx;
reg signed [2:0] adjust;

reg [0:0] in_triangle = 0;
reg [31:0] i, j;

assign dy = y2 - y1;
assign dx = x2 - x1;

initial begin	
	
	//abs_dy = (dy >= 0) ? dy : -dy;
	//abs_dx = (dx >= 0) ? dx : -dx;
	//adjust = ((dy >= 0 && dx >= 0) || (dy < 0 && dx < 0)) ? 1 : -1;
	m = 1;
	adjust = (m >= 0) ? 1 : -1;
 	offset = 0;
	
	if (/*abs_dy >= abs_dx*/ m >= -1 && m <= 1) begin
		delta = (dy > 0) ? dy * 2 : dy * -2;
		threshold = (dx > 0) ? dx : -dx;
		threshold_inc = threshold * 2;
		x1_new = x1;
		x2_new = x2;
		y = y1;
		if (x2 < x1) begin
			x1_new = x2;
			x2_new = x1;
			y = y2;
		end
		x = x1_new;
	end else begin
		delta = (dx > 0) ? dx * 2 : dx * -2;
		threshold = (dy > 0) ? dy : -dy;
		threshold_inc = threshold * 2;
		y1_new = y1;
		y2_new = y2;
		x = x1;
		if (y2 < y1) begin
			y1_new = y2;
			y2_new = y1;
			x = x2;
		end
		y = y1_new;
	end
end
				
always @(posedge I_CLK or negedge I_RST_N)
begin
	if (!I_RST_N) begin
		O_GPU_ADDR <= 16'h0000;
		O_GPU_WRITE <= 1'b1;
		O_GPU_READ <= 1'b0;
		O_GPU_DATA <= {4'hf, 4'hf, 4'hf, 4'hf};
		count <= 0;
	end else begin
		if (!I_VIDEO_ON) begin
			/* In Triangle Logic */
			if (/*abs_dy >= abs_dx*/ m >= -1 && m <= 1) begin
				if (x < x2_new) begin
					offset <= offset + delta;
					if (offset >= threshold) begin
						y <= y + adjust;
						threshold <= threshold + threshold_inc;
					end
					x <= x + 1;
					in_triangle <= 1;
				end else begin
					x <= x1_new;
					y <= (x2 < x1) ? y2 : y1;
					offset <= 0;
					threshold <= (dx > 0) ? dx : -dx;
					in_triangle <= 0;
				end
			end else begin
				if (y < y2_new) begin
					offset <= offset + delta;
					if (offset >= threshold) begin
						x <= x + adjust;
						threshold <= threshold + threshold_inc;
					end
					y <= y + 1;
				end
			end
		
		  	count <= count + 1;
			if (count[26] == 0) begin			
				O_GPU_ADDR <= x * 640 + y;
				O_GPU_WRITE <= 1'b1;
				O_GPU_READ <= 1'b0;
				if (in_triangle == 1 && rowInd == x && colInd == y)
					O_GPU_DATA <= {4'hf, 4'hf, 4'hf, 4'hf};	
				else 
					O_GPU_DATA <= {4'h0, 4'h0, 4'hf, 4'hf};
			end 
			/* reset the screen */ 		
			else if (count[26] == 1) begin 	
				O_GPU_ADDR <= x * 640 + y;
				O_GPU_WRITE <= 1'b1;
				O_GPU_READ <= 1'b0;
				if (in_triangle == 1 && rowInd == x && colInd == y)
					O_GPU_DATA <= {4'hf, 4'hf, 4'hf, 4'hf};	
				else 
					O_GPU_DATA <= {4'h0, 4'h4, 4'h3, 4'h0};
			end 	
		end 
	end
end

//SevenSeg sseg0(.IN(count[3:0]),.OUT(O_HEX0));
//SevenSeg sseg1(.IN(count[7:4]),.OUT(O_HEX1));
//SevenSeg sseg2(.IN(count[11:8]),.OUT(O_HEX2));
//SevenSeg sseg3(.IN(count[15:12]),.OUT(O_HEX3));

always @(posedge I_CLK or negedge I_RST_N)
begin
  if (!I_RST_N) begin
    colInd <= 0;
  end else begin
    if (!I_VIDEO_ON) begin
      if (colInd < 639)
        colInd <= colInd + 1;
      else
        colInd <= 0;
    end
  end
end

always @(posedge I_CLK or negedge I_RST_N)
begin
  if (!I_RST_N) begin
    rowInd <= 0;
  end else begin
    if (!I_VIDEO_ON) begin
      if (colInd == 0) begin
        if (rowInd < 399)
          rowInd <= rowInd + 1;
        else
          rowInd <= 0;
      end
    end
  end
end

endmodule
