module pixels( 
    input clk,  
    input reset,    
    input up,
    input down,
    input up2,
    input down2,
    input videoOn,
    input [9:0] xCoordinate,
    input [9:0] yCoordinate,
    output reg [11:0] rgbColor
    );

// maximum x, y values in display area
parameter maximumXValue = 639;
parameter maximumYValue = 479;
wire isRefreshTick;
assign isRefreshTick = ((yCoordinate == 481) && (xCoordinate == 0)) ? 1 : 0; // start of vsync(vertical retrace)

// PADDLE 1
// paddle horizontal boundaries
parameter paddle1LeftBoundary = 600;
parameter paddle1RightBoundary = 605;    // 4 pixels wide
// paddle vertical boundary signals
wire [9:0] paddle1TopBoundary, paddle1BottomBoundary;
// register to track top boundary and buffer
reg [9:0] paddle1BoundaryRegister, paddle1NextBoundary;

// PADDLE 2
parameter paddle2LeftBoundary = 32;
parameter paddle2RightBoundary = 37;    // 4 pixels wide
wire [9:0] paddle2TopBoundary, paddle2BottomBoundary;
// register to track top boundary and buffer
reg [9:0] paddle2BoundaryRegister, paddle2NextBoundary;




parameter paddleMovementVelocity = 3;    
parameter paddleHeightValue = 72;  // 72 pixels high

// BALL
// square rom boundaries
parameter ballSizeValue = 9;
// ball horizontal boundary signals
wire [9:0] ballLeftBoundary, ballRightBoundary;
// ball vertical boundary signals
wire [9:0] ballTopBoundary, ballBottomBoundary;
// register to track top left position
reg [9:0] ballYPositionRegister, ballXPositionRegister;
// signals for register buffer
wire [9:0] ballYNextPosition, ballXNextPosition;
// registers to track ball speed and buffers
reg [9:0] ballXDeltaRegister, ballXDeltaNext;
reg [9:0] ballYDeltaRegister, ballYDeltaNext;
// positive or negative ball velocity
parameter ballPositiveVelocity = 1;
parameter ballNegativeVelocity = -1;

wire [2:0] romAddress, romColumn;   // 3-bit rom address and rom column
reg [7:0] romDataValue;             // data at current rom address
wire romBitValue;                   // s1 or 0 for ball rgb control

// Register Control
always @(posedge clk or posedge reset)
    if(reset) begin
        paddle1BoundaryRegister <= 0;
        paddle2BoundaryRegister <= 0;
        ballXPositionRegister <= 0;
        ballYPositionRegister <= 0;
        ballXDeltaRegister <= 10'h002;
        ballYDeltaRegister <= 10'h002;
    end
    else begin
        paddle1BoundaryRegister <= paddle1NextBoundary;
        paddle2BoundaryRegister <= paddle2NextBoundary;
        ballXPositionRegister <= ballXNextPosition;
        ballYPositionRegister <= ballYNextPosition;
        ballXDeltaRegister <= ballXDeltaNext;
        ballYDeltaRegister <= ballYDeltaNext;
    end
// ball rom
always @*
    case(romAddress)
        3'b000 :    romDataValue = 8'b00010000;
        3'b001 :    romDataValue = 8'b00111100; 
        3'b010 :    romDataValue = 8'b01111110; 
        3'b011 :    romDataValue = 8'b11111111;  
        3'b100 :    romDataValue = 8'b11111111;  
        3'b101 :    romDataValue = 8'b01111110; 
        3'b110 :    romDataValue = 8'b00111100;  
        3'b111 :    romDataValue = 8'b00010000;  
    endcase

// OBJECT STATUS SIGNALS
wire paddle1IsOn, squareBallIsOn, ballIsOn, paddle2IsOn;
wire [11:0] paddle1RgbColor, ballRgbColor, backgroundRgbColor, isPongTextColor;

assign paddle1RgbColor = 12'h000;      // black paddle
assign ballRgbColor = 12'hF00;         // red ball
assign backgroundRgbColor = 12'hFFF;   // white background

// paddle 
assign paddle1TopBoundary = paddle1BoundaryRegister;                             // paddle top position
assign paddle1BottomBoundary = paddle1TopBoundary + paddleHeightValue - 1;      // paddle bottom position
assign paddle1IsOn = (paddle1LeftBoundary <= xCoordinate) && (xCoordinate <= paddle1RightBoundary) &&     // pixel within paddle boundaries
                      (paddle1TopBoundary <= yCoordinate) && (yCoordinate <= paddle1BottomBoundary);

// paddle2
assign paddle2TopBoundary = paddle2BoundaryRegister;                             // paddle top position
assign paddle2BottomBoundary = paddle2TopBoundary + paddleHeightValue - 1;      // paddle bottom position
assign paddle2IsOn = (paddle2LeftBoundary <= xCoordinate) && (xCoordinate <= paddle2RightBoundary) &&     // pixel within paddle boundaries
                      (paddle2TopBoundary <= yCoordinate) && (yCoordinate <= paddle2BottomBoundary);

// Paddle Control
always @* begin
    paddle1NextBoundary = paddle1BoundaryRegister;     // no move
    if(isRefreshTick)
        if(up & (paddle1TopBoundary > paddleMovementVelocity))
            paddle1NextBoundary = paddle1BoundaryRegister - paddleMovementVelocity;  // move up
        else if(down & (paddle1BottomBoundary < (maximumYValue - paddleMovementVelocity)))
            paddle1NextBoundary = paddle1BoundaryRegister + paddleMovementVelocity;  // move down
