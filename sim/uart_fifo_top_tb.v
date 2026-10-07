`timescale 1ns / 1ps

module uart_fifo_top_tb;

    reg        clk;
    reg        rst;

    reg  [7:0] tx_data;
    reg        tx_write;
    wire       tx_full;

    wire [7:0] rx_data;
    reg        rx_read;
    wire       rx_empty;

    wire       uart_tx;
    wire       uart_rx;

    // -------------------------------------------------
    // UART loopback
    // -------------------------------------------------
    assign uart_rx = uart_tx;

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------
    uart_fifo_top uut (
        .clk      (clk),
        .rst      (rst),

        .tx_data  (tx_data),
        .tx_write (tx_write),
        .tx_full  (tx_full),

        .rx_data  (rx_data),
        .rx_read  (rx_read),
        .rx_empty (rx_empty),

        .uart_rx  (uart_rx),
        .uart_tx  (uart_tx)
    );

    // -------------------------------------------------
    // 50 MHz clock
    // Period = 20 ns
    // -------------------------------------------------
    always #10 clk = ~clk;

    // -------------------------------------------------
    // Task: write one byte into TX FIFO
    // -------------------------------------------------
    task send_byte;
        input [7:0] data;
        begin

            @(negedge clk);

            // Wait if TX FIFO is full
            while (tx_full) begin
                @(negedge clk);
            end

            tx_data  = data;
            tx_write = 1'b1;

            @(negedge clk);

            tx_write = 1'b0;

        end
    endtask

    // -------------------------------------------------
    // Task: read one byte from RX FIFO
    // -------------------------------------------------
    task receive_byte;
        input [7:0] expected;
        begin

            // Wait until RX FIFO contains data
            while (rx_empty) begin
                @(negedge clk);
            end

            // Request FIFO read
            @(negedge clk);
            rx_read = 1'b1;

            @(posedge clk);
            #1;

            rx_read = 1'b0;

            // Check received value
            if (rx_data == expected)
                $display("PASS: Received %02h", rx_data);
            else
                $display("FAIL: Expected %02h, Received %02h",
                         expected, rx_data);

        end
    endtask

    // -------------------------------------------------
    // TEST
    // -------------------------------------------------
    initial begin

        // Initial values
        clk      = 1'b0;
        rst      = 1'b1;

        tx_data  = 8'h00;
        tx_write = 1'b0;
        rx_read  = 1'b0;

        // -------------------------------------------------
        // RESET
        // -------------------------------------------------
        #100;
        rst = 1'b0;

        $display("----------------------------------------");
        $display("UART + FIFO LOOPBACK TEST START");
        $display("----------------------------------------");

        // -------------------------------------------------
        // Send four bytes
        // -------------------------------------------------
        send_byte(8'h55);
        send_byte(8'hAA);
        send_byte(8'h12);
        send_byte(8'h34);

        $display("TX: 55 AA 12 34");

        // -------------------------------------------------
        // Receive four bytes
        // -------------------------------------------------
        receive_byte(8'h55);
        receive_byte(8'hAA);
        receive_byte(8'h12);
        receive_byte(8'h34);

        $display("----------------------------------------");
        $display("UART + FIFO LOOPBACK TEST COMPLETE");
        $display("----------------------------------------");

        #100;

        $finish;

    end

endmodule