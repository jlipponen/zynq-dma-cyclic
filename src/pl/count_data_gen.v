`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Wapice Ltd
// Engineer: Jan Lipponen
// 
// Create Date: 04/06/2018 12:37:00 PM
// Design Name: 
// Module Name: count_data_gen
// Project Name: ZYNQ DMA Cyclic
// Target Devices: Zynq-7000
// Tool Versions: 
// Description: Generates counter data
// 
// Dependencies: 
// 
// Revision:
// Revision 1.0 - Operational
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module count_data_gen#(
        parameter integer C_M_AXIS_DATA_WIDTH = 32
    )(
        // Global  
        input wire                              ACLK,
        input wire                              ARESETN,
        // Input
        input wire                              sample_clk,
        input wire                              enable,               
        // Registered output
        output reg [C_M_AXIS_DATA_WIDTH-1:0]    sample_data = 'd0,
        output reg                              data_valid = 1'b0
    );
    
    reg trigger_sample_write = 1'b1;
    
always @(posedge ACLK) begin
    // Synchronous reset
    if(~ARESETN) begin
        sample_data <= 'd0;
        data_valid <= 1'b0;
        trigger_sample_write <= 1'b1; 
    end
    else begin
        // Allow the data_valid only for one ACLK clock cycle
        if(data_valid) begin
            data_valid <= 1'b0;
        end
        // If sample generator is enabled
        if(enable) begin
            // If the sample clock is asserted and
            // no sample data has been written on this positive
            // sample clock cycle
            if(sample_clk && trigger_sample_write) begin
                sample_data <= sample_data + 'd1;
                data_valid <= 1'b1;
                // Wait for next positive sample clock cycle
                trigger_sample_write <= 1'b0;
            end
            else if(~sample_clk) begin
                // Trigger sample write on next positive 
                // sample clock cycle
                trigger_sample_write <= 1'b1;
            end
        end
    end
end
endmodule
