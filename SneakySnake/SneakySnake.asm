/*
 * SneakySnake.asm
 *
 *  Created: 2014-04-25 08:52:10
 *   Author: Rasmus Wallberg, Patrik Johansson, Johan Lautakoski
 */

.DEF rZero			= r0  // This is a register where we store 0
.DEF rStaticTemp    = r4  // This is a static temporary register, we use it for the apple X position in a subroutine
.DEF rStaticTemp2   = r5  // This is a static temporary register, we use it for the apple Y position in a subroutine
.DEF rRandomNumber  = r6  // We store the "Random" number here.
.DEF rSnakeHead		= r7  // Position for the snake head
.DEF rSL			= r9  // SL = SnakeLength, current snake length
.DEF rDir			= r10 // Dir is the snakes direction
.DEF rAppelX		= r11 // X Coord for the apple
.DEF rAppelY		= r12 // Y Coord for the apple
.DEF rTimerCount	= r15 // Number of timer triggers.
.DEF rTemp			= r16 // Temporary registers
.DEF rTemp2			= r17 // Temporary registers
.DEF rTemp3			= r18 // Temporary registers
.DEF rOutputB		= r19 // What will be written to Output at port B
.DEF rOutputC		= r20 // What will be written to Output at port C
.DEF rOutputD		= r21 // What will be written to Output at port D
.DEF rMatrixTemp	= r22 // What the matrix row looks like currently in the draw loop
.DEF rInterruptTemp	= r23 // Temporary register for use in interrupt calls
.DEF rArg			= r24 // Argument for subroutines

.EQU MAX_LENGTH    = 64 // Max length of the snake
.DSEG
adress:	  .BYTE 16  // What will be written to Output at port B
matrix:   .BYTE 8
snake:    .BYTE MAX_LENGTH+1

.CSEG
// Interrupt vector table
.ORG 0x0000
	jmp init // Reset vector
// Timer interrupt origin
.ORG 0x0020
	sei // Set the Global Interrupt Flag
	jmp timerCount // Jump to function to make changed when timer interrupts
//... fler interrupts
.ORG INT_VECTORS_SIZE

init:
	// Load the Snake array pointer to Y Register
	ldi	YH, HIGH(snake)
	ldi	YL, LOW(snake)
	
	// Set the snake direction
	ldi rTemp, 0
	mov rDir, rTemp
	// Set the snake position
	ldi	rMatrixTemp, 0x10
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0x11
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0x12
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0x13
	st	Y, rMatrixTemp


	// Clear rZero to make sure its 0
	clr rZero

	// Load 4 to snake length as that is the starting length ; rSL = 4
	ldi rTemp, 4
	MOV rSL, rTemp

	// Initiate the matrix pointer
	ldi	YH, HIGH(matrix)
	ldi	YL, LOW(matrix)
	// Initiate the matrix rows
	ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b00000000
	st	Y, rMatrixTemp
	// Initiate AD-Converter
	ldi	rTemp, 0b01100000
	sts ADMUX, rTemp
	ldi rTemp, 0b10000111
	sts ADCSRA, rTemp
	// Initiate PORTB
	ldi	rTemp, 0b11111111
	out DDRB, rTemp
	// Initiate PORTC
	ldi	rTemp, 0b11001111
	out	DDRC, rTemp
	// Initiate PORTD
	ldi	rTemp, 0b11111111
	out DDRD, rTemp

	// timer initiation
	mov rTemp, rZero
	// Set the needed bits for initiating the timer
	ldi rTemp, (1<<CS02) | (1<<CS00)
	out TCCR0B, rTemp
	// Set the global interrupt flag
	sei
	ldi rTemp, 0b00000001
	// Starta the timer
	sts TIMSK0,rTemp


	// Set the stack pointer to the highest memory adress in ram
	ldi rTemp, HIGH(RAMEND)
	out SPH, rTemp
	ldi rTemp, LOW(RAMEND)
	out SPL, rTemp
	
	// GameLoop Contains the game logic
