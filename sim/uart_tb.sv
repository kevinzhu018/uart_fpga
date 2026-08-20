interface uart_if(input logic clk);
    logic rst;
    logic send;
    logic [7:0] tx_data;
    logic tx;
    logic tx_busy;
    logic rx;
    logic [7:0] rx_data;
    logic rx_valid;
    logic rx_frame_error;

    modport TB (
        input clk, tx, tx_busy, rx_data, rx_valid, rx_frame_error,
        output rst, send, tx_data, rx
    );
endinterface

class uart_transaction;
    rand bit [7:0] data;

    constraint c_data {
        data dist { 8'h00 := 1, 8'hFF := 1, 8'h55 := 1, 8'hAA := 1, [1:254] :/ 4 };
    }

    function string to_string();
        return $sformatf("data=%h", data);
    endfunction
endclass

class uart_driver;
    virtual uart_if.TB vif;

    task drive(uart_transaction t);
        while (vif.tx_busy) @(posedge vif.clk);
        vif.tx_data = t.data;
        vif.send = 1'b1;
        @(posedge vif.clk);
        vif.send = 1'b0;
    endtask
endclass

class uart_monitor;
    virtual uart_if.TB vif;
    mailbox #(uart_transaction) mon2scb;

    task run();
        forever begin
            @(posedge vif.clk);
            if (vif.rx_valid) begin
                uart_transaction t = new();
                t.data = vif.rx_data;
                mon2scb.put(t);
            end
        end
    endtask
endclass

class uart_scoreboard;
    mailbox #(uart_transaction) mon2scb;
    virtual uart_if.TB vif;
    int errors = 0;
    int checked = 0;
    localparam int CLKS_PER_BIT = 10416;
    localparam int TIMEOUT_CYCLES = 15 * CLKS_PER_BIT;

    task check(uart_transaction expected);
        uart_transaction actual;
        int timed_out;

        timed_out = 1;
        fork : race
            begin
                mon2scb.get(actual);
                timed_out = 0;
            end
            begin
                repeat (TIMEOUT_CYCLES) @(posedge vif.clk);
            end
        join_any
        disable race;

        checked++;

        if (timed_out) begin
            $display("FAIL: timeout, sent %s", expected.to_string());
            errors++;
        end
        else if (actual.data !== expected.data) begin
            $display("FAIL: expected %h, got %h", expected.data, actual.data);
            errors++;
        end
        else begin
            $display("PASS: %h", expected.data);
        end
    endtask
endclass

module uart_top_sv_tb;

    logic clk = 0;
    always #5 clk = ~clk;

    uart_if vif(clk);
    assign vif.rx = vif.tx;

    uart_top DUT (
        .clk(vif.clk),
        .rst(vif.rst),
        .send(vif.send),
        .tx_data(vif.tx_data),
        .tx(vif.tx),
        .tx_busy(vif.tx_busy),
        .rx(vif.rx),
        .rx_data(vif.rx_data),
        .rx_valid(vif.rx_valid),
        .rx_frame_error(vif.rx_frame_error)
    );

    covergroup uart_cg;
        byte_cp: coverpoint DUT.tx_data {
            bins low = {[0:63]};
            bins mid = {[64:191]};
            bins high = {[192:255]};
            bins zero = {8'h00};
            bins max = {8'hFF};
            bins alt = {8'h55, 8'hAA};
        }
    endgroup

    uart_driver driver;
    uart_monitor monitor;
    uart_scoreboard scoreboard;
    mailbox #(uart_transaction) mon2scb;
    uart_cg cg;

    initial begin
        uart_transaction t;

        vif.rst = 1'b1;
        vif.send = 1'b0;
        vif.tx_data = 8'b0;
        repeat (5) @(posedge clk);
        vif.rst = 1'b0;
        repeat (5) @(posedge clk);

        mon2scb = new();

        driver = new();
        driver.vif = vif;

        monitor = new();
        monitor.vif = vif;
        monitor.mon2scb = mon2scb;

        scoreboard = new();
        scoreboard.mon2scb = mon2scb;
        scoreboard.vif = vif;

        cg = new();

        fork
            monitor.run();
        join_none

        repeat (100) begin
            t = new();
            if (!t.randomize())
                $display("WARNING: randomize failed");
            driver.drive(t);
            scoreboard.check(t);
            cg.sample();
        end

        $display("--------------------------------------------------");
        $display("Checked: %0d  Errors: %0d", scoreboard.checked, scoreboard.errors);
        $display("Functional coverage: %0.2f%%", cg.get_coverage());
        if (scoreboard.errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", scoreboard.errors);
        $display("--------------------------------------------------");

        $finish;
    end

endmodule
