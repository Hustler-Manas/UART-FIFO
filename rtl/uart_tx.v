module uart_tx #(
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst,

    input  wire [DATA_WIDTH-1:0] data_in,
    input  wire                  start,

    input  wire                  baud_tick,

    output reg                   tx,
    output reg                   busy,
    output reg                   done
);

    // State definitions
    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;

    // Holds the byte currently being transmitted
    reg [DATA_WIDTH-1:0] shift_reg;

    // Counts transmitted data bits
    reg [3:0] bit_count;

    always @(posedge clk) begin

        if (rst) begin
            state     <= IDLE;
            shift_reg <= 0;
            bit_count <= 0;

            // UART idle state is HIGH
            tx        <= 1'b1;

            busy      <= 1'b0;
            done      <= 1'b0;
        end

        else begin

            // done is a one-clock pulse
            done <= 1'b0;

            case (state)

                IDLE: begin
                    tx   <= 1'b1;
                    busy <= 1'b0;

                    if (start) begin
                        shift_reg <= data_in;
                        bit_count <= 0;
                        busy      <= 1'b1;
                        state     <= START;
                    end
                end

                START: begin
                    if (baud_tick) begin
                        tx    <= 1'b0;
                        state <= DATA;
                    end
                end

                DATA: begin
                    if (baud_tick) begin

                        // Send LSB first
                        tx <= shift_reg[0];

                        // Shift to next bit
                        shift_reg <= shift_reg >> 1;

                        if (bit_count == DATA_WIDTH-1) begin
                            bit_count <= 0;
                            state     <= STOP;
                        end
                        else begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end

                STOP: begin
                    if (baud_tick) begin
                        tx    <= 1'b1;
                        busy  <= 1'b0;
                        done  <= 1'b1;
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                    tx    <= 1'b1;
                    busy  <= 1'b0;
                end

            endcase
        end
    end

endmodule