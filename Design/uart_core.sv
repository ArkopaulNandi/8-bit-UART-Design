`timescale 1ns/1ps
`include "uart_registers.sv"
`include "uart_rx.sv"
`include "uart_tx.sv"
`include "baud_rate_gen.sv"

module uart_core #(
    parameter DATA_WIDTH = 8,
    parameter BAUD_DIV_WIDTH = 16,
    parameter ADDR_WIDTH = 4
) (
    input logic clk,
    input logic rst_n,
    input logic [ADDR_WIDTH-1:0] addr,
    input logic rd_en,
    input logic wr_en,
    input logic [31:0] write_data,
    output logic [31:0] read_data,
    input logic uart_rx,
    output logic uart_tx
);
    // Tx Internal Signals
    logic [DATA_WIDTH-1:0] tx_data;
    logic tx_start;
    logic tx_ready;
    logic tx_line;
    logic tx_busy;

    // Rx Internal Signals
    logic [DATA_WIDTH-1:0] rx_data;
    logic rx_valid;
    logic framing_error;
    logic overrun_error;

    //
    logic [BAUD_DIV_WIDTH-1:0] baud_divisor;
    logic baud_tick;

    assign tx_ready = ~tx_busy;

    uart_registers #(
        .DATA_WIDTH(DATA_WIDTH),
        .BAUD_DIV_WIDTH(BAUD_DIV_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut0 (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .write_data(write_data),
        .read_data(read_data),
        .tx_data(tx_data),
        .tx_ready(tx_ready),
        .tx_start(tx_start),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .framing_error(framing_error),
        .overrun_error(overrun_error),
        .baud_divisor(baud_divisor)
    );

    baud_rate_gen #(
        .BAUD_DIV_WIDTH(BAUD_DIV_WIDTH)
    ) dut1 (
        .clk(clk),
        .rst_n(rst_n),
        .divisor(baud_divisor),
        .baud_tick(baud_tick)
    );

    uart_tx dut2 (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_line(tx_line),
        .tx_busy(tx_busy)
    );

    uart_rx #(
        .DATA_BITS(DATA_WIDTH)
    ) dut3 (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_rx),
        .baud_tick(baud_tick),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .framing_error(framing_error),
        .overrun_error(overrun_error)
    );

    assign uart_tx = tx_line;
    
endmodule