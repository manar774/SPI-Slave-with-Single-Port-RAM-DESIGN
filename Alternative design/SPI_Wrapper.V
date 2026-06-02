module SPI_Wrapper(MOSI,SS_n, clk,rst_n,MISO);

parameter MEM_DEPTH = 256, ADDR_SIZE = 8;
parameter IDLE = 3'b000, CHK_CMD = 3'b001, WRITE = 3'b010,
READ_ADD = 3'b011, READ_DATA= 3'b100;

input MOSI,SS_n, clk,rst_n;
output MISO;

wire [9:0] rx_data;
wire [7:0] tx_data;
wire tx_valid, rx_valid;

SPI_Slave #(.IDLE(IDLE), .CHK_CMD(CHK_CMD), .WRITE(WRITE), 
    .READ_ADD(READ_ADD), .READ_DATA(READ_DATA)) spi_slave_inst (
    .clk(clk),
    .rst_n(rst_n),
    .SS_n(SS_n),
    .MOSI(MOSI),
    .tx_valid(tx_valid),
    .tx_data(tx_data),
    .rx_data(rx_data),
    .rx_valid(rx_valid),
    .MISO(MISO)
);

RAM #(.MEM_DEPTH(MEM_DEPTH), .ADDR_SIZE(ADDR_SIZE)) ram_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rx_valid(rx_valid),
    .din(rx_data),
    .dout(tx_data),
    .tx_valid(tx_valid)
);
endmodule 