GameLoop:
	// Set mask for direction
	ldi rTemp, 0b00000011
	// Set the direction that the snake is moving in
	and rDir, rTemp
	// Reset temporary registers
	mov rTimerCount, rZero
	ldi rTemp, 0
	ldi rTemp2, 0
	ldi rTemp3, 0
	// This label jumps to the place that moves the snake
	jmp SnakeMove
GameLoop1:
	// This subroutine puts the snake in the matrix as is
	rcall SnakeToMatrixDisplay
	// Subroutine to update the apple
	rcall UpdateAppleX

	
	// the draw function starts here
reset:
	sbrs rDir, 2
	// Get the input from the X-Axis and AD-convert it
	rcall getInputX
	sbrs rDir, 2
	// Get the input from the Y-Axis and AD-convert it
	rcall getInputY

	// Initiate the matrix for the draw function
	ldi	YH, HIGH(matrix)
	ldi	YL, LOW(matrix)
	// Set the current coordinate to check to the Upper-most row
	ldi	rTemp2, 0b00000001
	ldi	rTemp, 0b00000000
	ldi rTemp3, 16
	// Check if rTimercount has interrupted 16 times, if it has, go to GameLoop.
	cp rTimerCount, rTemp3
	brsh GameLoop
	// Draw the first row of the matrix
	jmp DrawRow
plusC:
	lsl	rTemp2
	jmp DrawRow
setDrow:
	// When 2 rows have been written to the matrix we need to set the registers
	// to start drawing the rows in the other output register because ATMega...
	ldi	rTemp2, 0b00000000
	ldi	rTemp, 0b00000100
	rjmp DrawRow
plusD:
	// Set the next row to be drawn in the D output register.
	lsl rTemp
DrawRow:
	// Reset the Temporary registers to be written to
	ldi rOutputD, 0
	ldi rOutputC, 0
	ldi rOutputB, 0
	// Load the current row to be written.
	ld	rMatrixTemp, Y
	
	// Load the Argument for invertBits Subroutine
	mov rArg, rMatrixTemp
	// Invert the bits of Matrix row
	call invertBits
	// Save the Argument for invertBits Subroutine
	mov rMatrixTemp, rArg
	
	// Shift the Matrix 6 times to get what bits to draw to the other output register
	// in memory
	lsl	rMatrixTemp
	lsl	rMatrixTemp
	lsl	rMatrixTemp
	lsl	rMatrixTemp
	lsl	rMatrixTemp
	lsl	rMatrixTemp
	// Save bits to temporary register rOutputD and save them to the Matrix Pointer
	or	rOutputD, rMatrixTemp
	or	rOutputD, rTemp

	// Reset Matrix Temp
	mov rMatrixTemp, rArg

	// Shift bits to get what is needed to draw to Output B
	lsr	rMatrixTemp
	lsr	rMatrixTemp
	or	rOutputB, rMatrixTemp
	// Set the current row in rOutputC
	or	rOutputC, rTemp2

	// Light the display Leds with output
	out	PORTB, rOutputB
	out PORTC, rOutputC
	out	PORTD, rOutputD
	// Wait for 255 loops	
	ldi	rArg, 255
	rcall wait
	// Reset Output to turn off lights on display.
	out	PORTB, rZero
	out PORTC, rZero
	out	PORTD, rZero
	// Check if loop has gone through all the rows
	cpi	YL, LOW(matrix+7)
	brne dontJump
	jmp reset
dontJump:
	// Subtract the iterator ( Y adress is the Matrix )
	subi YL, -1
	// Check if D rows are being lit and if so plus it
	cpi	rTemp, 0b0000100
	brsh plusD
	// Check if 4 first rows are lit
	cpi	rTemp2, 0b0001000
	brsh setDrow
	// Read Next Row
	jmp plusC
	// This is a waiting Subroutine, 
	// it takes one argument in rArg and it is the number of times it loops.
wait:
	ldi	rMatrixTemp, 0
