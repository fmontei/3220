module watch
( 
	input [3:0] sec_in_lsb,
	input [3:0] sec_in_msb,
	input [3:0] min_in_lsb,
	input [3:0] min_in_msb,
	input [3:0] hr_in_lsb,
	input [3:0] hr_in_msb,
	input set,	  
	input clk,
	output [3:0] sec_out_lsb,
	output [3:0] sec_out_msb,
	output [3:0] min_out_lsb,
	output [3:0] min_out_msb,
	output [3:0] hr_out_lsb,
	output [3:0] hr_out_msb
	);

	reg [3:0] sec_lsb = 0;
	reg [3:0] sec_msb = 0;
	reg [3:0] min_lsb = 0;
	reg [3:0] min_msb = 0;
	reg [3:0] hr_lsb = 0;
	reg [3:0] hr_msb = 0;
	always @(posedge clk or posedge set) begin
		if (set) begin
			sec_lsb <= sec_in_lsb;
			sec_msb <= sec_in_msb;
			min_lsb <= min_in_lsb;
			min_msb <= min_in_msb;
			hr_lsb  <= hr_in_lsb;
			hr_msb  <= hr_in_msb;
		end else begin
			if (clk) begin
				sec_lsb <= sec_lsb + 1;	
				if (sec_lsb == 9) begin
					sec_lsb <= 0;
					sec_msb <= sec_msb + 1;
					if (sec_msb == 5) begin
						sec_msb <= 0;
						min_lsb <= min_lsb + 1;
						if (min_lsb == 9) begin
							min_lsb <= 0;
							min_msb <= min_msb + 1;
							if (min_msb == 5) begin
								min_msb <= 0;
								hr_lsb <= hr_lsb + 1;
								if (hr_lsb == 9) begin
									hr_lsb <= 0;
									hr_msb <= hr_msb + 1;
								end else if (hr_msb == 2 && hr_lsb == 3) begin
									hr_lsb <= 0;
									hr_msb <= 0;
								end
							end
						end
					end
				end
			end
		end
	end
	
	assign sec_out_lsb = sec_lsb;
	assign sec_out_msb = sec_msb;
	assign min_out_lsb = min_lsb;
	assign min_out_msb = min_msb;
	assign hr_out_lsb = hr_lsb;
	assign hr_out_msb = hr_msb;
	
	//bcd bcd1(.number(counter), .ones(sec_out_lsb), .tens(sec_out_msb));
	
endmodule



module bcd(number, hundreds, tens, ones);
   // I/O Signal Definitions
   input  [7:0] number;
   output reg [3:0] hundreds;
   output reg [3:0] tens;
   output reg [3:0] ones;
   
   // Internal variable for storing bits
   reg [19:0] shift;
   integer i;
   
   always @(number)
   begin
      // Clear previous number and store new number in shift register
      shift[19:8] = 0;
      shift[7:0] = number;
      
      // Loop eight times
      for (i=0; i<8; i=i+1) begin
         if (shift[11:8] >= 5)
            shift[11:8] = shift[11:8] + 3;
            
         if (shift[15:12] >= 5)
            shift[15:12] = shift[15:12] + 3;
            
         if (shift[19:16] >= 5)
            shift[19:16] = shift[19:16] + 3;
         
         // Shift entire register left once
         shift = shift << 1;
      end
      
      // Push decimal numbers to output
      hundreds = shift[19:16];
      tens     = shift[15:12];
      ones     = shift[11:8];
   end
 
endmodule

