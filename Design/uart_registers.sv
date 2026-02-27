`timescale 1ns/1ps

module uart_registers #(
    parameter DATA_WIDTH     = 8,
    parameter BAUD_DIV_WIDTH = 16,
    parameter ADDR_WIDTH     = 4
) (
    // CPU Ports
    input logic                   clk,
    input logic                   rst_n,
    input logic [ADDR_WIDTH-1:0]  addr,
    input logic                   wr_en,
    input logic                   rd_en,
    input logic  [31:0]           write_data,
    output logic [31:0]           read_data,

    // UART_Tx Ports
    input logic                    tx_ready,
    output logic [DATA_WIDTH-1:0]  tx_data,
    output logic                   tx_start,

    // UART_Rx Ports
    input logic [DATA_WIDTH-1:0]  rx_data,
    input logic                   rx_valid,
    input logic                   framing_error,
    input logic                   overrun_error,

    // Baud Gen Ports
    output logic [BAUD_DIV_WIDTH-1:0] baud_divisor
);

    // Memory Allocation
    localparam logic [3:0] ADDR_TX_DATA = 4'h0;
    localparam logic [3:0] ADDR_RX_DATA = 4'h4;
    localparam logic [3:0] ADDR_STATUS  = 4'h8;
    localparam logic [3:0] ADDR_CONTROL = 4'hC;

    // Internal Registers
    logic [DATA_WIDTH-1:0] rx_data_reg;
    logic                  rx_buffer;
    logic                  framing_error_reg;
    logic                  overrun_error_reg;
    logic [31:0]           control_reg;
    logic                  tx_start_reg;

    assign tx_start = tx_start_reg;
    assign baud_divisor = control_reg[BAUD_DIV_WIDTH-1:0];

    always_ff @( posedge clk or negedge rst_n ) begin 
        if (!rst_n) begin
            rx_data_reg <= 8'b0;
            rx_buffer <= 1'b0;
            framing_error_reg <= 1'b0;
            overrun_error_reg <= 1'b0;
            control_reg <= 32'd0;
            control_reg[BAUD_DIV_WIDTH-1:0] <= 16'd27;
            tx_start_reg <= 1'b0;
        end else begin
            if (rx_valid) begin
                rx_data_reg <= rx_data;
                rx_buffer <= 1'b1;
                framing_error_reg <= framing_error;
                overrun_error_reg <= overrun_error;
            end
        end
    end

    always_ff @( posedge clk or negedge rst_n ) begin 
        if (!rst_n) begin
            rx_buffer <= 1'b0;
            framing_error_reg <= 1'b0;
            overrun_error_reg <= 1'b0;
        end else if (rd_en && addr == ADDR_RX_DATA) begin
            rx_buffer <= 1'b0;
            framing_error_reg <= 1'b0;
            overrun_error_reg <= 0;
        end
    end            

    always_ff @( posedge clk or negedge rst_n ) begin 
        tx_start_reg <= 1'b0;
        if (wr_en && addr == ADDR_TX_DATA) begin
            if (tx_ready == 1'b1) begin
                tx_data <= write_data[DATA_WIDTH-1:0];
                tx_start_reg <= 1'b1;
            end
        end

        if (wr_en && addr == ADDR_CONTROL) begin
            control_reg <= write_data;
        end
    end

    always_comb begin 
        read_data = 32'd0;

        case (addr) 
            ADDR_RX_DATA: begin
                read_data [DATA_WIDTH-1:0] = rx_data_reg;
            end

            ADDR_STATUS: begin
                read_data[0] = tx_ready;
                read_data[1] = rx_buffer;
                read_data[2] = framing_error_reg;
                read_data[3] = overrun_error_reg;
            end

            ADDR_CONTROL: begin
                read_data = control_reg;
            end

            default: read_data = 32'd0;
        endcase
    end
    
endmodule