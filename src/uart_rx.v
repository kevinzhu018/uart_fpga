`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/13/2026 11:10:27 AM
// Design Name: 
// Module Name: uart_rx
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


module uart_rx(
    input clk,
    input rst,
    input rx,
    output reg rx_sync,
    output falling_edge,
    output reg [7:0] rx_data,
    output reg data_valid,
    output reg frame_error
    );
    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;
    reg [1:0] next_state;
    reg [2:0] bit_index;
    reg [7:0] shift_reg;

    reg rx_ff1;
    reg rx_sync_prev;
    always @(posedge clk) begin
        if (rst) begin
            rx_ff1 <= 1'b1;
            rx_sync <= 1'b1;
            rx_sync_prev <= 1'b1;
        end else begin
            rx_ff1 <= rx;
            rx_sync <= rx_ff1;
            rx_sync_prev <= rx_sync;
        end
    end
    assign falling_edge = rx_sync_prev && !rx_sync;

    wire sample_tick;
    reg active;
    rx_timer #(.CLKS_PER_BIT(10416)) TIMER (
        .clk(clk),
        .rst(rst),
        .active(active),
        .start(falling_edge && state == IDLE),
        .sample_tick(sample_tick)
        );

    // FSM - combinational: only next_state, no output assignments here.
    // data_valid / frame_error are registered below so they land on the
    // same cycle rx_data's non-blocking update actually becomes visible.
    always @(*) begin
        next_state = state;

        case (state)
            IDLE: begin
                if (falling_edge)
                    next_state = START;
            end

            START: begin
                if (sample_tick) begin
                    if (rx_sync == 1'b0)
                        next_state = DATA;
                    else
                        next_state = IDLE;
                end
            end

            DATA: begin
                if (sample_tick) begin
                    if (bit_index == 3'd7)
                        next_state = STOP;
                end
            end

            STOP: begin
                if (sample_tick)
                    next_state = IDLE;
            end
        endcase
    end

    // FSM - sequential: state, active, bit_index, shift_reg, rx_data.
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            bit_index <= 3'b0;
            active <= 1'b0;
            shift_reg <= 8'b0;
            rx_data <= 8'b0;
        end
        else begin
            state <= next_state;

            if (state == IDLE && falling_edge)
                active <= 1'b1;
            else if (state == STOP && sample_tick)
                active <= 1'b0;
            else if (state == START && sample_tick && rx_sync == 1'b1)
                active <= 1'b0;

            if (state == START && sample_tick && rx_sync == 1'b0)
                bit_index <= 3'b0;
            else if (state == DATA && sample_tick)
                bit_index <= bit_index + 1;

            if (state == DATA && sample_tick)
                shift_reg[bit_index] <= rx_sync;

            if (state == STOP && sample_tick && rx_sync == 1'b1)
                rx_data <= shift_reg;
        end
    end

    // data_valid / frame_error - registered, one cycle behind the STOP-tick
    // condition, aligned with when rx_data's own update becomes visible.
    always @(posedge clk) begin
        if (rst) begin
            data_valid  <= 1'b0;
            frame_error <= 1'b0;
        end else begin
            data_valid  <= (state == STOP && sample_tick && rx_sync == 1'b1);
            frame_error <= (state == STOP && sample_tick && rx_sync == 1'b0);
        end
    end

endmodule