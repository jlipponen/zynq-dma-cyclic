`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Wapice Ltd
// Engineer: Jan Lipponen
// 
// Create Date: 04/06/2018 11:38:14 AM
// Design Name: 
// Module Name: sample_generator
// Project Name: ZYNQ DMA Cyclic
// Target Devices: Zynq-7000
// Tool Versions: 
// Description: Generates sample data to AXIS
// 
// Dependencies: 
// 
// Revision:
// Revision 1.0 - Operational
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module sample_generator#(
        parameter integer C_M_AXIS_DATA_WIDTH = 32
    )(
        // Global        
        input wire                                      ACLK,
        input wire                                      ARESETN,
        // Core input
        input wire [C_M_AXIS_DATA_WIDTH-1:0]            tlast_throttle,
        input wire [C_M_AXIS_DATA_WIDTH-1:0]            clk_divider,
        input wire                                      enable,
        input wire                                      insert_error,          
        // Master stream channel
        output reg  [C_M_AXIS_DATA_WIDTH-1:0]           M_AXIS_TDATA,
        output reg  [(C_M_AXIS_DATA_WIDTH/8)-1:0]       M_AXIS_TKEEP,
        output reg                                      M_AXIS_TLAST,
        input  wire                                     M_AXIS_TREADY,
        output reg                                      M_AXIS_TVALID
    );
    
    wire                            sample_clk;
    
    sample_clk_gen #(
        .C_M_AXIS_DATA_WIDTH(C_M_AXIS_DATA_WIDTH)
    ) sample_clk_gen_inst (
        // Global
        .ACLK(ACLK),
        .ARESETN(ARESETN),
        // Input
        .clk_divider(clk_divider),
        // Registered output
        .sample_clk(sample_clk)
    );
    
    wire [C_M_AXIS_DATA_WIDTH-1:0]  sample_data;
    wire                            data_valid;
    
    count_data_gen #(
        .C_M_AXIS_DATA_WIDTH(C_M_AXIS_DATA_WIDTH)
    ) count_data_gen_inst (
        // Global
        .ACLK(ACLK),
        .ARESETN(ARESETN),
        // Input
        .sample_clk(sample_clk),
        .enable(enable),
        // Output
        .sample_data(sample_data),
        .data_valid(data_valid)
    );
    
    reg                             insert_error_r = 1'b0;
    reg                             insert_error_ack_r = 1'b0;
 
    // Error insertion process
    always @(posedge ACLK) begin
         // Synchronous reset
        if(~ARESETN) begin
           insert_error_r <= 1'b0;
        end
        else begin
            if(insert_error && ~insert_error_ack_r) begin
                insert_error_r <= 1'b1;
            end
            else if(~insert_error && insert_error_ack_r) begin
                insert_error_r <= 1'b0;
            end
            else begin
                insert_error_r <= insert_error_r;
            end
        end
    end
   
    initial M_AXIS_TKEEP = 4'b1111;
    reg [C_M_AXIS_DATA_WIDTH-1:0]   databeat_counter_r = 'd0;
    
    // The AXIS interface implementation
    always @(posedge ACLK) begin
        // Synchronous reset
        if(~ARESETN) begin
            M_AXIS_TDATA <= 'd0;
            M_AXIS_TVALID <= 1'b0;
            M_AXIS_TLAST <= 1'b0;
            insert_error_ack_r <= 1'b0;
        end
        else begin
            // Allow M_AXIS_TVALID only for one ACLK clock cycle
            // when the receiver is ready
            if(M_AXIS_TREADY && M_AXIS_TVALID) begin
               M_AXIS_TVALID <= 1'b0;
            end
            // Allow M_AXIS_TLAST only for one ACLK clock cycle
            // when the receiver is ready
            if(M_AXIS_TREADY && M_AXIS_TLAST) begin
               M_AXIS_TLAST <= 1'b0;
            end
            
            if(data_valid) begin
                if(insert_error_r && ~insert_error_ack_r) begin
                    M_AXIS_TDATA <= sample_data - 'd2;
                    insert_error_ack_r <= 1'b1;
                end
                else if(~insert_error_r && insert_error_ack_r) begin
                    insert_error_ack_r <= 1'b0;
                    M_AXIS_TDATA <= sample_data;
                end
                else begin
                    M_AXIS_TDATA <= sample_data;
                end
                
                M_AXIS_TVALID <= 1'b1;
                
                // Throttle the TLAST signal
                if(databeat_counter_r < (tlast_throttle - 'd1)) begin
                    databeat_counter_r <= databeat_counter_r + 'd1;
                end else begin
                    databeat_counter_r <= 'd0;
                    M_AXIS_TLAST <= 1'b1;
                end       
            end
        end
    end
endmodule
