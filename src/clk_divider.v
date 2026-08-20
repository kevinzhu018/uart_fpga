`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/02/2026 06:00:41 PM
// Design Name: 
// Module Name: clk_divider
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


module clk_divider(
    input clk,
    input rst,
    input sync_reset,   
    output reg tick
    );
    
    parameter CLKS_PER_BIT = 10416;
    reg [13:0] counter;
    
    always @(posedge clk) begin 
    if (rst || sync_reset) begin
        counter <= 14'b0;
        tick    <= 0;
    end
    else if (counter == CLKS_PER_BIT - 1) begin
        counter <= 14'b0;
        tick    <= 1;
    end
    else begin
        counter <= counter + 1;
        tick    <= 0;
    end
end
           
endmodule