end

// Paddle Control2
always @* begin
    paddle2NextBoundary = paddle2BoundaryRegister;     // no move
    if(isRefreshTick)
        if(up2 & (paddle2TopBoundary > paddleMovementVelocity))
            paddle2NextBoundary = paddle2BoundaryRegister - paddleMovementVelocity;  // move up
        else if(down2 & (paddle2BottomBoundary < (maximumYValue - paddleMovementVelocity)))
            paddle2NextBoundary = paddle2BoundaryRegister + paddleMovementVelocity;  // move down
end

// rom data square boundaries
assign ballLeftBoundary = ballXPositionRegister;
assign ballTopBoundary = ballYPositionRegister;
assign ballRightBoundary = ballLeftBoundary + ballSizeValue - 1;
assign ballBottomBoundary = ballTopBoundary + ballSizeValue - 1;

// pixel within rom square boundaries
assign squareBallIsOn = (ballLeftBoundary <= xCoordinate) && (xCoordinate <= ballRightBoundary) &&
                        (ballTopBoundary <= yCoordinate) && (yCoordinate <= ballBottomBoundary);

// map current pixel location to rom addr/col
assign romAddress = yCoordinate[2:0] - ballTopBoundary[2:0];   // 3-bit address
assign romColumn = xCoordinate[2:0] - ballLeftBoundary[2:0];    // 3-bit column index
assign romBitValue = romDataValue[romColumn];         // 1-bit signal rom data by column

// pixel within round ball
assign ballIsOn = squareBallIsOn & romBitValue;      // within square boundaries AND rom data bit == 1

// new ball position
assign ballXNextPosition = (isRefreshTick) ? ballXPositionRegister + ballXDeltaRegister : ballXPositionRegister;
assign ballYNextPosition = (isRefreshTick) ? ballYPositionRegister + ballYDeltaRegister
: ballYPositionRegister;

// change ball direction after collision
always @* begin
    ballXDeltaNext = ballXDeltaRegister;
    ballYDeltaNext = ballYDeltaRegister;
    
    if(ballTopBoundary < 1)                                            // collide with top
        ballYDeltaNext = ballPositiveVelocity;                       // move down
    else if(ballBottomBoundary > maximumYValue)                      // collide with bottom
        ballYDeltaNext = ballNegativeVelocity;                       // move up
    else if((paddle1LeftBoundary <= ballRightBoundary) && (ballRightBoundary <= paddle1RightBoundary) &&
            (paddle1TopBoundary <= ballBottomBoundary) && (ballTopBoundary <= paddle1BottomBoundary))     // collide with paddle 1
        ballXDeltaNext = ballNegativeVelocity;                       // move left
    else if((paddle2LeftBoundary <= ballRightBoundary) && (ballRightBoundary <= paddle2RightBoundary) &&
            (paddle2TopBoundary <= ballBottomBoundary) && (ballTopBoundary <= paddle2BottomBoundary))     // collide with paddle 2
        ballXDeltaNext = ballPositiveVelocity;                       // move right
end
// PONG TEXT
parameter pongTextXStart = 220;  
parameter pongTextXEnd = 418;  
parameter pongTextYStart = 200;
parameter pongTextYEnd = 298;  

// 5x5 font
reg [4:0] pongTextBitmap [0:19]; 
initial begin
    pongTextBitmap[0]  = 5'b11110; 
    pongTextBitmap[1]  = 5'b10010; 
    pongTextBitmap[2]  = 5'b11110; 
    pongTextBitmap[3]  = 5'b10000; 
    pongTextBitmap[4]  = 5'b10000; 
    pongTextBitmap[5]  = 5'b01110; 
    pongTextBitmap[6]  = 5'b10001; 
    pongTextBitmap[7]  = 5'b10001; 
    pongTextBitmap[8]  = 5'b10001; 
    pongTextBitmap[9]  = 5'b01110; 
end


wire isPongTextOn;
wire [3:0] currentLetterRowIndex = (yCoordinate - pongTextYStart) / 20; // Map Y position to letter row
wire [3:0] currentLetterColumnIndex = (xCoordinate - pongTextXStart) / 20; // Map X position to letter column
wire [4:0] currentLetterRowData = pongTextBitmap[currentLetterRowIndex + (currentLetterColumnIndex / 5) * 5];
assign isPongTextOn = (pongTextXStart <= xCoordinate) && (xCoordinate <= pongTextXEnd) &&
                      (pongTextYStart <= yCoordinate) && (yCoordinate <= pongTextYEnd) &&
                      currentLetterRowData[4 - (currentLetterColumnIndex % 5)];

// rgb multiplexing circuit
always @*
    if (~videoOn)
        rgbColor = 12'h000;      // blank
    else if (isPongTextOn)
        rgbColor = 12'h000;      // black
    else if (paddle1IsOn)
        rgbColor = paddle1RgbColor;       // paddle color
    else if (ballIsOn)
        rgbColor = ballRgbColor;      // ball color
    else if (paddle2IsOn)
        rgbColor = paddle1RgbColor;       // paddle 2 color
    else
        rgbColor = backgroundRgbColor;        // background

endmodule
