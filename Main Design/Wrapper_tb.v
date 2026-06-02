module Wrapper_tb();

parameter MEM_DEPTH = 256, ADDR_SIZE = 8;
parameter IDLE = 3'b000, CHK_CMD = 3'b001, WRITE = 3'b010, 
READ_ADD = 3'b011, READ_DATA= 3'b100;

reg clk, rst_n, SS_n, MOSI;
wire MISO;
reg [9:0] bus;

SPI_Wrapper #(.MEM_DEPTH(MEM_DEPTH), .ADDR_SIZE(ADDR_SIZE), .IDLE(IDLE), .CHK_CMD(CHK_CMD), .WRITE(WRITE), .READ_ADD(READ_ADD), .READ_DATA(READ_DATA))
DUT(MOSI,SS_n, clk,rst_n,MISO);

initial begin
	clk=0;
	forever #1 clk= ~clk;
end

integer i;

initial begin
	$readmemb("mem.dat", DUT.ram_inst.mem);

//rst	
	rst_n = 0;
	SS_n = 1;
	bus= 0;
	MOSI= 0;
	repeat (5) @(negedge clk);

	rst_n = 1;
	bus = 10'b00_00000101; // write address(addr= 5)
	
	 @(negedge clk);


//write addr	
	
	SS_n = 0; // begin communication
 	@(negedge clk);		
	MOSI = 0; // to write addr
	for(i=10; i>0; i= i-1) begin
		@(negedge clk);		
		MOSI= bus[i-1];
	end

//write data
	@(negedge clk);
	SS_n = 1; //go for idle again
	@(negedge clk); 
	SS_n = 0; //start communication
	@(negedge clk) begin
		MOSI = 0;
		bus = 10'b01_00000111; // write data(data= 7)
	end
	for(i=10; i>0; i= i-1) begin
		@(negedge clk);		
		MOSI= bus[i-1];
	end

//read addr	
	@(negedge clk);
	SS_n = 1; //go for idle again
	@(negedge clk); 
	SS_n = 0; //start communication
	@(negedge clk)begin
		MOSI = 1;
		bus = 10'b10_00000011; // read_addr (addr= 3)
end
	for(i=10; i>0; i= i-1) begin
		@(negedge clk);		
		MOSI= bus[i-1];
	end

//read data
	@(negedge clk);
	SS_n = 1; //go for idle again
	@(negedge clk);
	SS_n = 1; //go for idle again
	@(negedge clk); 
	SS_n = 0; //start communication
	@(negedge clk) begin
		MOSI = 1;
		bus = 10'b11_00001000; // read_data (addr= 8)
end
	for(i=10; i>0; i= i-1) begin
		@(negedge clk);		
		MOSI= bus[i-1];
	end

// Wait to take the data from MISO
repeat (10) @(negedge clk);

// Close communication
@(negedge clk);
SS_n=1;
 repeat (100) @(negedge clk);

$stop;
end


initial begin
	$monitor("clk= %b, rst_n= %b, SS_n= %b, MOSI= %b, MISO= %b",
		clk, rst_n, SS_n, MOSI, MISO);
end

endmodule