waitloop:
	// Add one to the iterator
	subi rMatrixTemp, -1
	// See if iterator is done
	cp	rMatrixTemp, rArg
	// If not loop again
	brne waitloop
	// ret Returns to caller from subroutine
ret


SnakeMove:

	// rTemp = coordinates for SnakeHead
	// rTemp2 = Diraction

 	ldi	YH, HIGH(snake)
	ldi	YL, LOW(snake)

	// Move the head to right position depending which Value rDir have
	ld	rTemp, Y 					// Hämta värdet(Koordinaterna)
	mov rTemp2, rDir				// Load the diration of the Snake
	andi rTemp2, 0b00000011			// Make sure it isnt any random value on the other bits

	// Jmp to the right "Move - Function"
	cpi	rTemp2, 0			// if( rDir == 0 )	-> Move Down
	breq MoveDown
	cpi	rTemp2, 1			// if( rDir == 1 )	-> Move Left
	breq MoveLeft
	cpi	rTemp2, 2			// if( rDir == 2 )	-> Move Up
	breq MoveUp
	cpi	rTemp2, 3			// if( rDir == 3 )	-> Move Right
	breq MoveRight

MoveUp:
	
	// rTemp2 = X-Position
	// rTemp3 = Y-Position

	ldi rTemp2, 0b11110000
	and rTemp2, rTemp	

	ldi rTemp3, 0b00001111
	and rTemp3, rTemp	

	subi rTemp3, -1			// rTemp3++, PositionY++

	// Check if the row is 8(Outside the display), change the value to 0
	// if ( rTemp3 == 8 ) -> rTemp3 = 0; 
	// else -> Continue
	cpi rTemp3, 8			
	brne SnakeMoveLoopInit					
	ldi rTemp3, 0			
	jmp SnakeMoveLoopInit

MoveRight:

	// rTemp2 = X-Position
	// rTemp3 = Y-Position

	ldi rTemp3, 0b00001111
	and rTemp3, rTemp	

	mov rTemp2, rTemp

	lsr rTemp2
	lsr rTemp2
	lsr rTemp2
	lsr rTemp2

	
	subi rTemp2, 1		// rTemp2--, PositionX--

	// Check if the row is 8(Outside the display), change the value to 0
	// if ( rTemp3 == 255/-1 ) -> rTemp3 = 7; 
	// else -> Continue
	cpi rTemp2, 0b11111111			// if ( rTemp2 != 255 ) -> Continue
	brne returnX
	ldi rTemp2, 7					// X Position = 7
	jmp returnX

MoveDown:

	// rTemp2 = X-Position
	// rTemp3 = Y-Position

	ldi rTemp2, 0b11110000
	and rTemp2, rTemp	

	ldi rTemp3, 0b00001111
	and rTemp3, rTemp	

	subi rTemp3, 1		// rTemp3--, PositionY--

	// Check if the row is 8(Outside the display), change the value to 0
	// if ( rTemp3 == 255/-1 ) -> rTemp3 = 7; 
	// else -> Continue
	cpi rTemp3, 0b11111111				// if ( rTemp3 != 255 ) -> Continue
	brne SnakeMoveLoopInit					
	ldi rTemp3, 7						// rTemp3 = 7, PositionY = 7
	jmp SnakeMoveLoopInit

MoveLeft:

	// rTemp2 = X-Position
	// rTemp3 = Y-Position

	ldi rTemp3, 0b00001111
	and rTemp3, rTemp	

	mov rTemp2, rTemp

	lsr rTemp2
	lsr rTemp2
	lsr rTemp2
	lsr rTemp2

	subi rTemp2, -1		    // rTemp2++, PositionX++

	cpi rTemp2, 8		    // if ( rTemp2 != 255 ) -> Continue
	brne returnX					
	ldi rTemp2, 0			// rTemp2 = 8
	jmp returnX

// Loopa igenom alla kroppsdelar

