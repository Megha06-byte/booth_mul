`timescale 1ns/1ps

module tb;

parameter WIDTH = 8;

reg clk;
reg rst;
reg start;

reg  signed [WIDTH-1:0] ip_A;
reg  signed [WIDTH-1:0] ip_B;

wire signed [2*WIDTH-1:0] product;
wire done;

//--------------------------------------------------
// DUT
//--------------------------------------------------

seq_multiplier #(
    .WIDTH(WIDTH)
) dut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .ip_A(ip_A),
    .ip_B(ip_B),
    .product(product),
    .done(done)
);

//--------------------------------------------------
// Clock
//--------------------------------------------------

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

//--------------------------------------------------
// Statistics
//--------------------------------------------------

integer pass_count = 0;
integer fail_count = 0;

reg signed [2*WIDTH-1:0] expected;

//--------------------------------------------------
// Test Task
//--------------------------------------------------

task run_test;

    input signed [WIDTH-1:0] a;
    input signed [WIDTH-1:0] b;

    begin

        expected = a * b;

        @(posedge clk);
        ip_A  <= a;
        ip_B  <= b;
        start <= 1'b1;

        @(posedge clk);
        start <= 1'b0;

        wait(done);

        @(posedge clk);

        $display("------------------------------------------------------------");
        $display("A = %4d   B = %4d", a, b);
        $display("Expected = %6d", expected);
        $display("Obtained = %6d", product);

        if(product === expected) begin
            pass_count = pass_count + 1;
            $display("STATUS : PASS");
        end
        else begin
            fail_count = fail_count + 1;
            $display("STATUS : FAIL");
        end

    end

endtask

//--------------------------------------------------
// Test Sequence
//--------------------------------------------------

initial begin

    rst   = 1'b1;
    start = 1'b0;
    ip_A  = '0;
    ip_B  = '0;

    repeat(2) @(posedge clk);

    rst = 1'b0;

    // Basic functionality
    run_test(10, 5);
    run_test(7, 3);
    run_test(25, 4);

    // Zero cases
    run_test(0, 25);
    run_test(25, 0);
    run_test(0, 0);

    // Positive × Negative
    run_test(12, -5);
    run_test(-8, 7);

    // Negative × Negative
    run_test(-10, -9);
    run_test(-5, -1);

    // Boundary values
    run_test(127, 1);
    run_test(-128, 1);
    run_test(127, -1);
    run_test(-128, -1);

    // Extreme products
    run_test(127, 127);
    run_test(-128, -128);
    run_test(-128, 127);
    run_test(127, -128);

    //--------------------------------------------------

    $display("\n============================================================");
    $display("Simulation Summary");
    $display("------------------------------------------------------------");
    $display("Tests Passed : %0d", pass_count);
    $display("Tests Failed : %0d", fail_count);

    if(fail_count == 0)
        $display("RESULT : ALL TESTS PASSED");
    else
        $display("RESULT : TEST FAILED");

    $display("============================================================");

    #20;
    $finish;

end

//--------------------------------------------------
// Uncomment for debugging
//--------------------------------------------------
/*
initial begin
    $display("time state A M Q Q_1 count product done");

    $monitor("%4t %2d %4h %4h %4h %b %2d %6h %b",
        $time,
        dut.state,
        dut.A,
        dut.M,
        dut.Q,
        dut.Q_1,
        dut.counter,
        product,
        done);
end
*/

//--------------------------------------------------
// Waveforms
//--------------------------------------------------

initial begin
    $dumpfile("booth_multiplier.vcd");
    $dumpvars(0, tb);
end

endmodule


