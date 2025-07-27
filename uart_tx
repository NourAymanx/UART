module uart_tx (
    input clk,
    input reset,
    input baud_tick,
    input tx_start,
    input [7:0] tx_data,
    input parity_en,
    input parity_type,   // 0 for even, 1 for odd parity
    output reg txd,         // Serial output
    output reg tx_busy      // High during transmission
);

/*IDLE: Waiting for transmission request , txd is idle-high (1) , Waits for tx_start signal

START: Sending the start bit (0)

DATA: Shifting out data bits (LSB first)

PARITY: Sending parity bit (if enabled)

STOP: Sending stop bit (1)*/

//states
localparam IDLE  = 3'd0;
localparam START = 3'd1;
localparam DATA  = 3'd2;
localparam PARITY= 3'd3;
localparam STOP  = 3'd4;

reg [2:0] state; // now using a 3-bit reg to represent FSM state
reg [2:0] bit_index; //When bit_index == 7 (last data bit): If parity is enabled go to PARITY ,Else go to STOP ,Otherwise increment bit_index and stay in DATA
reg [7:0] tx_reg;   //internal shift register tx_reg
reg tx_parity;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        txd <= 1'b1;
        tx_busy <= 1'b0;
        bit_index <= 0; // reset index
        tx_parity <= 0;
        tx_reg <= 8'd0;
    end else if (baud_tick) begin  //Only update on baud_tick
        case(state)
            IDLE : begin
                txd <= 1'b1;
                if (tx_start) begin
                    state <= START;
                    tx_reg <= tx_data;
                    tx_busy <= 1'b1;
                    // Calculate parity if enabled
                    if (parity_en) begin
                        tx_parity <= ^tx_data;  // XOR all bits
                        if (parity_type) tx_parity <= ~(^tx_data);  // Invert for odd parity
                    end
                end
            end

            START : begin
                txd <= 1'b0;
                state <= DATA;
                bit_index <= 0;
            end

            DATA: begin
                txd <= tx_reg[bit_index];  // Send LSB first
                if (bit_index == 3'd7) begin
                    if (parity_en)
                        state <= PARITY;
                    else
                        state <= STOP;
                end else begin
                    bit_index <= bit_index + 1;
                end
            end

            PARITY: begin
                txd <= tx_parity;
                state <= STOP;
            end

            STOP: begin
                txd <= 1'b1;  // stop bit is always high
                tx_busy <= 1'b0;
                state <= IDLE;
            end
        endcase
    end
end

endmodule
