`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/13/2026 02:27:09 PM
// Design Name: 
// Module Name: rx_timer
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


module rx_timer(
    input clk,
    input rst,
    input active,        
    input start,          // one-cycle pulse to (re)start the timer (falling_edge)
    output reg sample_tick
    );

    parameter CLKS_PER_BIT = 10416;

    reg [13:0] counter;
    reg [13:0] target;
    reg first_tick_done;

    always @(posedge clk) begin
        if (rst || !active) begin
            counter <= 14'b0;
            target <= CLKS_PER_BIT / 2;
            first_tick_done <= 1'b0;
            sample_tick <= 1'b0;
        end
        else if (start) begin
            // restart timer fresh at the falling edge
            counter <= 14'b0;
            target <= CLKS_PER_BIT / 2;
            first_tick_done <= 1'b0;
            sample_tick <= 1'b0;
        end
        else if (counter == target - 1) begin
            counter <= 14'b0;
            sample_tick <= 1'b1;
            if (!first_tick_done) begin
                target <= CLKS_PER_BIT;  // switch to full-period ticks
                first_tick_done <= 1'b1;
            end
        end
        else begin
            counter <= counter + 1;
            sample_tick <= 1'b0;
        end
    end

endmodule
