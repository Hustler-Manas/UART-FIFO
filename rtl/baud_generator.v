module baud_generator #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire clk,
    input  wire rst,
    output reg  baud_tick
);

    // Number of clock cycles per UART bit
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    reg [31:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            counter   <= 32'd0;
            baud_tick <= 1'b0;
        end
        else begin
            if (counter == CLKS_PER_BIT - 1) begin
                counter   <= 32'd0;
                baud_tick <= 1'b1;
            end
            else begin
                counter   <= counter + 1'b1;
                baud_tick <= 1'b0;
            end
        end
    end

endmodule