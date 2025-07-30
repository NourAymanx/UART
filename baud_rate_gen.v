module baud_rate_gen (
  input clk, //system clock
  input reset,
  input [15:0] baud_divisor, // controls how many clock cycles to wait before generating a baud_tick
  output reg baud_tick, //high for 1 clock cycle when it's time to transmit a bit(for Tx)
  output reg sample_tick   // Pulse at 16x baud rate (for Rx) used to receive bits with oversampling
);  

//divisor = clk / baud_rate 

    reg [15:0] baud_counter;
    reg [3:0] sample_counter; //counts from 0 to 15 (16 cycles)to generates sample_tick

  always @(posedge clk or posedge reset) begin
        if (reset) begin
            baud_counter <= 0;
            sample_counter <= 0;
            baud_tick <= 0;
            sample_tick <= 0;
        end else begin
            // Baud rate counter (1x)
            if (baud_counter == baud_divisor - 1) begin
                baud_counter <= 0;
                baud_tick <= 1;
            end else begin
                baud_counter <= baud_counter + 1;
                baud_tick <= 0;
            end
            
            // Sample rate counter (16x)
            if (sample_counter == 15) begin
                sample_counter <= 0;
                sample_tick <= 1;
            end else begin
                sample_counter <= sample_counter + 1;
                sample_tick <= 0;
            end
        end
    end
endmodule
