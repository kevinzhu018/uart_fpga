`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/16/2026 03:35:31 PM
// Design Name: 
// Module Name: uart_full_tb
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


module uart_full_tb;
    reg clk = 0;
    reg rst;
    reg send;
    reg [7:0] tx_data;
    wire tx;
    wire tx_busy;
    reg rx;
    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_frame_error;
    integer errors = 0;

    localparam CLKS_PER_BIT = 10416;
    localparam TIMEOUT_CYCLES = 15 * CLKS_PER_BIT;

    uart_top DUT (
        .clk(clk), .rst(rst),
        .send(send), .tx_data(tx_data), .tx(tx), .tx_busy(tx_busy),
        .rx(rx), .rx_data(rx_data), .rx_valid(rx_valid), .rx_frame_error(rx_frame_error)
        );

    // loop tx back into rx externally, same as before, just through the
    // top-level module's ports this time instead of internal wires
    always @(*) rx = tx;

    always #5 clk = ~clk;

    task send_and_check(input [7:0] data);
        integer i;
        reg got_valid;
        begin
            while (tx_busy) @(posedge clk);   // wait for any prior frame to finish

            send <= 1;
            tx_data = data;
            @(posedge clk);
            send <= 0;

            // start watching for rx_valid immediately, before this frame
            // could possibly have finished. no race, nothing to catch late
            got_valid = 1'b0;
            for (i = 0; i < TIMEOUT_CYCLES && !got_valid; i = i + 1) begin
                @(posedge clk);
                if (rx_valid) got_valid = 1'b1;
            end

            if (!got_valid) begin
                $display("FAIL: timeout, sent %h", data);
                errors = errors + 1;
            end else if (rx_frame_error) begin
                $display("FAIL: rx_frame_error set for valid byte %h", data);
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
        $dumpfile("uart_full_tb.vcd");
        $dumpvars(0, uart_full_tb);

        rst = 1;
        send = 0;
        tx_data = 8'b0;
        repeat (5) @(posedge clk);
        rst = 0;
        repeat (5) @(posedge clk);

        send_and_check(8'h55);
        send_and_check(8'hAA);
        send_and_check(8'h00);
        send_and_check(8'hFF);
        send_and_check(8'h3C);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);

        $finish;
    end
endmodule

