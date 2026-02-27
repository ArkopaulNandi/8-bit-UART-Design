/* UART Tx Module
The fucntion of this module is to send out 8 bit data serially 
with the start and the stop bits sychronised with the baud ticks 
*/

`timescale 1ns/1ps

module uart_tx (
    input logic       clk,
    input logic       rst_n,
    input logic       baud_tick,    // High Signal for one clock cycle
    input logic       tx_start,     // Start signal for transmitting
    input logic [7:0] tx_data,      // Parallel data that is to be transmitted
    output logic      tx_line,      // Actual UART Line
    output logic      tx_busy       // Status Signal
);

    typedef enum logic [1:0] {      // States of the UART Transmitter
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11
    } tx_states;

    tx_states state;

    logic [7:0] shift_reg;          // Internal shift register
    logic [2:0] bit_count;          // Bit Counter for tracking transmitting bits

    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin
            state     <= IDLE;
            tx_line   <= 1'b1;
            tx_busy   <= 1'b0;
            bit_count <= 3'd0;
            shift_reg <= 8'b0;
        end else begin
            if (baud_tick) begin
                case (state)

                    IDLE: begin
                        tx_line <= 1'b1;
                        tx_busy <= 1'b0;
                        if (tx_start) begin
                            shift_reg <= tx_data;
                            tx_busy   <= 1'b1;
                            state     <= START;
                        end
                    end 

                    START:  begin
                        tx_line   <= 1'b0;
                        bit_count <= 3'd0;
                        state     <= DATA;
                    end

                    DATA: begin
                        tx_line   <= shift_reg[0];
                        shift_reg <= shift_reg >> 1;
                        if (bit_count == 3'd7) begin
                            state <= STOP;
                        end else begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end

                    STOP: begin
                        tx_line <= 1'b1;
                        tx_busy <= 1'b0;
                        state   <= IDLE;
                    end
                endcase
            end
        end
    end
    
endmodule