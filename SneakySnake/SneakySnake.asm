/*
 * SneakySnake.asm
 *
 *  Created: 2014-04-25 08:52:10
 *   Author: Rasmus Wallberg, Patrik Johansson, Johan Lautakoski
 */ 

.DEF rZero			= r0
.DEF rSnakeHead		= r7
.DEF rApplePosition = r8
.DEF rSL			= r9 // SL = SnakeLength, current snake length
.DEF rDir			= r10
.DEF rTimerCount	= r15
.DEF rTemp			= r16
.DEF rTemp2			= r17
.DEF rTemp3			= r18
.DEF rOutputB		= r19
.DEF rOutputC		= r20
.DEF rOutputD		= r21
.DEF rMatrixTemp	= r22
.DEF rInterruptTemp	= r23
.DEF rArg			= r24

.EQU NUM_COLUMNS   = 8

.EQU MAX_LENGTH    = 25
.DSEG
adress:		.BYTE 16
matrix:   .BYTE 8
snake:    .BYTE MAX_LENGTH+1

.CSEG
// Interrupt vector table
.ORG 0x0000
	jmp init // Reset vector
.ORG 0x0020
	sei
	jmp timerCount
//... fler interrupts
.ORG INT_VECTORS_SIZE

init:

	ldi	YH, HIGH(snake)
	ldi	YL, LOW(snake)
	
	// Sätter ormens riktning
	ldi rTemp, 0
	mov rDir, rTemp
	// Sätter ormens position
	ldi	rMatrixTemp, 0x00
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0x01
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0x02
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0x03
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0x04
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0x05
	st	Y, rMatrixTemp

	// Clear rZero to make sure its 0
	clr rZero

	// Laddar in värdet 4 till rSL; rSL = 4
	ldi rTemp, 6
	MOV rSL, rTemp

	ldi rTemp, 0x55
	MOV rApplePosition, rTemp

	// Initiera Matrisen i Minnet
	ldi	YH, HIGH(matrix)
	ldi	YL, LOW(matrix)
	// Ladda in matrisens rader
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
	// Initiera AD-omvandlare
	ldi	rTemp, 0b01100000
	sts ADMUX, rTemp
	ldi rTemp, 0b10000111
	sts ADCSRA, rTemp
	// Initiera PORTB
	ldi	rTemp, 0b11111111
	out DDRB, rTemp
	// Initiera PORTC
	ldi	rTemp, 0b11001111
	out	DDRC, rTemp
	// Initiera PORTD
	ldi	rTemp, 0b11111111
	out DDRD, rTemp

	//timer
	mov rTemp, rZero
	ldi rTemp, (1<<CS02) | (1<<CS00)
	out TCCR0B, rTemp
	sei
	ldi rTemp, 0b00000001
	sts TIMSK0,rTemp
	

	// Sätt stackpekaren till högsta minnesadressen
	ldi YH, HIGH( adress * 2)
	ldi YL, LOW( adress * 2 )

	ldi rTemp, HIGH(RAMEND)
	out SPH, rTemp
	ldi rTemp, LOW(RAMEND)
	out SPL, rTemp
// Här skall all spellogik vara
GameLoop:
	ldi rTemp, 0b00000011
	and rDir, rTemp
	mov rTimerCount, rZero
	ldi rTemp, 0
	ldi rTemp2, 0
	ldi rTemp3, 0
	rcall SnakeMove
	rcall SnakeToMatrixDisplay
//	rcall SnakeCollision

	// Initiera Matrisen i Minnet

	/*
	ldi	YH, HIGH(matrix)
	ldi	YL, LOW(matrix)

	// Get input from X-axis
	// Spara matrisens rad0
	mov	rMatrixTemp, rDir
	st	Y+, rMatrixTemp
	// Spara matrisens rad1
	ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp
	// Spara matrisens rad2
	ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp
	// Spara matrisens rad3
	ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp	
	// Spara matrisens rad4
	ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp
	// Spara matrisens rad5
	ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp
	// Spara matrisens rad6
	ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp
	// Spara matrisens rad7
	ldi	rMatrixTemp, 0b00000000
	st	Y, rMatrixTemp
	*/

	// Här börjar draw funktionen
