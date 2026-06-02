module Wrapper_tb();

parameter MEM_DEPTH = 256, ADDR_SIZE = 8;
parameter IDLE = 3'b000, CHK_CMD = 3'b001, WRITE = 3'b010, 
READ_ADD = 3'b011, READ_DATA= 3'b100;

reg clk, rst_n, SS_n, MOSI;
wire MISO;

SPI_Wrapper #(.MEM_DEPTH(MEM_DEPTH), .ADDR_SIZE(ADDR_SIZE), .IDLE(IDLE), .CHK_CMD(CHK_CMD), .WRITE(WRITE), .READ_ADD(READ_ADD), .READ_DATA(READ_DATA))
DUT(MOSI,SS_n, clk,rst_n,MISO);

initial begin
    clk = 0;
    forever begin
        #1 clk = ~clk;
    end
end

initial begin
	$readmemb("mem.dat", DUT.ram_inst.mem);
	rst_n = 0;
    SS_n = 1;
    MOSI = 0;
    @(negedge clk);
    rst_n = 1;

    // Test case1 : write address 10'b0000001111 -> 15
    SS_n = 0; 
    @(negedge clk);
    @(negedge clk);
    // here we in Write
    // Enter the write address MSB first
    MOSI = 0; @(negedge clk);//msb
    MOSI = 0; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 1; @(negedge clk);
    MOSI = 1; @(negedge clk);
    MOSI = 1; @(negedge clk);
    MOSI = 1; @(negedge clk);
    @(negedge clk); // extra clock cycles to check that data will not change 
    SS_n = 1; @(negedge clk);

    // Test case2 : write data 10'b0100001010 -> 14
    SS_n = 0; @(negedge clk);
    MOSI = 0; @(negedge clk);
    // Enter the write data MSB first
    MOSI = 0; @(negedge clk); // MSB
    MOSI = 1; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 1; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 1; @(negedge clk);
    MOSI = 0; @(negedge clk);
     @(negedge clk); // extra clock cycles to check that data will not change 
    SS_n = 1; @(negedge clk);


    // Test case3 : read add 10'b0000001111 -> 15
    SS_n = 0; @(negedge clk);
    MOSI = 1; @(negedge clk);
    // Enter the read address MSB first
    MOSI = 1; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 1; @(negedge clk);
    MOSI = 1; @(negedge clk);
    MOSI = 1; @(negedge clk);
    MOSI = 1; @(negedge clk);
    @(negedge clk); // extra clock cycles to check that data will not change 
    SS_n = 1; @(negedge clk);
    
    // Test case4 : read data 10'b1100001010 -> 14
    SS_n = 0; @(negedge clk);
    MOSI = 1; @(negedge clk);
    // Enter the read data MSB first
    MOSI = 1; @(negedge clk);
    MOSI = 1; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 0; @(negedge clk);
    MOSI = 0; @(negedge clk);
    @(negedge clk); // extra clock cycles to check that data will not change
    @(negedge clk); // extra clock cycles to check that data will not change
    repeat(8)begin
       @(negedge clk); 
    end
    SS_n = 1; @(negedge clk);

    //repeat(20) @(negedge clk);
    $stop;
end
endmodule