returnX:

	// Switch back rTemp2 to Right Position( X-Postion )
	lsl rTemp2
	lsl rTemp2
	lsl rTemp2
	lsl rTemp2

SnakeMoveLoopInit:
	// rTemp	= Old Snake Position
	// rTemp2	= New Position for SnakeBodyPart
	// rTemp3	= Counter
	add rTemp2, rTemp3
	mov rTemp3, rSL

	st Y+, rTemp2			// Save the new position for the Snake-Head
	mov rSnakeHead, rTemp2	// Save even the SnakeHead-Position for collision check in rSnakeHead
	mov rTemp2, rTemp

SnakeMoveLoop:
	

	ld	rTemp, Y		// rTemp saves the old position
	st Y+, rTemp2		// Replace the body with the new position

	// Collision with the SnakeBody and the head
	cp rSnakeHead, rTemp2

	// restart if the Head hit the Body
brne JumpOverOneInstruction 
	jmp init			
JumpOverOneInstruction:

	mov rTemp2, rTemp	// Move the old body position to rTemp

	subi rTemp3, 1
	cpi rTemp3, 1
	brne SnakeMoveLoop


	
	// if (SnakeHead == Apple ) ->
	// rSL++, rSL = SnakeLenght
	// add rTemp2 to the end of the snake

	// Transfer rAppleX and rAppleY to Same Position-Standard as SnakeHead-Position have
	mov rTemp, rAppelX
	mov rTemp3, rAppelY

	lsl rTemp
	lsl rTemp
	lsl rTemp
	lsl rTemp
	or rTemp, rTemp3

	// Make sure the the two bits we dont use for Position dont have any random value
	ldi rTemp3, 0b01110111
	and rTemp, rTemp3
	and rSnakeHead, rTemp3

	// Check if we the SnakeHead hit the Apple
	cp rTemp, rSnakeHead
brne DontAddBody

	ldi rTemp, 1		
	add rSL, rTemp		// Add SnakeBody with 1
	st Y+, rTemp2		// Store the last bodypart with the last position
	rcall NewAppleX


DontAddBody:
jmp GameLoop1

SnakeToMatrixDisplay:
	
	// clear Display
	ldi	YH, HIGH(matrix)
	ldi	YL, LOW(matrix)
	lds rTemp, TCCR0B

	// Clear all rows
	clr	rMatrixTemp
	st	Y+, rMatrixTemp
	st	Y+, rMatrixTemp
	st	Y+, rMatrixTemp
	st	Y+, rMatrixTemp
	st	Y+, rMatrixTemp
	st	Y+, rMatrixTemp
	st	Y+, rMatrixTemp
	st	Y,  rMatrixTemp

	// Y = MatrixDisplay
	// X = Snake
	// rMatrixTemp = Counter
	ldi	XH, HIGH(snake)
	ldi	XL, LOW(snake)

	ldi rMatrixTemp, 0  // Reset Counter

STMDLoop:
	ldi	YL, LOW(matrix)
	ldi	YH, HIGH(matrix)

	// rTemp	= Colum
	// rTemp2	= Row
	// rTemp3	= Counter
	
	// rTemp = X position
	ld	rTemp, X	// Get the Snake coordinates

	// rTemp2 = Y position
	ldi rTemp2, 0b00001111
	and rTemp2, rTemp	// Take out the SnakeBodyPart Y-Position
	
	// Bit-Switch 4 time to right to get the SnakeBodyPart X-Position
	lsr rTemp					
	lsr rTemp
	lsr rTemp
	lsr rTemp

	add YL, rTemp2	// Jump to the right Y-Postion on the MatrixDisplay, Depend on SnakeBodyPart Y-Position
	
	ldi rTemp3, 0b10000000	// Initilize one bit at right

	// BitSwitch to right many times, depend which value SnakePodyPart X-Position have
	rjmp initBitSwitch
BitSwitch:
	subi rTemp, 1
	lsr rTemp3
initBitSwitch:
	cpi rTemp, 0
