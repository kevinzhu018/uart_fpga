`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/13/2026 01:43:27 PM
// Design Name: 
// Module Name: uart_rx_tb
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

//detect falling edge
/*
module uart_rx_tb;
    reg clk = 0;
    reg rst;
    reg rx ;
    wire rx_sync;
    wire falling_edge;
    
    uart_rx DUT(
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .rx_sync(rx_sync),
        .falling_edge(falling_edge)
        );
        
        always #5 clk = ~clk;
        initial begin
            rst = 1;
            rx = 1;
            repeat(5) @(posedge clk);
            rst = 0;
            
            repeat(5) @(posedge clk);
            rx = 0;
            repeat(2) @(posedge clk);
            if (falling_edge !== 1'b1)
                $display("FAIL: falling_edge did not pulse when expected");
            else
                $display("PASS: falling_edge pulsed correctly");
        
            repeat(5) @(posedge clk);
            $display("Simulation complete");
            $finish;
        end

endmodule */
module uart_rx_tb;
    reg clk = 0;
    reg rst;
    reg rx;
    wire [7:0] rx_data;
    wire data_valid;
    wire frame_error;
    integer errors = 0;

    localparam CLKS_PER_BIT = 10416;
    localparam TIMEOUT_CYCLES = 15 * CLKS_PER_BIT;

    uart_rx DUT (
        .clk(clk), .rst(rst), .rx(rx),
        .rx_data(rx_data), .data_valid(data_valid), .frame_error(frame_error)
        );

    always #5 clk = ~clk;

    task send_byte(input [7:0] data);
        integer i;
        begin
            rx = 1'b0;
            repeat (CLKS_PER_BIT) @(posedge clk);
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                repeat (CLKS_PER_BIT) @(posedge clk);
            end
            rx = 1'b1;
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    task send_and_check(input [7:0] data);
        integer i;
        reg got_valid;
        begin
            got_valid = 1'b0;
            fork
                send_byte(data);
                begin
                    for (i = 0; i < TIMEOUT_CYCLES && !got_valid; i = i + 1) begin
                        @(posedge clk);
                        if (data_valid) got_valid = 1'b1;
                    end
                end
            join

            if (!got_valid) begin
                $display("FAIL: timeout, sent %h", data);
                errors = errors + 1;
            end else if (rx_data !== data) begin
                $display("FAIL: expected %h, got %h", data, rx_data);
                errors = errors + 1;
            end else begin
                $display("PASS: %h", data);
            end
        end
    endtask

    initial begin
        rst = 1;
        rx = 1;
        repeat (5) @(posedge clk);
        rst = 0;
        repeat (5) @(posedge clk);

        send_and_check(8'h55);
        send_and_check(8'hAA);
        send_and_check(8'h00);
        send_and_check(8'hFF);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);

        $finish;
    end
endmodule
