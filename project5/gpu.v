
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

/* Provided registers */
reg [26:0] count;

/* Our registers & wires */
reg [10:0] ax[4:0], ay[4:0], bx[4:0], by[4:0], cx[4:0], cy[4:0];
reg [10:0] x, y;
reg [0:0] in_triangle;
reg signed [31:0] e1;
reg signed [31:0] e2;
reg signed [31:0] e3;
reg [2:0] i;

wire [31:0] min_x, min_y, max_x, max_y;
assign min_x = (ax[i] <= bx[i] && ax[i] <= cx[i]) ? ax[i] :
					(bx[i] <= ax[i] && bx[i] <= cx[i]) ? bx[i] :
					/*(cx <= ax && cx <= bx)*/ cx[i];
assign min_y = (ay[i] <= by[i] && ay[i] <= cy[i]) ? ay[i] :
				   (by[i] <= ay[i] && by[i] <= cy[i]) ? by[i] :
				   /*(cy <= cx && cy <= by)*/ cy[i];		
assign max_x = (ax[i] >= bx[i] && ax[i] >= cx[i]) ? ax[i] :
				   (bx[i] >= ax[i] && bx[i] >= cx[i]) ? bx[i] :
				   /*(cx >= ax && cx >= bx)*/ cx[i];
assign max_y = (ay[i] >= by[i] && ay[i] >= cy[i]) ? ay[i] :
				   (by[i] >= ay[i] && by[i] >= cy[i]) ? by[i] :
				   /*(cy >= ay && cy >= by)*/ cy[i];

initial begin
	/* test case triangle 1 */
	ax[0] = 1; ay[0] = 1; bx[0] = 200; by[0] = 100; cx[0] = 50; cy[0] = 50;	
	/* test case triangle 2 */
	ax[1] = 100; ay[1] = 100; bx[1] = 200; by[1] = 100; cx[1] = 200; cy[1] = 200;	
	/* test case triangle 3 */
	ax[2] = 100; ay[2] = 100; bx[2] = 200; by[2] = 100; cx[2] = 200; cy[2] = 1;	
	/* test case triangle 4 */
	ax[3] = 20; ay[3] = 20; bx[3] = 100; by[3] = 1; cx[3] = 1; cy[3] = 1;	
	/* test case triangle 5 */
	ax[4] = 1; ay[4] = 1; bx[4] = 100; by[4] = 90; cx[4] = 20; cy[4] = 100;	
	x = 0;
	y = 0;
	i = 0;
	in_triangle = 0;
end
				
always @(posedge I_CLK or negedge I_RST_N)
begin
	if (!I_RST_N) begin
		O_GPU_ADDR <= 16'h0000;
		O_GPU_WRITE <= 1'b1;
		O_GPU_READ <= 1'b0;
		O_GPU_DATA <= {4'hf, 4'hf, 4'hf, 4'hf};
		count <= 0;
		i <= 0;
	end else begin
		if (!I_VIDEO_ON) begin
		
			/* Iterate over the entire screen with x and y, to make computation
			 * of O_GPU_ADDR more intuitive. However, only perform expensive
			 * multiplication operations for e1 - e3 if x and y are inside
			 * the box bounded by (min_x, max_x), (min_y, max_y) */
			if (y <= 639) begin
				if (x <= 399) begin
					if (x >= min_x && x <= max_x && y >= min_y && y <= max_y) begin
						e1 <= (-(cy[i] - by[i]) * (x - bx[i])) + ((cx[i] - bx[i]) * (y - by[i]));
						e2 <= (-(ay[i] - cy[i]) * (x - cx[i])) + ((ax[i] - cx[i]) * (y - cy[i]));
						e3 <= (-(by[i] - ay[i]) * (x - ax[i])) + ((bx[i] - ax[i]) * (y - ay[i]));
					end
					/* After testing this in C code, it is necessary to check whether
					 * all three edges are positive or all three are negative */
					in_triangle <= ((e1 > 0 && e2 > 0 && e3 > 0) || 
					                (e1 < 0 && e2 < 0 && e3 < 0)) ? 1 : 0;
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
				O_GPU_DATA <= {4'h0, 4'h0, 4'h0, 4'h0};
				i <= (i + 1) % 5;
			end 
			/* reset the screen */ 		
			else if (count[24] == 1) begin 
				O_GPU_ADDR <= x * 640 + y;
				O_GPU_WRITE <= 1'b1;
				O_GPU_READ <= 1'b0;
				if (in_triangle == 1)
					O_GPU_DATA <= {4'h0, 4'h0, 4'h0, 4'h0};	
				else
					O_GPU_DATA <= {4'hf, 4'hf, 4'hf, 4'hf};
			end 		
		end 
	end
end

SevenSeg sseg0(.IN(min_x[ 3: 0]),.OUT(O_HEX0));
SevenSeg sseg1(.IN(min_x[ 7: 4]),.OUT(O_HEX1));
SevenSeg sseg2(.IN(min_x[11: 8]),.OUT(O_HEX2));
SevenSeg sseg3(.IN(min_x[15:12]),.OUT(O_HEX3));

endmodule