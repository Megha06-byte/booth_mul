`timescale 1ns/1ps

module tb_seq;

parameter WIDTH = 8;

reg clk;
reg rst;
reg start;

reg signed [WIDTH-1:0] ip_A;
reg signed [WIDTH-1:0] ip_B;

wire signed [2*WIDTH-1:0] product;
wire done;

//--------------------------------------------------
// DUT
//--------------------------------------------------

booth_multiplier_seq #(
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

integer add_ops = 0;
integer sub_ops = 0;
integer total_mults = 0;

reg signed [2*WIDTH-1:0] expected;

//--------------------------------------------------
// Count arithmetic operations
//--------------------------------------------------

always @(posedge clk) begin
    if(!rst) begin

        if(dut.add_en)
            add_ops <= add_ops + 1;

        if(dut.sub_en)
            sub_ops <= sub_ops + 1;

        if(done)
            total_mults <= total_mults + 1;

    end
end

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

        if(product === expected)
            pass_count = pass_count + 1;
        else begin
            fail_count = fail_count + 1;

            $display("----------------------------------------");
            $display("FAILED");
            $display("A        = %0d", a);
            $display("B        = %0d", b);
            $display("Expected = %0d", expected);
            $display("Obtained = %0d", product);
        end

    end

endtask

//--------------------------------------------------
// Test Sequence
//--------------------------------------------------

initial begin

    rst   = 1;
    start = 0;
    ip_A  = 0;
    ip_B  = 0;

    repeat(2) @(posedge clk);
    rst = 0;

    //==================================================
    // Directed Benchmark
    //==================================================

    // Dataset 1 : Multiplicand = 0x55
    run_test(8'h55, 8'b11111111);
    run_test(8'h55, 8'b11111110);
    run_test(8'h55, 8'b11111100);
    run_test(8'h55, 8'b11111000);
    run_test(8'h55, 8'b11110000);
    run_test(8'h55, 8'b01111111);
    run_test(8'h55, 8'b00111111);
    run_test(8'h55, 8'b00011111);
    run_test(8'h55, 8'b00001111);
    run_test(8'h55, 8'b00000111);

    // Dataset 2 : Multiplicand = 0xD3
    run_test(8'hD3, 8'b11111111);
    run_test(8'hD3, 8'b11111110);
    run_test(8'hD3, 8'b11111100);
    run_test(8'hD3, 8'b11111000);
    run_test(8'hD3, 8'b11110000);
    run_test(8'hD3, 8'b01111111);
    run_test(8'hD3, 8'b00111111);
    run_test(8'hD3, 8'b00011111);
    run_test(8'hD3, 8'b00001111);
    run_test(8'hD3, 8'b00000111);

    @(posedge clk);

    //==================================================
    // Summary
    //==================================================

    $display("\n==========================================");
    $display("Directed Benchmark Summary");
    $display("------------------------------------------");
    $display("Tests Passed              : %0d", pass_count);
    $display("Tests Failed              : %0d", fail_count);
    $display("Total ADD Operations      : %0d", add_ops);
    $display("Total SUB Operations      : %0d", sub_ops);
    $display("Total Arithmetic Ops      : %0d", add_ops + sub_ops);
    $display("Total Multiplications     : %0d", total_mults);

    if(total_mults != 0) begin
        $display("Average ADDs/Multiply     : %.2f",
                add_ops*1.0/total_mults);

        $display("Average SUBs/Multiply     : %.2f",
                sub_ops*1.0/total_mults);

        $display("Average Ops/Multiply      : %.2f",
                (add_ops+sub_ops)*1.0/total_mults);
    end

    $display("==========================================");

    #20;
    $finish;

end

//--------------------------------------------------
// Waveforms
//--------------------------------------------------

initial begin
    $dumpfile("seq_multiplier.vcd");
    $dumpvars(0, tb_seq);
end

endmodule


