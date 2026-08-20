`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/02/2026 10:02:11 PM
// Design Name: 
// Module Name: clk_divider_tb
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


module clk_divider_tb;
    reg clk = 0;
    reg rst = 1;
    wire tick;
    reg sync_reset = 0;
    
    clk_divider DUT (
        .clk(clk),
        .rst(rst),
        .sync_reset(sync_reset),
        .tick(tick)
        );
        
    always #5 clk = ~clk;
        
    initial begin
        repeat(5) @(posedge clk);  // wait 5 cycles with reset high
        rst = 0;                    // release reset
        repeat(3000) @(posedge clk);
        sync_reset = 1;
        @(posedge clk);      // hold sync_reset high through exactly one clean edge
        sync_reset = 0;
        repeat(250000) @(posedge clk);  // wait long enough to see ~24 ticks
    
        $display("Simulation complete");
        $finish;
    end
endmodule


/* module alu_tb;

    reg  [7:0] a, b;
    reg  [2:0] opcode;
    wire [7:0] result;
    wire carry;
    wire zero;
    wire negative;

    alu DUT (
        .a(a),
        .b(b),
        .opcode(opcode),
        .result(result),
        .carry(carry),
        .zero(zero),
        .negative(negative)
    );

    initial begin
        // ADD
        a = 8'd10; b = 8'd3; opcode = 3'b000; #10;
        $display("ADD: %0d + %0d = %0d (expect 13)", a, b, result);

        // SUB
        a = 8'd10; b = 8'd3; opcode = 3'b001; #10;
        $display("SUB: %0d - %0d = %0d (expect 7)", a, b, result);

        // AND: 0xAA & 0x0F = 0x0A
        a = 8'hAA; b = 8'h0F; opcode = 3'b010; #10;
        $display("AND: %0h & %0h = %0h (expect 0a)", a, b, result);

        // OR: 0xAA | 0x0F = 0xAF
        a = 8'hAA; b = 8'h0F; opcode = 3'b011; #10;
        $display("OR: %0h | %0h = %0h (expect af)", a, b, result);

        // XOR: 0xAA ^ 0x0F = 0xA5
        a = 8'hAA; b = 8'h0F; opcode = 3'b100; #10;
        $display("XOR: %0h ^ %0h = %0h (expect a5)", a, b, result);

        // NOT: ~0x0A = 0xF5
        a = 8'h0A; opcode = 3'b101; #10;
        $display("NOT: ~%0h = %0h (expect f5)", a, result);

        // SHL: 10 << 1 = 20
        a = 8'd10; opcode = 3'b110; #10;
        $display("SHL: %0d << 1 = %0d (expect 20)", a, result);

        // SHR: 10 >> 1 = 5
        a = 8'd10; opcode = 3'b111; #10;
        $display("SHR: %0d >> 1 = %0d (expect 5)", a, result);

        // Overflow: 255 + 1 = 0 (carry lost)
        a = 8'hFF; b = 8'h01; opcode = 3'b000; #10;
        $display("OVERFLOW: %0h + %0h = %0h (expect 00)", a, b, result);

        // Zero: 5 - 5 = 0
        a = 8'd5; b = 8'd5; opcode = 3'b001; #10;
        $display("ZERO: %0d - %0d = %0d (expect 0)", a, b, result);
        
        // Carry flag: 255 + 1 should set carry
        a = 8'd255; b = 8'd1; opcode = 3'b000; #10;
        $display("CARRY: %b (expect 1)", carry);
        
        // Zero flag: 5 - 5 should set zero
        a = 8'd5; b = 8'd5; opcode = 3'b001; #10;
        $display("ZERO FLAG: %b (expect 1)", zero);
        
        // Negative flag: NOT 10 = 11110101, bit[7]=1
        a = 8'd10; opcode = 3'b101; #10;
        $display("NEGATIVE: %b (expect 1)", negative);

        $display("All tests complete");
        $finish;
    end

endmodule
*/