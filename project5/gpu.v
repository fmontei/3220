
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
reg [31:0] ax, ay, bx, by, cx, cy;
reg [31:0] x, y, min_x, min_y, max_x, max_y;
reg signed [31:0] e1, e2, e3;

reg [0:0] in_triangle;

initial begin
	/* test case triangle 1 */
	ax = 1; ay = 1; bx = 200; by = 100; cx = 50; cy = 50;
	min_x = (ax < bx && ax < cx) ? ax :
			  (bx < ax && bx < cx) ? bx :
			  /*(cx < ax && cx < bx)8?*/ cx;
	min_y = (ay < by && ay < cy) ? ay :
			  (by < ay && by < cy) ? by :
			  /*(cx > ax && cx > bx)8?*/ cy;		
	max_x = (ax > bx && ax > cx) ? ax :
			  (bx > ax && bx > cx) ? bx :
			  /*(cx < ax && cx < bx)8?*/ cx;
	max_y = (ay > by && ay > cy) ? ay :
			  (by > ay && by > cy) ? by :
			  /*(cx > ax && cx > bx)8?*/ cy;	  
	x = min_x;
	y = min_y;
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
			if (y < max_y) begin
				if (x < max_x) begin
					
					e1 <= -(cy - by) * (x - bx) + (cx - bx) * (y - by);
					e2 <= -(ay - cy) * (x - cx) + (ax - cx) * (y - cy);
					e3 <= -(by - ay) * (x - ax) + (bx - ax) * (y - ay);
					if (e1 > 0 && e2 > 0 && e3 > 0) begin
						in_triangle <= 1;
					end else begin
						in_triangle <= 0;
					end
				
					x <= x + 1;
				end else begin
					x <= min_x;
				end
				y <= y + 1;
			end else begin
				y <= min_y;
			end
		
		  	count <= count + 1;
			if (count[25] == 0) begin			
				O_GPU_ADDR <= x * 640 + y;
				O_GPU_WRITE <= 1'b1;
				O_GPU_READ <= 1'b0;
				if (in_triangle == 1 && rowInd == x && colInd == y)
					O_GPU_DATA <= {4'h0, 4'h0, 4'h0, 4'h0};	
				else 
					O_GPU_DATA <= {4'hf, 4'hf, 4'hf, 4'hf};
			end 
			/* reset the screen */ 		
			else if (count[25] == 1) begin 	
				O_GPU_ADDR <= rowInd * 640 + colInd;
				O_GPU_WRITE <= 1'b1;
				O_GPU_READ <= 1'b0;
				O_GPU_DATA <= {4'h0, 4'h0, 4'h0, 4'h0};
			end 		
		end 
	end
end

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