//////////////////////////////////////////////////////////////////////////////////
// Company: CSUN
// Engineer: Keitaro Cho
// Create Date: 04/04/2026 10:25:12 PM
// Module Name: RTI_gen
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module RTI_gen #(
    parameter integer CLK_FREQ_HZ = 50_000_000,
    parameter integer RTI_FREQ_HZ = 8,
    parameter integer RTI_PULSE_WIDTH_MS = 1
    )(
    input sys_clk,
    input sys_rst_n,
    input rti_en,
    output reg rti_pulse
    );
    
    // This creates how many clock of 50MHz is needed to make 8Hz Freq
    localparam integer PERIOD_COUNT = CLK_FREQ_HZ/RTI_FREQ_HZ; 
    // This creates how many clock of 50MHz is needed to make 1ms pulse
    localparam integer PULSE_COUNT = (CLK_FREQ_HZ/1000)*RTI_PULSE_WIDTH_MS;
    
    reg [31:0] counter;
    
    always @(posedge sys_clk) begin
        if (!sys_rst_n) begin
            rti_pulse  <= 1'b0;
            counter <= 0;
        end else if (!rti_en) begin
            rti_pulse <= 1'b0;
            counter <= 0;
        end else begin
            // incrementing the counter
            if (counter >= PERIOD_COUNT - 1)
                counter <= 0;
            else
                counter <= counter + 1;
            // generating RTI pulse
            if (counter < PULSE_COUNT)
                rti_pulse <= 1'b1;
            else
                rti_pulse <= 1'b0;
        end
    end
   
endmodule
