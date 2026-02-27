`timescale 1ns/1ps

module uart_rx #(
    parameter DATA_BITS = 8
) (
    input logic                  clk,
    input logic                  rst_n,
    input logic                  rx,
    input logic                  baud_tick,
    output logic [DATA_BITS-1:0] rx_data,
    output logic                 rx_valid,
    output logic                 framing_error,
    output logic                 overrun_error
);

    typedef enum logic [1:0] { 
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11
    } rx_states;

    rx_states state;

    logic                       rx_sync1;
    logic                       rx_sync2;
    logic [$clog2(DATA_BITS):0] bit_count;
    logic [DATA_BITS-1:0]       shift_reg;
    logic                       rx_buffer;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= IDLE;
            bit_count     <= 3'd0;
            shift_reg     <= 8'b0;
            rx_data       <= 8'b0;
            rx_valid      <= 1'b0;
            framing_error <= 1'b0;
            overrun_error <= 1'b0;
            rx_buffer     <= 1'b0;
        end else begin
            rx_valid      <= 1'b0;

            case (state)
                IDLE: begin
                    framing_error <= 1'b0;
                    if (rx_sync2 == 1'b0) begin
                       state     <= START;
                       bit_count <= 4'b0; 
                    end
                end

                START: begin
                    if (baud_tick) begin
                        if (rx_sync2 == 1'b0) begin
                            state <= DATA;
                        end else begin
                            state <= IDLE;
                        end
                    end
                end

                DATA: begin
                    if (baud_tick == 1'b1) begin
                        shift_reg <= {rx_sync2, shift_reg[DATA_BITS-1:1]};
                        bit_count <= bit_count + 1'b1;
                        if (bit_count == DATA_BITS - 1) begin
                            state <= STOP;
                        end
                    end
                end 

                STOP: begin
                    if (baud_tick == 1'b1) begin
                       if (rx_sync2 == 1'b1) begin
                        if (rx_buffer == 1'b1) begin
                            overrun_error <= 1'b1;
                        end
                        rx_data   <= shift_reg;
                        rx_valid  <= 1'b1;
                        rx_buffer <= 1'b1;
                       end else begin
                        framing_error <= 1'b1;
                       end
                       state <= IDLE;
                    end
                end
            endcase
        end
    end
    
endmodule