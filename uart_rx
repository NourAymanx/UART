module uart_rx( 
    input clk,
    input reset,
    input sample_tick,       // 16x baud rate sampling
    input rxd,               // Serial input
    input parity_en,         // Enable parity checking
    input parity_type,       // 0=even, 1=odd
    output reg [7:0] rx_data, // Received parallel data
    output reg rx_valid,     // Data valid pulse
    output reg parity_error, // Parity error flag
    output reg stop_error    // Stop bit error flag
);


localparam IDLE  = 3'd0;
localparam START = 3'd1;
localparam DATA  = 3'd2;
localparam PARITY= 3'd3;
localparam STOP  = 3'd4;

reg [2:0] state;              // FSM current state
reg [3:0] sample_counter;     // 16x oversampling counter
reg [2:0] bit_index;          // Bit index for data reception
reg [7:0] rx_reg;             // Register to hold received bits
reg rx_parity;                // Computed parity

always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        rx_valid <= 1'b0;
        parity_error <= 1'b0;
        stop_error <= 1'b0;
        sample_counter <= 0;
        bit_index <= 0;
        rx_reg <= 8'd0;
        rx_parity <= 1'b0;
    end else if (sample_tick) begin  // Only update on sampling ticks
        case (state)
            IDLE: begin
                rx_valid <= 1'b0;
                parity_error <= 1'b0;
                stop_error <= 1'b0;
                if (!rxd) begin  // Falling edge => start bit
                    state <= START;
                    sample_counter <= 0;
                end
            end

            START: begin
                if (sample_counter == 4'd7) begin  // Sample in middle
                    if (!rxd) begin
                        state <= DATA;
                        bit_index <= 0;
                        sample_counter <= 0;
                        rx_parity <= 1'b0;
                    end else begin
                        state <= IDLE;  // False start
                    end
                end else begin
                    sample_counter <= sample_counter + 1;
                end
            end

            DATA: begin
                if (sample_counter == 4'd15) begin
                    rx_reg[bit_index] <= rxd;
                    rx_parity <= rx_parity ^ rxd;
                    sample_counter <= 0;

                    if (bit_index == 3'd7) begin
                        if (parity_en)
                            state <= PARITY;
                        else
                            state <= STOP;
                    end else begin
                        bit_index <= bit_index + 1;
                    end
                end else begin
                    sample_counter <= sample_counter + 1;
                end
            end

            PARITY: begin
                if (sample_counter == 4'd15) begin
                    // Check received parity
                    if (parity_type) begin  // Odd parity
                        parity_error <= (rx_parity == rxd);
                    end else begin          // Even parity
                        parity_error <= (rx_parity != rxd);
                    end
                    sample_counter <= 0;
                    state <= STOP;
                end else begin
                    sample_counter <= sample_counter + 1;
                end
            end

            STOP: begin
                if (sample_counter == 4'd15) begin
                    stop_error <= !rxd;  // Should be 1
                    rx_data <= rx_reg;
                    rx_valid <= 1'b1;
                    state <= IDLE;
                end else begin
                    sample_counter <= sample_counter + 1;
                end
            end
        endcase
    end
end

endmodule                                                  
