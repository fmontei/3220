
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

/* Our registers & wires */
reg [10:0] ax, ay, bx, by, cx, cy;
reg [10:0] x, y;
reg [0:0] in_triangle, outside_triangle;
reg signed [31:0] e1;
reg signed [31:0] e2;
reg signed [31:0] e3;

wire [31:0] min_x, min_y, max_x, max_y;
assign min_x = (ax < bx && ax < cx) ? ax :
					(bx < ax && bx < cx) ? bx :
					/*(cx < ax && cx < bx)*/ cx;
assign min_y = (ay < by && ay < cy) ? ay :
				   (by < ay && by < cy) ? by :
				   /*(cx > ax && cx > bx)*/ cy;		
assign max_x = (ax > bx && ax > cx) ? ax :
				   (bx > ax && bx > cx) ? bx :
				   /*(cx < ax && cx < bx)*/ cx;
assign max_y = (ay > by && ay > cy) ? ay :
				   (by > ay && by > cy) ? by :
				   /*(cx > ax && cx > bx)*/ cy;

initial begin
	/* test case triangle 1 */
	ax = 1; ay = 1; bx = 200; by = 100; cx = 50; cy = 50;	
	/* test case triangle 2 */
	//ax = 100; ay = 100; bx = 200; by = 100; cx = 200; cy = 200;	
	/* test case triangle 3 */
	//ax = 100; ay = 100; bx = 200; by = 100; cx = 200; cy = 1;	
	/* test case triangle 4 */
	//ax = 20; ay = 20; bx = 100; by = 1; cx = 1; cy = 1;	
	/* test case triangle 5 */
	//ax = 1; ay = 1; bx = 100; by = 90; cx = 20; cy = 100;	
	x = 0;
	y = 0;
	in_triangle = 0;
	outside_triangle = 1;
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
			if (y <= 639) begin
				if (x <= 399) begin
					outside_triangle <= 0;
					if (x >= min_x && x <= max_x && y >= min_y && y <= max_y) begin
						e1 <= (-(cy - by) * (x - bx)) + ((cx - bx) * (y - by));
						e2 <= (-(ay - cy) * (x - cx)) + ((ax - cx) * (y - cy));
						e3 <= (-(by - ay) * (x - ax)) + ((bx - ax) * (y - ay));
					end else begin
						outside_triangle <= 1;
					end
					in_triangle <= (e1 > 0 && e2 > 0 && e3 > 0) ? 1 : 0;
					x <= x + 1;
				end else begin
					x <= 0;
					y <= y + 1;
				end
			end else begin
				y <= 0;
			end
		
		  	count <= count + 1;
			if (count[24] == 0) begin
				O_GPU_ADDR <= x * 640 + y;
				O_GPU_WRITE <= 1'b1;
				O_GPU_READ <= 1'b0;
				if (in_triangle == 1)
					O_GPU_DATA <= {4'h0, 4'h0, 4'h0, 4'h0};	
				else if (in_triangle == 0 || outside_triangle == 1)
					O_GPU_DATA <= {4'hf, 4'hf, 4'hf, 4'hf};
			end 
			/* reset the screen */ 		
			else if (count[24] == 1) begin 	
				O_GPU_ADDR <= x * 640 + y;
				O_GPU_WRITE <= 1'b1;
				O_GPU_READ <= 1'b0;
				if (in_triangle == 1)
					O_GPU_DATA <= {4'hf, 4'hf, 4'hf, 4'hf};
				else 
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