reset:
	sbrs rDir, 2
	rcall getInputX
	sbrs rDir, 2
	rcall getInputY

	ldi	YH, HIGH(matrix)
	ldi	YL, LOW(matrix)
	ldi	rTemp2, 0b00000001
	ldi	rTemp, 0b00000000
	ldi rTemp3, 12
	cp rTimerCount, rTemp3
	brsh GameLoop
	jmp DrawRow
plusC:
	lsl	rTemp2
	jmp DrawRow
setDrow:
	ldi	rTemp2, 0b00000000
	ldi	rTemp, 0b00000100
	rjmp DrawRow
plusD:
	lsl rTemp
DrawRow:
	ldi rOutputD, 0
	ldi rOutputC, 0
	ldi rOutputB, 0
	ld	rMatrixTemp, Y

	// Invert the bits of Matrix row
	mov rArg, rMatrixTemp
	call invertBits
	mov rMatrixTemp, rArg

	lsl	rMatrixTemp
	lsl	rMatrixTemp
	lsl	rMatrixTemp
	lsl	rMatrixTemp
	lsl	rMatrixTemp
	lsl	rMatrixTemp
	or	rOutputD, rMatrixTemp
	or	rOutputD, rTemp
	ld	rMatrixTemp, Y
	
	// Invert the bits of Matrix row
	mov rArg, rMatrixTemp
	call invertBits
	mov rMatrixTemp, rArg

	lsr	rMatrixTemp
	lsr	rMatrixTemp
	or	rOutputB, rMatrixTemp
	or	rOutputC, rTemp2

	// Light the display Leds with output
	out	PORTB, rOutputB
	out PORTC, rOutputC
	out	PORTD, rOutputD
	// Wait for 100 loops	
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
	// This is a waiting Subroutine, it takes one argument in rArg and it is the number of times it loops.
wait:
	ldi	rMatrixTemp, 0
waitloop:
	subi rMatrixTemp, -1
	cp	rMatrixTemp, rArg
	brne waitloop
	// ret Returns to caller from subroutine
ret


SnakeMove:

	// rTemp = Kordinaterna för Huvudet
	// rTemp2 = Riktningen

 	ldi	YH, HIGH(snake)
	ldi	YL, LOW(snake)

	// Hämta första huvudet o flytta den till den riktningen som joysticen riktar mot
	ld	rTemp, Y 					// Hämta värdet(Koordinaterna)
	mov rTemp2, rDir				// Laddar in riktningen av maskenshuvud
	andi rTemp2, 0b00000011

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

	subi rTemp3, -1			// rTemp2++

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

	
	subi rTemp2, 1

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

	subi rTemp3, 1

	// Check if the row is 8(Outside the display), change the value to 0
	// if ( rTemp3 == 255/-1 ) -> rTemp3 = 7; 
	// else -> Continue
	cpi rTemp3, 0b11111111				// if ( rTemp3 != 255 ) -> Continue
	brne SnakeMoveLoopInit					
	ldi rTemp3, 7			// rTemp3 = 7
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

	subi rTemp2, -1

	cpi rTemp2, 8				// if ( rTemp2 != 255 ) -> Continue
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
	// rTemp	= Gammla ormens position 
	// rTemp2	= Nya Positionen för ormens kroppsdel
	// rTemp3	= Räknare
	add rTemp2, rTemp3
	mov rTemp3, rSL

	st Y+, rTemp2			// Sparar ner den nya positionen för Ormens huvud.
	mov rSnakeHead, rTemp2	// Sparar även ner positionen för ormens huvud för att kolla kollison
	mov rTemp2, rTemp

