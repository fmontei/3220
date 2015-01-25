`timescale 1ns/1ps
module watch_test();
reg [3:0] sec_in_lsb_t, sec_in_msb_t, min_in_lsb_t, min_in_msb_t, hr_in_lsb_t, hr_in_msb_t;
reg set_t, clk_t;
wire [3:0] sec_out_lsb_t, sec_out_msb_t,min_out_lsb_t, min_out_msb_t, hr_out_lsb_t, hr_out_msb_t;


watch test_watch (sec_in_lsb_t, sec_in_msb_t, min_in_lsb_t, min_in_msb_t, hr_in_lsb_t, hr_in_msb_t, set_t,clk_t,sec_out_lsb_t, sec_out_msb_t,min_out_lsb_t, min_out_msb_t,hr_out_lsb_t, hr_out_msb_t);

initial begin
	clk_t = 0;
	set_t = 0;
	sec_in_lsb_t= 0;
	sec_in_msb_t = 0;
	min_in_lsb_t= 0;
	min_in_msb_t = 0;
	hr_in_lsb_t= 0;
	hr_in_msb_t = 0;
	
	#1
	// Test 60 sec rollover
	// Set time as 03:45:53
	set_t = 1;
	sec_in_lsb_t = 3;
	sec_in_msb_t = 5;
	min_in_lsb_t= 5;
	min_in_msb_t = 4;
	hr_in_lsb_t= 3;
	hr_in_msb_t = 0;
	
	#1
	set_t = 0;
	
	
	// Test 60 min rollover
	// Set time as 06:59:55
	#19
	set_t = 1;
	sec_in_lsb_t = 5;
	sec_in_msb_t = 5;
	min_in_lsb_t= 9;
	min_in_msb_t = 5;
	hr_in_lsb_t= 6;
	hr_in_msb_t = 0;
	
	#1
	set_t = 0;
	
	
	#150
	// Test 24 hour roll over
	// Set time as 23:59:55
	set_t = 1;
	sec_in_lsb_t = 5;
	sec_in_msb_t = 5;
	min_in_lsb_t= 9;
	min_in_msb_t = 5;
	hr_in_lsb_t= 3;
	hr_in_msb_t = 2;
	
	#1
	set_t = 0; 
	
	
	#20
	//Test frozen time
	set_t = 1;
	sec_in_lsb_t = 5;
	sec_in_msb_t = 5;
	min_in_lsb_t= 8;
	min_in_msb_t = 5;
	hr_in_lsb_t= 6;
	hr_in_msb_t = 0;
	
	#20
	set_t = 0;
	
end

/*
//Uncomment this for getting the final vcd output file.
initial begin
	$dumpfile("watch_250ns.vcd");
	$dumpvars(0, watch_test);
	#250;
	$finish;
end
*/

always
#1 clk_t = ~clk_t;

endmodule
