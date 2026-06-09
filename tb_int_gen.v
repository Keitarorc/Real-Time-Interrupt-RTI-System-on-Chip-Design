//////////////////////////////////////////////////////////////////////////////////
// Company: CSUN
// Engineer: Keitaro Cho
// Create Date: 04/5/2026 07:24:26 AM
// Module Name: tb_int_gen
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module tb_interrupt_generator;
    
    reg sys_clk;
    reg sys_rst_n;
    reg int_en;
    reg int_clr;
    reg rti_in;
    wire rti_out;

    int_gen UTT (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .int_en(int_en),
        .int_clr(int_clr),
        .rti_in(rti_in),
        .rti_out(rti_out)
    );

    initial begin
        sys_clk = 0;
        forever #10 sys_clk = ~sys_clk;
    end

    initial begin
        sys_rst_n = 0;
        int_en    = 0;
        int_clr   = 0;
        rti_in    = 0;

        #100;
        sys_rst_n = 1;

        #100;
        int_en = 1;

        #100
        rti_in = 1;
        #100
        rti_in = 0;
        
        #100
        int_clr = 1;
        #20
        int_clr = 0;

        #100 $finish;
    end
    
endmodule
