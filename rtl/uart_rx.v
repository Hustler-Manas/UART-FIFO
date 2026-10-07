module uart_rx #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115200,
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst,

    input  wire                  rx,

    output reg  [DATA_WIDTH-1:0] data_out,
    output reg                   data_valid,
    output reg                   busy
);

    // Number of system-clock cycles in one UART bit
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam HALF_BIT     = CLKS_PER_BIT / 2;

    // UART receiver states
    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam DATA  = 3'd2;
    localparam STOP  = 3'd3;

    reg [2:0] state;

    // Clock counter
    reg [31:0] clk_count;

    // Data bit counter
    reg [3:0] bit_count;

    // Receive shift register
    reg [DATA_WIDTH-1:0] shift_reg;

    always @(posedge clk) begin

        if (rst) begin
            state      <= IDLE;
            clk_count  <= 32'd0;
            bit_count  <= 4'd0;
            shift_reg  <= 8'd0;

            data_out   <= 8'd0;
            data_valid <= 1'b0;
            busy       <= 1'b0;
        end

        else begin

            // data_valid is a one-clock pulse
            data_valid <= 1'b0;

            case (state)

                // --------------------------------
                // IDLE
                // --------------------------------
                IDLE: begin

                    clk_count <= 32'd0;
                    bit_count <= 4'd0;
                    busy      <= 1'b0;

                    // UART start bit is LOW
                    if (rx == 1'b0) begin
                        busy      <= 1'b1;
                        state     <= START;
                        clk_count <= 32'd0;
                    end

                end


                // --------------------------------
                // START BIT
                // --------------------------------
                START: begin

                    if (clk_count == HALF_BIT - 1) begin

                        clk_count <= 32'd0;

                        // Confirm that this is still LOW
                        if (rx == 1'b0) begin
                            state <= DATA;
                        end
                        else begin
                            // False start
                            state <= IDLE;
                            busy  <= 1'b0;
                        end

                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end

                end


                // --------------------------------
                // DATA BITS
                // --------------------------------
                DATA: begin

                    if (clk_count == CLKS_PER_BIT - 1) begin

                        clk_count <= 32'd0;

                        // Sample data bit
                        shift_reg[bit_count] <= rx;

                        if (bit_count == DATA_WIDTH - 1) begin
                            bit_count <= 4'd0;
                            state     <= STOP;
                        end
                        else begin
                            bit_count <= bit_count + 1'b1;
                        end

                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end

                end


                // --------------------------------
                // STOP BIT
                // --------------------------------
                STOP: begin

                    if (clk_count == CLKS_PER_BIT - 1) begin

                        clk_count <= 32'd0;

                        // Stop bit should be HIGH
                        if (rx == 1'b1) begin

                            data_out   <= shift_reg;
                            data_valid <= 1'b1;

                        end

                        state <= IDLE;
                        busy  <= 1'b0;

                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end

                end


                default: begin
                    state     <= IDLE;
                    clk_count <= 32'd0;
                    bit_count <= 4'd0;
                    busy      <= 1'b0;
                end

            endcase
        end
    end

endmodule 