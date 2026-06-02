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
    reg read_flag; //edit 1 change name
    reg [3:0] counter1, counter2; 
    reg [9:0] rx_shift_temp;
    reg [7:0] MISO_temp;

    
    
    // state memory logic
    always@(posedge clk)
    begin
    if (!rst_n)
        cs <= IDLE;
    else
        cs <= ns;
    end
    
    //next state logic
    always@(*)
    begin
        case(cs)
            IDLE: ns = (SS_n)? IDLE : CHK_CMD; 
            CHK_CMD: 
            begin
                if (SS_n)
                    ns = IDLE;
                else
                begin
                    if (MOSI) 
                    begin 
                        if (read_flag)
                            ns = READ_DATA;
                        else 
                            ns = READ_ADD;
                    end
                    else
                        ns = WRITE;
                end
            end
            WRITE: ns = (SS_n)? IDLE : WRITE;
            READ_ADD : ns = (SS_n)? IDLE : READ_ADD; 
            READ_DATA : ns = (SS_n)? IDLE : READ_DATA; 
            default: ns = IDLE;
        endcase
    end

    // Output Logic block
    always @(posedge clk) begin
        if (!rst_n) 
        begin
            rx_valid <= 0;
            rx_data <= 10'b0;
            MISO <= 0;
            read_flag <= 0;
            counter1 <= 0;
            counter2 <= 0;
            rx_shift_temp <= 0;
            MISO_temp <= 0;
        end 
        else 
        begin
            case (cs)
                WRITE: 
                begin
                    if (counter1 < 11 ) 
                    begin // why 11 :  10 for get 10 bit shifted left then 1 cycle for copy value of temp inside rx_data
                         counter1 <= counter1 + 1;
                         if (counter1 < 10 ) 
                         begin // mean i have already 10 cycles before and shift reg was ready to copy and at end of this edge counter will be 11 (remember non blocking)
                            rx_shift_temp <= {rx_shift_temp ,MOSI} ; // shifting left
                         end 
                         else 
                         begin // mean counter equal 10//editttttttttttttt
                             rx_valid <= 1;
                             rx_data <= rx_shift_temp ;
                         end
                    end 
                    else 
                        rx_valid <= 0 ;
                end 
                READ_ADD: 
                begin
                    if (counter1 < 11 ) 
                    begin // why 11 :  10 for get 10 bit shifted left then 1 cycle for copy value of temp inside rx_data
                         counter1 <= counter1 + 1;
                         if (counter1 < 10 ) 
                         begin // mean i have already 10 cycles before and shift reg was ready to copy and at end of this edge counter will be 11 (remember non blocking)
                            rx_shift_temp <= {rx_shift_temp ,MOSI} ; // shifting left
                         end 
                         else 
                         begin // mean counter equal 10
                             rx_valid <= 1;
                             rx_data <= rx_shift_temp ;
                             read_flag <= 1 ;
                         end
                    end 
                    else 
                        rx_valid <= 0 ;
                end     
                READ_DATA: 
                begin
                    if(tx_valid == 0)
                    begin
                        if (counter1 < 11)
                        begin
                            counter1 <= counter1 + 1;
                            if (counter1 < 10) 
                                rx_shift_temp <= {rx_shift_temp[8:0],MOSI};
                            else 
                            begin
                                rx_valid <= 1;
                                rx_data <= rx_shift_temp;
                            end
                        end 
                        else if (counter1 > 11 && counter2 < 8) 
                        begin
                            MISO_temp <= MISO_temp << 1;//editttttttttttt
                            MISO <= MISO_temp[7]; //edittttttttttttt
                            read_flag <= 0;
                            counter2 <= counter2 + 1;
                        end 
                        else  // counter equal 11
                            rx_valid <= 0;
                    end 
                    else 
                    begin
                        counter1 <= counter1 + 1;
                        // rx_valid <= 0;
                        MISO_temp <= tx_data;
                    end 
                end
                default: 
                begin
                    counter1 <= 0;
                    counter2 <= 0;
                    rx_shift_temp <= 0;
                    rx_valid <= 0;
                    rx_valid <= 0;
                    MISO_temp <= 0;
                    MISO <= 0;
                end
            endcase
        end//if
    end//always
endmodule