module Project2(CLOCK_50, LEDG, LEDR, KEY);  
	input CLOCK_50; 
	input [2:0] KEY;
	output [7:0] LEDG;
	output [7:0] LEDR;
	reg [7:0] green;
	reg [7:0] red;
	reg [31:0] clock_count; // Counts clock ticks
	reg [31:0] CLOCK_MAX; // Time between flashes
	reg [2:0] count; // Counts number of flashes
	reg [2:0] state; // State 0 == Green, State 1 == Red, State 2 == Both
	reg [0:0] k0_clicked; // Keeps track of when k0 is initially pressed
	reg [0:0] k0_unclicked; // Keeps track of when k0 is released
	reg [0:0] k1_clicked; // Keeps track of when k1 is initially pressed
	reg [0:0] k1_unclicked; // Keeps track of when k1 is released
	
	initial begin 
		clock_count <= 0;
		CLOCK_MAX <= 32'd25000000;
		count <= 0;
		state <= 0; 
		k0_clicked <= 0;
		k0_unclicked <= 0;
		k1_clicked <= 0;
		k1_unclicked <= 0;
	end
	
	always @(posedge CLOCK_50) begin
		
		clock_count <= clock_count + 32'd1;
	
		/* We want to keep track of when a key has been pressed down */
		if (KEY[0] == 0) begin
			k0_clicked <= 1;
		end else if (KEY[1] == 0) begin
			k1_clicked <= 1;
		end
		
		/* If the key has been pressed down AND the key INPUT is
		 * no longer pressed down, then the button has been released */
		if (KEY[0] == 1 && k0_clicked == 1) begin
			k0_unclicked <= 1;
		end else if (KEY[1] == 1 && k1_clicked == 1) begin
			k1_unclicked <= 1;
		end
		
		/* Since we know that the button has been clicked and released,
		 * NOW we want to change the value of CLOCK_MAX -- this happens
		 * only once, since it's synched to the button being released */
		if (k0_unclicked == 1 && CLOCK_MAX < 32'd100000000) begin
			CLOCK_MAX <= CLOCK_MAX + 32'd12500000; // slow down
			clock_count <= 0;
			k0_clicked <= 0;
			k0_unclicked <= 0;
		end else if (k1_unclicked == 1 && CLOCK_MAX > 32'd12500000) begin
			CLOCK_MAX <= CLOCK_MAX - 32'd12500000; // speed up
			clock_count <= 0;
			k1_clicked <= 0;
			k1_unclicked <= 0;
		/* We don't need to keep track of keys being pressed and released
	    * for reset, since spamming reset does nothing to increment/decrement
		 * CLOCK_MAX like crazy */	
		end else if (KEY[2] == 0) begin
			CLOCK_MAX <= 32'd25000000; // reset
			clock_count <= 0;
		end
		
		if (clock_count == CLOCK_MAX) begin
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
