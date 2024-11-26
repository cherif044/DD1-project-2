`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module pixels(
    input clk_100MHz,      
    input reset,           
    input [2:0] sw,        
    input video_on,        
    output reg [3:0] red,  
    output reg [3:0] green,
    output reg [3:0] blue  
);

    always @(*) begin
        if (!video_on) begin
            red   = 4'b0000;
            green = 4'b0000;
            blue  = 4'b0000;
        end else begin
            case (sw)
                3'b000: {red, green, blue} = {4'b0000, 4'b0000, 4'b0000}; // Black
                3'b001: {red, green, blue} = {4'b1111, 4'b0000, 4'b0000}; // Red
                3'b010: {red, green, blue} = {4'b0000, 4'b1111, 4'b0000}; // Green
                3'b011: {red, green, blue} = {4'b1111, 4'b1111, 4'b0000}; // Yellow
                3'b100: {red, green, blue} = {4'b0000, 4'b0000, 4'b1111}; // Blue
                3'b101: {red, green, blue} = {4'b1111, 4'b0000, 4'b1111}; // Magenta
                3'b110: {red, green, blue} = {4'b0000, 4'b1111, 4'b1111}; // Cyan
                3'b111: {red, green, blue} = {4'b1111, 4'b1111, 4'b1111}; // White
                default: {red, green, blue} = {4'b0000, 4'b0000, 4'b0000}; // Black 
            endcase
        end
    end

endmodule

