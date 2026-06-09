//////////////////////////////////////////////////////////////////////////////////
// Company: CSUN
// Engineer: Keitaro Cho
// Create Date: 04/05/2026 07:40:42 AM
// Module Name: rti_top
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module rti_top(
    input sys_clk,
    input sys_rst_n,
    input rti_en,
    input int_en,
    input int_clr,
    output rti_out
    );
    
    reg rit_pulse;
    
    // instantiating RIT_GEN
    RTI_gen #(
        .CLK_FREQ_HZ(50_000_000),
        .RTI_FREQ_HZ(8),
        .RTI_PULSE_WIDTH_MS(1)
    ) uut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .rti_en(rti_en),
        .rti_pulse(rti_pulse)
    );
    
    //instantiating int_gen
    int_gen UTT (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .int_en(int_en),
        .int_clr(int_clr),
        .rti_in(rti_pulse),
        .rti_out(rti_out)
    );
    
endmodule
