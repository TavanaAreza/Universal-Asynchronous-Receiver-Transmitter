module uart_tb ();
 

parameter c_CLOCK_PERIOD_NS = 100;
parameter c_BIT_PERIOD      = 104167;
   
reg Clock = 0;
reg r_Rx_Serial = 1;
reg [7:0] i_Data = 8'b00110011;
integer     ii;

reg Reset=1;
reg BaudRate=0;
reg TxDataLoad=0;
wire TxDataOut;
wire [7:0] RxDataOut;
wire TxDone;
wire RxDone;
wire RxError;
   
   
   
  UART_Project  UART_INST
    (.Reset(Reset),
     .Clock(Clock),
     .BaudRate(BaudRate),
     .TxDataLoad(TxDataLoad),
     .TxDataIn(i_Data),
     .TxDataOut(TxDataOut),
     .RxDataIn(r_Rx_Serial),
     .RxDataOut(RxDataOut),
     .TxDone(TxDone),
     .RxDone(RxDone),
     .RxError(RxError)
     );
   
   always  begin
       #(c_CLOCK_PERIOD_NS/2) Clock <= !Clock;
   end

   always 
   begin
       if (i_Data != 8'b11111111) begin
           #10000;
           TxDataLoad=1;
           #100;
           TxDataLoad=0;
           #10000;
            // Send Start Bit
            r_Rx_Serial <= 1'b0;
            #(c_BIT_PERIOD);
        
       
            // Send Data Byte
            for (ii=0; ii<8; ii=ii+1)
                begin
                r_Rx_Serial <= i_Data[ii];
                #(c_BIT_PERIOD);
                end
       
            // Send Stop Bit
            r_Rx_Serial <= 1'b1;
            i_Data = 8'b11111111;
            #(c_BIT_PERIOD);
            end
            else 
            begin
                #2000;
            end
   end

    
 
   
endmodule