SnakeMoveLoop:
	
	ld	rTemp, Y
	st Y+, rTemp2
	mov rTemp2, rTemp

	cp rSnakeHead, rTemp2
	brne JumpOverOneInstruction
	jmp init

JumpOverOneInstruction:
	subi rTemp3, 1
	cpi rTemp3, 1
	brne SnakeMoveLoop
ret

SnakeCollision:



SnakeToMatrixDisplay:
	
	// clear Display
	ldi	YH, HIGH(matrix)
	ldi	YL, LOW(matrix)

	// Ladda in matrisens rader
	clr	rMatrixTemp
	st	Y+, rMatrixTemp
	st	Y+, rMatrixTemp
	st	Y+, rMatrixTemp
	st	Y+, rMatrixTemp
	st	Y+, rMatrixTemp
	st	Y+, rMatrixTemp
	st	Y+, rMatrixTemp
	st	Y,  rMatrixTemp

	// Y = MatrixDisplayen
	// X = Snake
	// rMatrixTemp = Räknare
	ldi	XH, HIGH(snake)
	ldi	XL, LOW(snake)

	ldi rMatrixTemp, 0

STMDLoop:
	ldi	YL, LOW(matrix)
	ldi	YH, HIGH(matrix)

	// rTemp	= Vilken Kolum
	// rTemp2	= Vilkem Rad
	// rTemp3	= Räknare
	
	// rTemp = X position
	ld	rTemp, X	// Hämtar Ormens koordinater

	// rTemp2 = Y position
	ldi rTemp2, 0b00001111
	and rTemp2, rTemp	// Tar ut Ormens Y koordinat
	
	// Bit-Switchar 4 till höger för att få Ormens X koordinat
	lsr rTemp					
	lsr rTemp
	lsr rTemp
	lsr rTemp

	add YL, rTemp2	// Plussar på DisplayMatrixen med Y-koordVärdet.
	
	ldi rTemp3, 0b10000000

	rjmp initBitSwitch
BitSwitch:
	subi rTemp, 1
	lsr rTemp3
initBitSwitch:
	cpi rTemp, 0
brne BitSwitch
	
	// rTemp ska nu plussa/or med MatrisDisplayen
	ld	rTemp2, Y
	or rTemp2, rTemp3
	st Y, rTemp2

	// 2 RÄknare som plussas på
	subi rMatrixTemp, -1	// rMatrixTemp++
	subi XL, -1

	cp rMatrixTemp, rSL
brne STMDLoop
ret // Loopa igenom alla kroppsdelar

timerCount:
	mov rInterruptTemp, rTimerCount
	subi rInterruptTemp, -1
	mov rTimerCount, rInterruptTemp
reti

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

	// Default Stick Position is about 130 = 0b10000010 = 0x82
	// cpi rTemp, 160
	mov rTemp2, rDir
	// brge SetLeft
	cpi rTemp2, 1
	breq checkRight
	cpi rTemp, -100
	brsh setLeft
CheckRight:
	cpi rTemp2, 3
	breq endInputX
	cpi rTemp, 100
	brlo setRight

endInputX:
	// Return if stick isnt moved
	ret
setLeft:
	ldi rTemp, 0b00000111
	mov rDir, rTemp
ret
setRight:
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

	// Default Stick Position is about 130 = 0b10000010 = 0x82
	// cpi rTemp, 160
	// brge setRight
	mov rTemp2, rDir
	// brge SetLeft
	cpi rTemp2, 2
	breq checkDown
	cpi rTemp, -100
	brsh setUp
checkDown:
	cpi rTemp2, 0
	breq endInputY
	cpi rTemp, 100
	brlo setDown
endInputY:
	// Return if stick isnt moved
	ret
setUp:
	ldi rTemp, 0b00000100
	mov rDir, rTemp
ret
setDown:
	ldi rTemp, 0b00000110
	mov rDir, rTemp
ret