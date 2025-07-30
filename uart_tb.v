`timescale 1ns/1ps

module uart_tb;
    // System Parameters
    parameter CLK_PERIOD = 10;       // 100 MHz clock
    parameter BAUD_RATE = 115200;
    parameter BAUD_DIVISOR = 100000000/BAUD_RATE;
    
    // Test Parameters
    parameter TEST_DATA1 = 8'h55;    // 01010101
    parameter TEST_DATA2 = 8'hAA;    // 10101010
    parameter TEST_DATA3 = 8'h7E;    // 01111110
    parameter TEST_DATA4 = 8'h81;    // 10000001

    // Signals
    reg clk;
    reg reset;
    reg [15:0] baud_divisor;
    reg parity_en;
    reg parity_type;
    reg tx_start;
    reg [7:0] tx_data;
    wire tx_busy;
    wire txd;
    wire rxd;
    wire [7:0] rx_data;
    wire rx_valid;
    wire parity_error;
    wire stop_error;
    
    // Test control
    integer test_num;
    integer error_count;
    
    // Instantiate UUT
    uart_top uut (
        .clk(clk),
        .reset(reset),
        .baud_divisor(baud_divisor),
        .parity_en(parity_en),
        .parity_type(parity_type),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_busy(tx_busy),
        .txd(txd),
        .rxd(rxd),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .parity_error(parity_error),
        .stop_error(stop_error)
    );
    
    // Connect TX to RX for loopback testing
    assign rxd = txd;
    
    // Clock Generation
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Waveform Dumping
    initial begin
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb);
    end
    
    // Main Test Procedure
    initial begin
        // Initialize
        reset = 1'b1;
        baud_divisor = BAUD_DIVISOR;
        parity_en = 1'b0;
        parity_type = 1'b0;
        tx_start = 1'b0;
        tx_data = 8'h00;
        test_num = 0;
        error_count = 0;
        
        // Reset
        #100;
        reset = 1'b0;
        #100;
        
        // Test 1: Basic Transmission (no parity)
        test_num = 1;
        tx_data = TEST_DATA1;
        tx_start = 1'b1;
        #CLK_PERIOD;
        tx_start = 1'b0;
        
        wait(rx_valid);
        #10;
        
        if (rx_data == TEST_DATA1 && !parity_error && !stop_error)
            $display("Test %0d PASSED: Basic TX/RX", test_num);
        else begin
            $display("Test %0d FAILED: Expected %h, Got %h", test_num, TEST_DATA1, rx_data);
            error_count = error_count + 1;
        end
        
        // Test 2: Different data pattern
        test_num = 2;
        #(BAUD_DIVISOR * CLK_PERIOD * 12); // Wait for complete transmission
        tx_data = TEST_DATA2;
        tx_start = 1'b1;
        #CLK_PERIOD;
        tx_start = 1'b0;
        
        wait(rx_valid);
        #10;
        
        if (rx_data == TEST_DATA2 && !parity_error && !stop_error)
            $display("Test %0d PASSED: Different data pattern", test_num);
        else begin
            $display("Test %0d FAILED: Expected %h, Got %h", test_num, TEST_DATA2, rx_data);
            error_count = error_count + 1;
        end
        
        // Test 3: With even parity
        test_num = 3;
        #(BAUD_DIVISOR * CLK_PERIOD * 12);
        parity_en = 1'b1;
        parity_type = 1'b0; // Even
        tx_data = TEST_DATA3;
        tx_start = 1'b1;
        #CLK_PERIOD;
        tx_start = 1'b0;
        
        wait(rx_valid);
        #10;
        
        if (rx_data == TEST_DATA3 && !parity_error && !stop_error)
            $display("Test %0d PASSED: Even parity", test_num);
        else begin
            $display("Test %0d FAILED: Expected %h, Got %h", test_num, TEST_DATA3, rx_data);
            error_count = error_count + 1;
        end
        
        // Test 4: With odd parity
        test_num = 4;
        #(BAUD_DIVISOR * CLK_PERIOD * 12);
        parity_type = 1'b1; // Odd
        tx_data = TEST_DATA4;
        tx_start = 1'b1;
        #CLK_PERIOD;
        tx_start = 1'b0;
        
        wait(rx_valid);
        #10;
        
        if (rx_data == TEST_DATA4 && !parity_error && !stop_error)
            $display("Test %0d PASSED: Odd parity", test_num);
        else begin
            $display("Test %0d FAILED: Expected %h, Got %h", test_num, TEST_DATA4, rx_data);
            error_count = error_count + 1;
        end
        
        // Test 5: Parity error detection
        test_num = 5;
        #(BAUD_DIVISOR * CLK_PERIOD * 12);
        
        // Manually inject error by breaking loopback
        force rxd = 1'b1; // Force stop bit condition
        tx_data = TEST_DATA1;
        tx_start = 1'b1;
        #CLK_PERIOD;
        tx_start = 1'b0;
        
        wait(rx_valid || stop_error);
        #10;
        release rxd;
        
        if (stop_error)
            $display("Test %0d PASSED: Stop error detected", test_num);
        else begin
            $display("Test %0d FAILED: Stop error not detected", test_num);
            error_count = error_count + 1;
        end
        
        // Final Summary
        #100;
        $display("\nTestbench complete. %0d errors detected.", error_count);
        $finish;
    end
    
    // Monitor for debugging
    initial begin
        $monitor("Time=%0t TX_State=%d RX_State=%d TXD=%b RXD=%b TX_Data=%h RX_Data=%h RX_Valid=%b",
                $time, 
                uut.transmitter.state, 
                uut.receiver.state,
                txd, 
                rxd,
                tx_data,
                rx_data,
                rx_valid);
    end
endmodule
