//////////////////////////////////////////////////////////////////////////////////
// Company: CSUN
// Engineer: Keitaro Cho
// Create Date: 04/04/2026 11:22:16 PM
// Module Name: tb_RTI_gen
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module RTI_gen_tb;

    // Testbench signals
    reg sys_clk;
    reg sys_rst_n;
    reg rti_en;
    wire rti_pulse;

    // Instantiate DUT (Device Under Test)
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

    // ? Clock generation (50 MHz ? period = 20 ns)
    always #10 sys_clk = ~sys_clk;

    initial begin
        // Initialize signals
        sys_clk   = 0;
        sys_rst_n = 0;
        rti_en    = 0;

        // Apply reset
        #100;
        sys_rst_n = 1;

        // Enable RTI
        #100;
        rti_en = 1;

        // Run simulation long enough to see a few pulses
        // 8 Hz ? period = 125 ms ? simulate ~500 ms
        #500_000_000;
        
        // Disable RTI
        rti_en = 0;

        #1000;
        $stop;
    end

endmodule