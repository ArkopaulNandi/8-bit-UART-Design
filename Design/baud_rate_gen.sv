/* Baud Rate Generator 
   The function of this module is to produce 1 clock cycle pulse called baud tick 
   */

`timescale 1ns/1ps

module baud_rate_gen #(
    parameter BAUD_DIV_WIDTH = 16
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [BAUD_DIV_WIDTH-1:0] divisor,    // Number of clock cycles per baud tick
    output logic        baud_tick   // Goes HIGH for exactly one clock cycle
);

    logic [15:0] counter;           // Counter for synchronising the baud tick with the baud rate

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter   <= 16'b0;
            baud_tick <= 1'b0;
        end else begin
            if (counter == divisor - 1) begin
                counter   <= 16'b0;
                baud_tick <= 1'b1;
            end else begin
                counter   <= counter + 1'b1; 
                baud_tick <= 1'b0;
            end
        end        
    end

endmodule