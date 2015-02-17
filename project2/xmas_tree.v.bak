module Project2(CLOCK_50, LEDG, LEDR);  
	input CLOCK_50; 
	output [7:0] LEDG;
	output [7:0] LEDR;
	reg [7:0] green;
	reg [7:0] red;
	reg [31:0] clock_count;
	reg [2:0] count;
	reg [2:0] state; // A 4-bit register
	initial begin 
		clock_count = 0;
		count = 0;
		state = 0; // Note - this is a 16-bit zero
	end
	always @(posedge CLOCK_50) begin
		clock_count <= clock_count + 32'd1;
		if (clock_count == 32'd25000000) begin 
			if (state == 0) begin
				red[7:0] <= 8'd0;
				if (count % 2 == 0) begin
					green[7:0] <= 8'd255;
				end else begin
					green[7:0] <= 8'd0;
				end
			end else if (state == 1) begin
				green[7:0] <= 8'd0;
				if (count % 2 == 0 ) begin
					red[7:0] <= 8'd255;
				end else begin
					red[7:0] <= 8'd0;
				end
			end else if (state == 2) begin
				if (count % 2 == 0) begin
					green[7:0] <= 8'd255;
					red[7:0] <= 8'd255;
				end else begin
					green[7:0] <= 8'd0;
					red[7:0] <= 8'd0;
				end
			end
			count <= count + 1;
			if (count == 5) begin
				state <= (state + 1) % 3;
				count <= 0;
			end	
			clock_count <= 32'd0;
		end
	end
	assign LEDG = green;
	assign LEDR = red;
endmodule
