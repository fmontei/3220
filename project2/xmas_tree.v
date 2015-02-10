module Project2(CLOCK_50, LEDG, LEDR, KEY, HEX0, HEX1, HEX2, HEX3); 
	output [6:0] HEX0, HEX1, HEX2, HEX3;
	input CLOCK_50; 
	input [2:0] KEY;
	output [7:0] LEDG;
	output [7:0] LEDR;
	reg [7:0] green;
	reg [7:0] red;
	reg [31:0] clock_count; // Counts clock ticks
	reg [31:0] CLOCK_MAX; // Time between flashes
	reg [2:0] count; // Counts number of flashes
	reg [2:0] state; // State 0 = Green, State 1 = Red, State 2 = Both
	reg [0:0] k0_clicked; // Keeps track of when k0 is initially pressed
	reg [0:0] k0_unclicked; // Keeps track of when k0 is released
	reg [0:0] k1_clicked; // Keeps track of when k1 is initially pressed
	reg [0:0] k1_unclicked; // Keeps track of when k1 is released
	reg [15:0] hex_output; // Debugging hex output
	
	parameter QUARTER_SEC = 32'd12500000;
	parameter HALF_SEC = 32'd25000000;
	parameter TWO_SEC = 32'd100000000;
	
	initial begin 
		clock_count <= 0;
		CLOCK_MAX <= HALF_SEC;
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
		if (k0_unclicked == 1) begin
			if (CLOCK_MAX < TWO_SEC) begin
				CLOCK_MAX <= CLOCK_MAX + QUARTER_SEC; // slow down
				clock_count <= 0;
			end
			k0_clicked <= 0;
			k0_unclicked <= 0;
		end else if (k1_unclicked == 1) begin
			if (CLOCK_MAX > QUARTER_SEC) begin
				CLOCK_MAX <= CLOCK_MAX - QUARTER_SEC; // speed up
				clock_count <= 0;
			end
			k1_clicked <= 0;
			k1_unclicked <= 0;
		/* We don't need to keep track of keys being pressed and released
		 * for reset, since spamming reset does nothing to increment/decrement
		 * CLOCK_MAX like crazy */	
		end else if (KEY[2] == 0) begin
			CLOCK_MAX <= HALF_SEC; // reset
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
		
		hex_output <=
			(CLOCK_MAX == QUARTER_SEC) ? 1 :
			(CLOCK_MAX == HALF_SEC) ? 2 :
			(CLOCK_MAX == HALF_SEC + QUARTER_SEC) ? 3 :
			(CLOCK_MAX == HALF_SEC + HALF_SEC) ? 4 :
			(CLOCK_MAX == HALF_SEC + HALF_SEC + QUARTER_SEC) ? 5 :
			(CLOCK_MAX == HALF_SEC + HALF_SEC + HALF_SEC) ? 6 : 
			(CLOCK_MAX == HALF_SEC + HALF_SEC + HALF_SEC + QUARTER_SEC) ? 7 :
			/*(CLOCK_MAX == TWO_SEC)*/ 8;
			
	end
	
	SevenSeg sseg0(.IN(hex_output[ 3: 0]),.OUT(HEX0));
	SevenSeg sseg1(.IN(hex_output[ 7: 4]),.OUT(HEX1));
	SevenSeg sseg2(.IN(hex_output[11: 8]),.OUT(HEX2));
	SevenSeg sseg3(.IN(hex_output[15:12]),.OUT(HEX3));
	
	assign LEDG = green;
	assign LEDR = red;
endmodule

module SevenSeg(OUT, IN);
input  [3:0] IN;
output [6:0] OUT;
assign OUT =
  (IN == 4'h0) ? 7'b1000000 :
  (IN == 4'h1) ? 7'b1111001 :
  (IN == 4'h2) ? 7'b0100100 :
  (IN == 4'h3) ? 7'b0110000 :
  (IN == 4'h4) ? 7'b0011001 :
  (IN == 4'h5) ? 7'b0010010 :
  (IN == 4'h6) ? 7'b0000010 :
  (IN == 4'h7) ? 7'b1111000 :
  (IN == 4'h8) ? 7'b0000000 :
  (IN == 4'h9) ? 7'b0010000 :
  (IN == 4'hA) ? 7'b0001000 :
  (IN == 4'hb) ? 7'b0000011 :
  (IN == 4'hc) ? 7'b1000110 :
  (IN == 4'hd) ? 7'b0100001 :
  (IN == 4'he) ? 7'b0000110 :
  /*IN == 4'hf*/ 7'b0001110 ;
endmodule

