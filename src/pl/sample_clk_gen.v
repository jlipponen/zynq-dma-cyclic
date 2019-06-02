`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Wapice Ltd
// Engineer: Jan Lipponen
// 
// Create Date: 04/06/2018 11:46:43 AM
// Design Name: 
// Module Name: sample_clk_gen
// Project Name: ZYNQ DMA Cyclic
// Target Devices: Zynq-7000
// Tool Versions: 
// Description: Generates divisible sample clock signal
// 
// Dependencies: 
// 
// Revision:
// Revision 1.0 - Operational
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module sample_clk_gen#(
        parameter integer C_M_AXIS_DATA_WIDTH = 32
    )(
        // Global  
        input wire                              ACLK,
        input wire                              ARESETN,
        // Input
        input wire [C_M_AXIS_DATA_WIDTH-1:0]    clk_divider,               
        // Registered output
        output reg                              sample_clk = 1'b0
    );
    
    reg [C_M_AXIS_DATA_WIDTH-1:0] counter_r = 'd0;
    
    always @(posedge ACLK) begin
        // Synchronous reset
        if(~ARESETN) begin
            sample_clk <= 1'b0;
        end
        else begin
            // The clk divider needs to be at least 2   
            // for the sample clock generation
            if(clk_divider > 1) begin
                // Count the ACLK positive clock edges
                if(counter_r < (clk_divider - 'd2)) begin
                    counter_r <= counter_r + 'd1;
                end
                // Toggle the sample clock state
                else begin
                    counter_r <= 'd0;
                    if(sample_clk == 1'b0) begin
                        sample_clk <= 1'b1;
                    end
                    else begin
                        sample_clk <= 1'b0;
                    end
                end
            end
        end
    end
endmodule
