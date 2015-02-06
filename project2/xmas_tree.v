module Project2(CLOCK_50, LEDG, LEDR, KEY);  
	input CLOCK_50; 
	input [2:0] KEY;
	output [7:0] LEDG;
	output [7:0] LEDR;
	reg [2:0] REG_KEY;
	reg [7:0] green;
	reg [7:0] red;
	reg [31:0] clock_count;
	reg [31:0] CLOCK_MAX;
	reg [2:0] count;
	reg [2:0] state; // A 4-bit register
	reg [0:0] FLAG;
	initial begin 
		clock_count <= 0;
		CLOCK_MAX <= 32'd25000000;
		REG_KEY <= 3'd0;
		count <= 0;
		state <= 0; // Note - this is a 16-bit zero
		FLAG <= 0;
	end
	
	always @(posedge CLOCK_50) begin
		
		clock_count <= clock_count + 32'd1;
		
		if (clock_count == 32'd12500000) begin
			if (KEY[0] == 0) begin
				REG_KEY[0] <= 1'b1;
				REG_KEY[1] <= 1'b0;
				REG_KEY[2] <= 1'b0;
				//FLAG <= 1;
			end else if (KEY[1] == 0) begin
				REG_KEY[0] <= 1'b0;
				REG_KEY[1] <= 1'b1;
				REG_KEY[2] <= 1'b0;
				//FLAG <= 1;
			end else if (KEY[2] == 0) begin
				REG_KEY[0] <= 1'b0;
				REG_KEY[1] <= 1'b0;
				REG_KEY[2] <= 1'b1;
				//FLAG <= 1;
			end
		end
		
		if (clock_count == CLOCK_MAX /* || FLAG == 1 */) begin
			if (REG_KEY[0] == 1'b1 && CLOCK_MAX < 32'd100000000) begin
				CLOCK_MAX <= CLOCK_MAX + 32'd12500000; 
				//clock_count <= 0;
			end else if (REG_KEY[1] == 1'b1 && CLOCK_MAX > 32'd12500000) begin
				CLOCK_MAX <= CLOCK_MAX - 32'd12500000;
				//clock_count <= 0;
			end else if (REG_KEY[2] == 1'b1) begin
				CLOCK_MAX <= 32'd25000000;
				//clock_count <= 0;
			end
		
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
