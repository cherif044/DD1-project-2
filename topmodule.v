`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module topmodule(
    input clk_100MHz,     
    input reset,          
    input [2:0] sw,        
    output hsync,          
    output vsync,         
    output [3:0] vga_red,  
    output [3:0] vga_green,
    output [3:0] vga_blue 
);

    wire video_on;
    wire p_tick;
    wire [9:0] x, y;

    vga_sync vga_sync_inst (
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .video_on(video_on),
        .hsync(hsync),
        .vsync(vsync),
        .p_tick(p_tick),
        .x(x),
        .y(y)
    );


    pixels pixels_inst (
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .sw(sw),
        .video_on(video_on),
        .red(vga_red),
        .green(vga_green),
        .blue(vga_blue)
    );

endmodule

