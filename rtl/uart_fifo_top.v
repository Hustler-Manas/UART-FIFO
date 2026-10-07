module uart_fifo_top (
    input  wire       clk,
    input  wire       rst,

    // -------------------------
    // System TX interface
    // -------------------------
    input  wire [7:0] tx_data,
    input  wire       tx_write,
    output wire       tx_full,

    // -------------------------
    // System RX interface
    // -------------------------
    output wire [7:0] rx_data,
    input  wire       rx_read,
    output wire       rx_empty,

    // -------------------------
    // UART interface
    // -------------------------
    input  wire       uart_rx,
    output wire       uart_tx
);

    // =========================================================
    // Baud generator
    // =========================================================

    wire baud_tick;

    baud_generator #(
        .CLK_FREQ  (50_000_000),
        .BAUD_RATE (115200)
    ) baud_gen (
        .clk       (clk),
        .rst       (rst),
        .baud_tick (baud_tick)
    );


    // =========================================================
    // TX FIFO
    // =========================================================

    wire [7:0] tx_fifo_data;
    wire       tx_fifo_empty;

    reg        tx_fifo_rd_en;

    fifo #(
        .DATA_WIDTH (8),
        .FIFO_DEPTH (16)
    ) tx_fifo (
        .clk     (clk),
        .rst     (rst),

        .wr_data (tx_data),
        .wr_en   (tx_write),
        .full    (tx_full),

        .rd_data (tx_fifo_data),
        .rd_en   (tx_fifo_rd_en),
        .empty   (tx_fifo_empty)
    );


    // =========================================================
    // UART TX
    // =========================================================

    reg        tx_start;
    wire       tx_busy;
    wire       tx_done;

    uart_tx #(
        .DATA_WIDTH (8)
    ) uart_transmitter (
        .clk       (clk),
        .rst       (rst),

        .data_in   (tx_fifo_data),
        .start     (tx_start),

        .baud_tick (baud_tick),

        .tx        (uart_tx),
        .busy      (tx_busy),
        .done      (tx_done)
    );


    // =========================================================
    // TX control
    //
    // FIFO read occurs one clock before UART TX start.
    // This is necessary because FIFO rd_data is registered.
    // =========================================================

    reg tx_pending;

    always @(posedge clk) begin

        if (rst) begin
            tx_fifo_rd_en <= 1'b0;
            tx_start      <= 1'b0;
            tx_pending    <= 1'b0;
        end

        else begin

            // Default: both are one-clock pulses
            tx_fifo_rd_en <= 1'b0;
            tx_start      <= 1'b0;

            // Read next byte from FIFO
            if (!tx_pending && !tx_busy && !tx_fifo_empty) begin
                tx_fifo_rd_en <= 1'b1;
                tx_pending    <= 1'b1;
            end

            // Start UART transmission one clock later
            else if (tx_pending && !tx_busy) begin
                tx_start   <= 1'b1;
                tx_pending <= 1'b0;
            end

        end
    end


    // =========================================================
    // UART RX
    // =========================================================

    wire [7:0] rx_byte;
    wire       rx_valid;
    wire       rx_busy;

    uart_rx #(
        .CLK_FREQ   (50_000_000),
        .BAUD_RATE  (115200),
        .DATA_WIDTH (8)
    ) uart_receiver (
        .clk        (clk),
        .rst        (rst),

        .rx         (uart_rx),

        .data_out   (rx_byte),
        .data_valid (rx_valid),
        .busy       (rx_busy)
    );


    // =========================================================
    // RX FIFO
    // =========================================================

    wire       rx_fifo_full;

    fifo #(
        .DATA_WIDTH (8),
        .FIFO_DEPTH (16)
    ) rx_fifo (
        .clk     (clk),
        .rst     (rst),

        .wr_data (rx_byte),
        .wr_en   (rx_valid && !rx_fifo_full),
        .full    (rx_fifo_full),

        .rd_data (rx_data),
        .rd_en   (rx_read),
        .empty   (rx_empty)
    );

endmodule