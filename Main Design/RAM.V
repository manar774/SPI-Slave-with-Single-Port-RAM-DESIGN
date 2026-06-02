//module Name : RAM
//module Version : 1
//Date : 2025 - 7 - 31 
//Author : 

module RAM
    #(parameter MEM_DEPTH = 256, ADDR_SIZE = 8)(
    input clk, rst_n, rx_valid,
    input [9:0] din,
    output reg [7 : 0] dout,
    output reg tx_valid
    );
    
    reg [7:0] addr_wr;
   
    reg [ADDR_SIZE - 1:0] mem [MEM_DEPTH - 1:0];
    
    always@(posedge clk)
    begin
        if (!rst_n)
        begin
            dout <= 0;
            tx_valid <= 0;
        end
        
        else if (rx_valid)
        begin
            case(din[9:8])
                2'b00: addr_wr <= din[7:0];
                2'b01: mem[addr_wr] <= din[7:0];
                2'b10: addr_wr <= din[7:0];
                2'b11: 
                begin
                    dout <= mem[addr_wr];
                    tx_valid <= 1'b1;
                end 
                 default: begin
                        dout <= 0;
                        tx_valid <= 0;
                    end
            endcase
        end
    end
endmodule