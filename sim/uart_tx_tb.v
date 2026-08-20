`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/16/2026 02:53:52 PM
// Design Name: 
// Module Name: uart_tx_tb
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


module uart_tx_tb;
    reg clk = 0;
    reg rst;
    reg send;
    reg [7:0] data;
    wire tx;
    wire busy;
    integer errors = 0;

    localparam CLKS_PER_BIT = 10416;

    uart_tx DUT (
        .clk(clk), .rst(rst), .send(send), .data(data),
        .tx(tx), .busy(busy)
        );

    always #5 clk = ~clk;

    // samples tx at the middle of each bit period and rebuilds the byte
    task send_and_check(input [7:0] expected);
        reg [7:0] captured;
        integer i;
        begin
            while (busy) @(posedge clk);
            @(posedge clk);
            send = 1;
            data = expected;
            @(posedge clk);
            send = 0;

            // wait to the middle of the start bit
            repeat (CLKS_PER_BIT/2) @(posedge clk);
            if (tx !== 1'b0) begin
                $display("FAIL: start bit not 0 for %h", expected);
                errors = errors + 1;
            end

            for (i = 0; i < 8; i = i + 1) begin
                repeat (CLKS_PER_BIT) @(posedge clk);
                captured[i] = tx;
            end

            repeat (CLKS_PER_BIT) @(posedge clk);
            if (tx !== 1'b1) begin
                $display("FAIL: stop bit not 1 for %h", expected);
                errors = errors + 1;
            end

            if (captured !== expected) begin
                $display("FAIL: expected %h, got %h", expected, captured);
                errors = errors + 1;
            end else begin
                $display("PASS: %h", expected);
            end
        end
    endtask

    initial begin
        rst = 1;
        send = 0;
        data = 8'b0;
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