brne BitSwitch
	
	// The X - Position add with the current MatrixDisplay
	ld	rTemp2, Y
	or rTemp2, rTemp3
	st Y, rTemp2


	subi rMatrixTemp, -1	// Counter++
	subi XL, -1				// Jump to next SnakeBodyPart

	// End if it have loop through all SnakeBodyParts
	cp rMatrixTemp, rSL
brne STMDLoop
ret 

	// This is where the program jumps when the timer interrupts.
timerCount:
	// This is the random function for tha apple position, it is time based and is pseudo random
	mov rInterruptTemp, rRandomNumber
	// add 3 to the appl number (it is between 0-64)
	subi rInterruptTemp, -3
	// if the random number is equal to or bigger than 65 i subtract 65 from the number
	cpi rInterruptTemp, 65
	brsh dontResetRandom
	subi rInterruptTemp, 65
dontResetRandom:
	// Move the random number to its register where it is saved.
	mov rRandomNumber, rInterruptTemp
	// This is the count that keeps track of how many interrupts we have had since the last GameLoop update.
	mov rInterruptTemp, rTimerCount
	// Add one to the count
	subi rInterruptTemp, -1
	mov rTimerCount, rInterruptTemp
	// Return from interrupt call
reti

// This subrouting inverts the bits in a register
// This we did because the display was inverted compared to the registers in our code
// So we inverted the registers back to be in the right way
invertBits:
	mov rTemp3, rArg
	bst rTemp3, 0
	bld rArg, 7
	bst rTemp3, 1
	bld rArg, 6
	bst rTemp3, 2
	bld rArg, 5
	bst rTemp3, 3
	bld rArg, 4
	bst rTemp3, 4
	bld rArg, 3
	bst rTemp3, 5
	bld rArg, 2
	bst rTemp3, 6
	bld rArg, 1
	bst rTemp3, 7
	bld rArg, 0
ret

getInputX:
	// Load ADMUX to rTemp
	lds rTemp, ADMUX
	// Clear ADMUX from input register get
	andi rTemp, 0xF0
	// get Input from X Position
	ori  rTemp, 5
	// Set ADMUX register to get input from X-Axis
	sts ADMUX, rTemp

	// Start AD converting
	lds rTemp, ADCSRA
	sbr rTemp, 1<<6
	sts ADCSRA, rTemp
waitForAD1:
	// sbrc = Skip if bit 6 in register is cleared
	lds rTemp, ADCSRA
	sbrc rTemp, 6
	jmp waitForAD1

	// Check Direction ur moving
	lds rTemp, ADCH

	mov rTemp2, rDir
	// If direction is 1 jump to checkRight
	cpi rTemp2, 1
	breq checkRight
	// Check if stick is pointing in the left direction
	cpi rTemp, -100
	brsh setLeft
CheckRight:
	// If direction is 3 jump to End the check
	cpi rTemp2, 3
	breq endInputX
	// Check if stick is pointing to the Right
	cpi rTemp, 100
	brlo setRight

endInputX:
	// Return if stick isnt moved
	ret
setLeft:
	// Set direction to the left Number
	ldi rTemp, 0b00000111
	mov rDir, rTemp
ret
setRight:
	// Set direction to the right Number
	ldi rTemp, 0b00000101
	mov rDir, rTemp
ret

getInputY:
	// Load ADMUX to rTemp
	lds rTemp, ADMUX
	// Clear ADMUX from input register get
	andi rTemp, 0xF0
	// get Input from X Position
	ori  rTemp, 4
	// Set ADMUX register to get input from X-Axis
	sts ADMUX, rTemp

	// Start AD converting
	lds rTemp, ADCSRA
	sbr rTemp, 1<<6
	sts ADCSRA, rTemp
waitForAD2:
	// sbrc = Skip if bit 6 in register is cleared
	lds rTemp, ADCSRA
	sbrc rTemp, 6
	jmp waitForAD2
			
	// Check Direction ur moving
	lds rTemp, ADCH


	mov rTemp2, rDir
	// Check if the direction is 2, if it is not see if the stick is pointing upwards
	cpi rTemp2, 2
	breq checkDown
	// Check if stick is pointing up
	cpi rTemp, -100
	brsh setUp
