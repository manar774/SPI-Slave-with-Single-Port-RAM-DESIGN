//module Name : SPI_Slave
//module Version : 1
//Date : 2025 - 7 - 31 
//Author :  

module SPI_Slave
    #(parameter IDLE = 3'b000, CHK_CMD = 3'b001, WRITE = 3'b010, 
    READ_ADD = 3'b011, READ_DATA= 3'b100)(
    input clk, rst_n, SS_n, MOSI, tx_valid,
    input [7:0] tx_data,
    output reg [9:0] rx_data,
    output reg rx_valid, MISO
    );
    
    reg [2:0] cs, ns;
    reg ADD_READ;
    reg [3:0] counter1;
    reg [9:0] rx_temp;
    reg [7:0] MISO_temp;
    reg [2:0]counter2;
    
    
    // state memory logic
    always@(posedge clk)
    begin
    if (!rst_n)
        cs <= IDLE;
    else
        cs <= ns;
    end
    
    //next state logic
    always@(cs)
    begin
        case(cs)
            IDLE: ns = (SS_n)? cs : CHK_CMD;
            CHK_CMD: begin
                if (!SS_n && !MOSI)
                    ns = WRITE;
                else if (SS_n == 0 && MOSI == 1 ) begin 
                    if (ADD_READ)
                    ns = READ_ADD;
                    else 
                    ns = READ_ADD;
                end else 
                    ns = IDLE;
            end
            WRITE : begin
                if (SS_n == 0 && rx_data[9]) //not sure
                    ns = WRITE;
                else 
                    ns = IDLE;
            end 
            READ_ADD : ns = (SS_n)? IDLE : cs; //missing a condition
            READ_DATA : ns = (SS_n)? IDLE : cs; //missing a condition
            default: ns = IDLE;
        endcase
    end

    //output logic 
    always @(posedge clk) begin 
        if (!rst_n) begin 
            rx_data <= 10'd0;
            rx_valid <= 1'b0;
            MISO <= 1'b0;
            counter1 <=4'd0;
            rx_temp <= 10'd0;
            ADD_READ <= 1'b0;
            counter2 <= 3'd0;
            MISO_temp <= 8'd0;
        end else begin 
            case (cs) 
                WRITE : begin 
                    rx_temp <={MOSI , rx_temp[9:1]};
                    counter1 <= counter1 + 1;
                    if (counter1 == 4'd9) begin //not sure
                        rx_data <= rx_temp;
                        rx_valid <= 1'b1;
                        counter1 <= 4'd0;
                    end else begin 
                        rx_valid <= 1'b0;
                    end
                end
                READ_ADD : begin 
                        rx_temp <={MOSI , rx_temp[9:1]};
                        counter1 <= counter1 + 1;
                    if (counter1 == 4'd9) begin 
                        rx_data <= rx_temp;
                        rx_valid <= 1'b1;
                        counter1 <= 4'd0;
                        ADD_READ <= 1'b1;
                    end else begin 
                        rx_valid <= 1'b0;
                    end
                end 
                READ_DATA : begin 
                    if(!tx_valid) begin
                    rx_temp <={MOSI , rx_temp[9:1]};
                    counter1 <= counter1 + 1;
                    end
                    else if (counter1 == 4'd9) begin 
                        rx_data <= rx_temp;
                        rx_valid <= 1'b1;
                        counter1 <= 4'd0;
                        MISO <= 1'b0;
                        ADD_READ <= 1'b0;
                    end else begin  //tx_valid == 1
                        if (counter2 == 0) begin
                        MISO_temp <= tx_data[7:0];
                        end
                        MISO <= MISO_temp[7 - counter2];
                        counter2 <= counter2 + 1;
                        if (counter2 == 7) begin 
                            counter2 <= 0;
                        end 
                    end
                end 
            
    
            default : begin 
                MISO <= 1'b0;
            end
            endcase 
        end 
    end 
    
endmodule

