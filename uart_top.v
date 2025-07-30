module uart_top(
    input clk,
    input reset,
    input [15:0] baud_divisor,  // Clock divider for desired baud rate
    input parity_en,             // Enable parity bit
    input parity_type,           // 0=even, 1=odd
    
    // Transmitter interface
    input tx_start,
    input [7:0] tx_data,
    output tx_busy,
    output txd,
    
    // Receiver interface
    input rxd,
    output [7:0] rx_data,
    output rx_valid,
    output parity_error,
    output stop_error
);
    // Baud rate and sampling signals
    wire baud_tick;   // 1x baud rate
    wire sample_tick; // 16x baud rate
    
    // Baud rate generator
    baud_rate_gen brg(
        .clk(clk),
        .reset(reset),
        .baud_divisor(baud_divisor),
        .baud_tick(baud_tick),
        .sample_tick(sample_tick)
    );
    
    // Transmitter
    uart_tx transmitter(
        .clk(clk),
        .reset(reset),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .parity_en(parity_en),
        .parity_type(parity_type),
        .txd(txd),
        .tx_busy(tx_busy)
    );
    
    // Receiver
    uart_rx receiver(
        .clk(clk),
        .reset(reset),
        .sample_tick(sample_tick),
        .rxd(rxd),
        .parity_en(parity_en),
        .parity_type(parity_type),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .parity_error(parity_error),
        .stop_error(stop_error)
    );
endmodule
