//////////////////////////////////////////////////////////////////////////////////
// Company: CSUN
// Engineer: Keitaro Cho
// Create Date: 04/5/2026 07:24:29 AM
// Module Name: int_gen
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module int_gen(sys_clk,sys_rst_n,int_en,int_clr,rti_in,rti_out);
    
    input sys_clk;
    input sys_rst_n;
    input int_en;
    input int_clr;
    input rti_in;
    output reg rti_out;

    reg sig_in_d1;
    reg sig_in_d2;
    
    always @(posedge sys_clk) begin
        if (!sys_rst_n) begin
            rti_out  <= 1'b0;
        end else begin
            sig_in_d1 <=rti_in;
            sig_in_d2 <= sig_in_d1;
            if (!int_en)
                rti_out <= 1'b0;
            else if (int_clr)
                rti_out <= 1'b0;
            else if (sig_in_d1 && !sig_in_d2)
                rti_out <= 1'b1;
        end
    end
    
endmodule
