`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/20 10:50:03
// Design Name: 
// Module Name: Unused
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module timer(
    input clk, reset,
    input [3:0] btn,
    output [6:0] seg, [3:0] an,
    output reg alert
    );
    
    wire btn_mode_nedge, btn_min_pedge, btn_sec_pedge, btn_off_pedge;
    short_button_nedge mode_switch_button_edge(
        .clk(clk), .reset(reset), .btn(btn[0]), .btn_nedge(btn_mode_nedge)
    );
    long_short_button_pedge inc_min_button_edge(
        .clk(clk), .reset(reset), .btn(btn[1]), .btn_pedge(btn_min_pedge)
    );
    long_short_button_pedge inc_sec_button_edge(
        .clk(clk), .reset(reset), .btn(btn[2]), .btn_pedge(btn_sec_pedge)
    );
    short_button_nedge alert_off_button_edge(
        .clk(clk), .reset(reset), .btn(btn[3]), .btn_nedge(btn_off_nedge)
    );
    reg mode;
    parameter SET = 0;
    parameter TIMER = 1;
    
    wire clk_sec, clk_min;
    clock_divider #(100_000_000) second(
        .clk(clk), .reset(reset), .clk_div(clk_sec)
    );
    source_divider #(60) minute(
        .clk(clk), .reset(reset), .source(inc_sec), .clk_div(clk_min)
    );
    
    assign dec_min = (mode == TIMER)? clk_min : 0;
    assign dec_sec = (mode == TIMER)? clk_sec : 0;
    assign inc_min = (mode == SET)? btn_min_pedge : 0;
    assign inc_sec = (mode == SET)? btn_sec_pedge : 0;
    wire [2:0] min10, sec10;
    wire [3:0] min1, sec1;
    bcd_up_down_counter decimal_min(
        .clk(clk), .reset(reset), .source_down(dec_min), .source_up(inc_min), .bcd10(min10), .bcd1(min1)
    );
    bcd_up_down_counter decimal_sec(
        .clk(clk), .reset(reset), .source_down(dec_sec), .source_up(inc_sec), .bcd10(sec10), .bcd1(sec1)
    );
    
    wire [15:0] value;
    assign value = {1'b0, min10, min1, 1'b0, sec10, sec1};
    fnd_controller fnd_print(
        clk, reset, value, seg, an
    );
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            alert = 0;
            mode = 0;
        end
        else begin
            if(btn_mode_nedge)
                mode = ~mode;
            else if(mode == TIMER && value == 16'h0000) begin
                mode = SET;
                alert = 1;
            end
            else if(btn_off_nedge)
                alert = 0;
        end
    end
    
endmodule

module bcd_up_down_counter(
    input clk, reset, source_up, source_down,
    output reg [3:0] bcd10, bcd1
    );
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            bcd10 = 0;
            bcd1 = 0;
        end
        else if(source_down) begin
            if(bcd1 > 0) begin
                bcd1 = bcd1 - 1;
            end
            else begin
                if(bcd10 > 0) begin
                    bcd1 = 9;
                    bcd10 = bcd10 - 1;
                end
            end
        end
        else if(source_up) begin
            if(bcd1 < 9) begin
                bcd1 = bcd1 + 1;
            end
            else begin
                bcd1 = 0;
                if(bcd10 < 5) begin
                    bcd10 = bcd10 + 1;
                end
                else begin
                    bcd10 = 0;
                end
            end
        end
    end
    
endmodule

module bcd_counter(
    input clk, reset, source,
    output reg [3:0] bcd10, bcd1
    );
    
    parameter ONES_MAX = 9;
    parameter TENS_MAX = 5;
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            bcd10 = 0;
            bcd1 = 0;
        end
        else if(source) begin
            if(bcd1 < ONES_MAX) begin
                bcd1 = bcd1 + 1;
            end
            else begin
                bcd1 = 0;
                if(bcd10 < TENS_MAX) begin
                    bcd10 = bcd10 + 1;
                end
                else begin
                    bcd10 = 0;
                end
            end
        end
    end
    
endmodule