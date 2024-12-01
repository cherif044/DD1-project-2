`timescale 1ns / 1ps

module topmodule(
    input clk100MHz,        // from Basys 3
    input reset,            // btnR
    input up,               // btnU
    input down,
    input up2,
    input down2,             // btnD
    output hsync,           // to VGA port
    output vsync,           // to VGA port
    output [11:0] rgb     // to DAC, to VGA port
//    output [6:0] 
    );
    
    wire wReset, wUp, wDown, wVidOn, wPTick,wUp2,wDown2;
    wire [9:0] wX, wY;
    reg [11:0] rgbReg;
    wire [11:0] rgbNext;
    
    vga_sync vga(.clk100MHz(clk100MHz), .reset(wReset), .videoOn(wVidOn),
                      .hsync(hsync), .vsync(vsync), .pTick(wPTick), .x(wX), .y(wY));
    pixels pg(.clk(clk100MHz), .reset(wReset), .up(wUp), .down(wDown), 
                 .videoOn(wVidOn), .xCoordinate(wX), .yCoordinate(wY), . rgbColor(rgbNext),
                 .up2(wUp2), .down2(wDown2));
                 
    debouncer dbR(.clk(clk100MHz), .in(reset), .out(wReset));
    debouncer dbU(.clk(clk100MHz), .in(up), .out(wUp));
    debouncer dbD(.clk(clk100MHz), .in(down), .out(wDown));
    debouncer dbU2(.clk(clk100MHz), .in(up2), .out(wUp2));
    debouncer dbD2(.clk(clk100MHz), .in(down2), .out(wDown2));
    
    // rgb buffer
    always @(posedge clk100MHz)
        if(wPTick)
            rgbReg <= rgbNext;
            
    assign rgb = rgbReg;
    
endmodule
