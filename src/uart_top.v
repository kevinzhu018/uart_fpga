`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/23/2026 05:37:03 PM
// Design Name: 
// Module Name: uart_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_top(
    input clk,
    input rst,
    // TX side
    input send,
    input [7:0] tx_data,
    output tx,
    output tx_busy,
    // RX side
    input rx,
    output [7:0] rx_data,
    output rx_valid,
    output rx_frame_error
    );

    uart_tx TX (
        .clk(clk), .rst(rst), .send(send), .data(tx_data),
        .tx(tx), .busy(tx_busy)
        );

    uart_rx RX (
        .clk(clk), .rst(rst), .rx(rx),
        .rx_data(rx_data), .data_valid(rx_valid), .frame_error(rx_frame_error)
        );

endmodule