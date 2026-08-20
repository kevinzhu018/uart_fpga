`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/03/2026 09:47:00 AM
// Design Name: 
// Module Name: uart_tx
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


module uart_tx(
    input clk,
    input rst,
    input send,
    input [7:0] data,
    output reg tx,
    output reg busy
    );
    localparam IDLE  = 2'd0; //localparams to avoid being overriden
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    wire tick;
    wire sync_reset;

    // internal signals  not ports
    reg [1:0] state;
    reg [1:0] next_state;
    reg [2:0] bit_index;
    reg [7:0] data_latch;

    assign sync_reset = (state == IDLE) && send;

    clk_divider baud(
        .clk(clk),
        .rst(rst),
        .sync_reset(sync_reset),
        .tick(tick)
        );
        
    
    
    
    always@(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            bit_index  <= 3'b0;
            data_latch <= 8'b0;
        end
        else begin
            state <= next_state;
            
            if (state == IDLE && send)
                data_latch <= data;
            if (state == DATA && tick)
                bit_index <= bit_index + 1;
            if (state == STOP && tick)
                bit_index <= 3'b0;
            
        end
    end
         
    
    always @(*) begin
    next_state = state;
    tx   = 1;
    busy = 0;
        case (state)
            IDLE: begin
                if(send) begin
                    next_state = START;
                    busy = 1;
                end
            end
                
            START: begin
                tx = 0;
                if (tick) begin
                    next_state = DATA;                   
                end
            end
            
            DATA: begin
               tx = data_latch[bit_index];
               busy = 1;
                if (tick && (bit_index == 7)) begin
                    next_state = STOP;
                end
            end
            
            STOP: begin
                tx = 1;
                busy = 1;
                if(tick) begin
                    next_state = IDLE;   
                end
            end
        endcase
    end
    
endmodule
