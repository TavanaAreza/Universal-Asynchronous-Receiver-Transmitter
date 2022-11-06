
module UART_Project (input Reset,input Clock,input BaudRate,input TxDataLoad,input [7:0] TxDataIn,output reg TxDataOut,input RxDataIn,output [7:0] RxDataOut,output TxDone,output RxDone,output RxError);

reg [2:0] Halat1 = 3'b000;    //   sabr ta in ke start bit biad
reg [2:0] Halat2 = 3'b001;    //   khandan start bit
reg [2:0] Halat3 = 3'b010;    //   khandan data
reg [2:0] Halat4 = 3'b011;    //   khandan stop bit
   
reg [2:0]    Halat     = 0;
reg [10:0]    Counter = 0;
reg [2:0]    Index   = 0;
reg [7:0]    Tx_Data     = 0;
reg          Tx_Done     = 0;


integer CPB;
initial CPB=BaudRate*521+(1-BaudRate)*1042;  // tain kardan baudrate

always @(posedge Clock) begin
    if (BaudRate==0) begin
        CPB=11'd1042;
    end else begin
        CPB=11'd521;
    end
end

always @(posedge Clock or negedge Reset) begin
    if (!Reset) begin    //  vaghti low mishavad avtive ast
        TxDataOut   <= 1'b1;        
        Tx_Done     <= 1'b0;
        Counter <= 0;
        Index   <= 0;
        Halat <= Halat1;
        TxDataOut <= 1'b1;
    end else begin
        if (Halat==Halat1) begin
            Counter <= 0;
            Index   <= 0;
            TxDataOut   <= 1'b1;        
            Tx_Done     <= 1'b0;
            if (TxDataLoad == 1'b1)
                begin
                  Tx_Data   <= TxDataIn;
                  Halat   <= Halat2;
                end
            else
            begin
                Halat <= Halat1;
            end
        end else begin
            if (Halat==Halat2) begin
                TxDataOut <= 1'b0;
                if (Counter < CPB-1)
                  begin
                    Counter <= Counter + 1;
                    Halat <= Halat2;
                  end
                else
                  begin
                    Counter <= 0;
                    Halat <= Halat3;
                  end
            end else begin
                if (Halat==Halat3) begin
                    TxDataOut <= Tx_Data[Index];
                    if (Counter < CPB-1)
                    begin
                        Counter <= Counter + 1;
                        Halat <= Halat3;
                    end
                    else
                    begin
                        Counter <= 0;
                        if (Index < 7)
                        begin
                            Index <= Index + 1;
                            Halat   <= Halat3;
                        end
                        else
                        begin
                            Index <= 0;
                            Halat <= Halat4;
                        end
                    end
                end else begin
                    TxDataOut <= 1'b1;
                    if (Counter < CPB-1)
                    begin
                        Counter <= Counter + 1;
                        Halat  <= Halat4;
                    end
                    else
                    begin
                        Tx_Done  <= 1'b1;
                        Counter <= 0;
                        Halat <= Halat1;
                    end
                end
            end
        end
    end
end

assign TxDone  = Tx_Done;

///////////////////////////////////////////////////////////////////// Receiver


reg [2:0]    HalatR     = 0;
reg [10:0]    CounterR = 0;
reg [3:0]    IndexR   = 0;
reg [3:0]    IndexStartBit   = 0;
reg Flag = 0;

reg     r_Rx_Data_R = 1'b1;
reg     r_Rx_Data   = 1'b1;
reg     r_Rx_Error   = 1'b0;
reg     r_Rx_DV       = 0;
reg [7:0]     r_Rx_Byte     = 0;

integer CPBR;
initial CPBR=BaudRate*66+(1-BaudRate)*131;  // tain kardan baudrate

always @(posedge Clock) begin
    if (BaudRate==0) begin
        CPBR=11'd131;
    end else begin
        CPBR=11'd66;
    end
end


always @(posedge Clock)
begin
    r_Rx_Data_R <= RxDataIn;
    r_Rx_Data   <= r_Rx_Data_R;
end


always @(posedge Clock) begin
    if (HalatR==Halat1) begin
        r_Rx_DV       <= 1'b0;
        r_Rx_Error  <= 0;
        CounterR <= 0;
        IndexR   <= 0;
        IndexStartBit  <= 0;
        Flag <= 0;
             
        if (r_Rx_Data == 1'b0)          // Start bit detected
            HalatR <= Halat2;
        else
        begin
            HalatR <= Halat1;
        end
    end else begin            //Checking Start bit 
        if (HalatR==Halat2) begin
            if (CounterR < CPBR-1)
            begin
                CounterR <= CounterR + 1;
                HalatR <= Halat2;
            end
            else
            begin
                CounterR <= 0;
                if (IndexStartBit < 7)
                begin
                    if (r_Rx_Data==0) begin
                        IndexStartBit  <= IndexStartBit +1;
                    end else begin
                        if (IndexStartBit<4) begin
                            IndexStartBit  <=  0;
                            HalatR   <= Halat1;
                            r_Rx_Error  <= 1;
                        end else begin
                            IndexStartBit  <= IndexStartBit +1;
                        end
                    end
                end
                else
                begin
                    HalatR <= Halat3;
                    IndexStartBit <= 0;
                end
            end
        end else begin
            if (HalatR==Halat3) begin
                if (Flag==0) begin
                   if (CounterR == (CPB-1)/2)
                    begin
                        Flag <= 1;
                        CounterR       <= 0;
                        r_Rx_Byte[IndexR] <= r_Rx_Data;
                        IndexR <= IndexR + 1;
                    end
                    else
                    begin
                        CounterR <= CounterR + 1;
                        HalatR <= Halat3;
                    end 
                end else begin
                    if (CounterR < CPB-1)
                    begin
                        CounterR <= CounterR + 1;
                        HalatR <= Halat3;
                    end
                    else
                    begin
                        CounterR       <= 0;
                        r_Rx_Byte[IndexR] <= r_Rx_Data;
                 
                        // Check if we have received all bits
                        if (IndexR < 7)
                        begin
                            IndexR <= IndexR + 1;
                            HalatR <= Halat3;
                        end
                        else
                        begin
                            IndexR <= 0;
                            HalatR <= Halat4;
                        end
                    end
                end
            end else begin
                if (CounterR < CPB-1)
                begin
                    CounterR <= CounterR + 1;
                    HalatR     <= Halat4;
                end
                else
                begin
                    r_Rx_DV       <= 1'b1;
                    CounterR <= 0;
                    HalatR   <= Halat1 ;
                end  
            end
        end
    end
end

assign RxDone   = r_Rx_DV;
assign RxError   = r_Rx_Error;
assign RxDataOut = r_Rx_Byte;

endmodule