checkDown:
	// Check if direction is not 0, if it is not, check if stick is down.
	cpi rTemp2, 0
	breq endInputY
	// Check if stick is pointing down
	cpi rTemp, 100
	brlo setDown
endInputY:
	// Return if stick isnt moved
	ret
	
	// set rDir to the up number
setUp:
	ldi rTemp, 0b00000100
	mov rDir, rTemp
ret
	// set rDir to the down number
setDown:
	ldi rTemp, 0b00000110
	mov rDir, rTemp
ret

UpdateAppleX:
// Load X Coord
ldi rTemp3, 0 //conter
ldi rTemp2, 0b10000000 //get bitshifted to the correct position of the appel on the bord (X axis)
UpdateAppelLoopX:
cp rTemp3,rAppelX // loop for the bitshift
brlo AppeleCounterX

UpdateAppelY:
// Load Y Coord
ldi YL, LOW(matrix) //loads the board matrix in to YL
ldi YH, HIGH(matrix) //loads the board matrix in to YH
ldi rTemp3, 0//conter
UpdateAppelLoopY:
cp rTemp3,rAppelY //loop to find the row the appel is placed on (Y axis)
brlo AppeleCounterY
ld rTemp, Y
or rTemp2, rTemp //running an or between the appel and the board matrix to place the appel in the board matrix
st Y, rTemp2 
ret

UpdateAppeleCounterX:
lsr rTemp2 //bitshift right
subi rTemp3, -1 //conter plus 1
jmp UpdateAppelLoopX

UpdateAppeleCounterY:
ld rTemp, Y+ // load the next row from the board matrix
subi rTemp3, -1 //conter plus 1
jmp UpdateAppelLoopY


NewAppleX:
// Split Random Number To X and Y Coords
// This takes a random number from 0-64 and converts it to X Coordinates to
// be compatible with the new apple Loop
// rTemp2 Is X Coordinate
ldi rTemp, 0b00000111
and rTemp, rRandomNumber
mov rStaticTemp, rTemp

// This takes a random number from 0-64 and converts it to Y Coordinates to
// be compatible with the new apple Loop
// rTemp3 is Y Coordinate
ldi rTemp, 0b00111000
and rTemp, rRandomNumber
mov rStaticTemp2, rTemp
lsr rStaticTemp2
lsr rStaticTemp2
lsr rStaticTemp2

// Load X Coord from the random generated number
mov rTemp, rStaticTemp
mov rAppelX, rTemp
ldi rTemp3, 0 //conter
ldi rTemp2, 0b10000000 //get bitshifted to the correct position of the appel on the bord (X axis)
NewAppelLoopX:
cp rTemp3,rAppelX // loop for the bitshift
brlo AppeleCounterX

NewAppelY:
// Load Y Coord from the random generated number
mov rTemp, rStaticTemp2
mov rAppelY, rTemp
ldi YL, LOW(matrix)
ldi YH, HIGH(matrix)
ldi rTemp3, 0 //conter
NewAppelLoopY:
cp rTemp3,rAppelY //loop to find the correct row where the appel should be placed on (Y axis)
brlo AppeleCounterY
mov rTemp3, rTemp2
ld rTemp, Y
and rTemp2, rTemp //checks if a part if the worm is on this coordinat. If the worm is here random a new number
cp rTemp2,rZero
brne NewAppleX
or rTemp3, rTemp //running an or between the appel and the board matrix to place the appel in the board matrix
st Y, rTemp3
ret
AppeleCounterX:
lsr rTemp2 //bitshift right
subi rTemp3, -1 //conter plus 1
jmp NewAppelLoopX

AppeleCounterY:
ld rTemp, Y+ //load the next row from the board matrix
subi rTemp3, -1 //counter plus 1
jmp NewAppelLoopY
