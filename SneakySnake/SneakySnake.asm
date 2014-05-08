/*
 * SneakySnake.asm
 *
 *  Created: 2014-04-25 08:52:10
 *   Author: Rasmus Wallberg, Patrik Johansson, Johan Lautakoski
 */ 

.DEF rZero			= r0
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
.DEF rWait			= r23
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
	 jmp timerCount
//... fler interrupts
.ORG INT_VECTORS_SIZE
init:

InitializeSnake: // Initierar Masken i minnet
	ldi	YH, HIGH(snake)
	ldi	YL, LOW(snake)

	// Sätter
	ldi	rMatrixTemp, 0x01
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0x02
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0x03
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0x04
	st	Y, rMatrixTemp

	// Laddar in värdet 4 till rSL; rSL = 4
	ldi rTemp, 4
	MOV rSL, rTemp

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

	//timer ska paceras någon anna stans
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
	// Initiera Matrisen i Minnet

	rcall SnakeMove

	ldi	YH, HIGH(matrix)
	ldi	YL, LOW(matrix)

	// Get input from X-axis
	
	// Spara matrisens rad0
	ldi	rMatrixTemp, 0b00000000
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
	ldi	rMatrixTemp, 0b11000101
	st	Y, rMatrixTemp
	// Här börjar draw funktionen



reset:
	ldi	YH, HIGH(matrix)
	ldi	YL, LOW((matrix))
	ldi	rTemp2, 0b00000001
	ldi	rTemp, 0b00000000
	jmp checkrow
plusC:
	lsl	rTemp2
	jmp checkrow
setDrow:
	ldi	rTemp2, 0b00000000
	ldi	rTemp, 0b00000100
	rjmp checkrow
plusD:
	lsl rTemp
checkrow:
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
loop:
	// Light the display Leds with output
	out	PORTB, rOutputB
	out PORTC, rOutputC
	out	PORTD, rOutputD
	// Wait for 100 loops
	ldi rArg, 20
	rcall wait
	// Reset Output to turn off lights on display.
	ldi	rOutputB, 0b00000000
	ldi	rOutputC, 0b00000000
	ldi	rOutputD, 0b00000000
	out	PORTB, rOutputB
	out PORTC, rOutputC
	out	PORTD, rOutputD
	// Wait for one loop
	ldi	rArg, 1
	rcall wait
	// Check if loop has gone through all the rows
	cpi	YL, LOW(matrix+7)
	brne dontJump
	jmp GameLoop
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
	ldi	rWait, 0
waitloop:
	subi rWait, -1
	cp	rWait, rArg
	brne waitloop
	// ret Returns to caller from subroutine
ret


SnakeMove:

	// rTemp = Kordinaterna för Huvudet
	// rTemp2 = Riktningen

	ldi rTemp, 3
	mov rDir, rTemp

 	ldi	YH, HIGH(snake)
	ldi	YL, LOW(snake)

	// Hämta första huvudet o flytta den till den riktningen som joysticen riktar mot
	ld	rTemp, Y 					// Hämta värdet(Koordinaterna)
	add rTemp2, rDir				// Laddar in riktningen av maskenshuvud

	cpi	rTemp2, 0			// if( rDir == 0 )	-> Move Up
	breq MoveUp
	cpi	rTemp2, 1			// if( rDir == 1 )	-> Move Right
	breq MoveRight
	cpi	rTemp2, 2			// if( rDir == 2 )	-> Move Down
	breq MoveDown
	cpi	rTemp2, 3			// if( rDir == 3 )	-> Move Left
	breq MoveLeft

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
	cpi rTemp2, 0b11111111			// if ( rTemp2 != 8 ) -> Continue
	brne SnakeMoveLoopInitBitSwitch					
	ldi rTemp2, 7			// rTemp2 = 0
	jmp SnakeMoveLoopInitBitSwitch
	

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
	cpi rTemp3, 0b11111111				// if ( rTemp3 != 255/-1 ) -> Continue
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
	brne SnakeMoveLoopInitBitSwitch					
	ldi rTemp2, 0			// rTemp2 = 8
	jmp SnakeMoveLoopInitBitSwitch

// Loopa igenom alla kroppsdelar

SnakeMoveLoopInitBitSwitch:

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
	mov rTemp2, rTemp

SnakeMoveLoop:
	
	ld	rTemp, Y
	st Y+, rTemp2
	mov rTemp2, rTemp

	subi rTemp3, 1
	cpi rTemp3, 1
	brne SnakeMoveLoop
ret


ClearDisplayMatrix:
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
ret

SnakeToMatrixDisplay:

	rcall ClearDisplayMatrix

	// Y = MatrixDisplayen
	// X = Snake
	// rMatrixTemp = Räknare
	ldi	XH, HIGH(snake)
	ldi	XL, LOW(snake)

	ldi rMatrixTemp, 0

STMDLoop:
	ldi	YH, HIGH(matrix)
	ldi	YL, LOW(matrix)

	// rTemp	= Vilken Kolum
	// rTemp2	= Vilkem Rad
	// rTemp3	= Räknare

	ld	rTemp, X				// Hämtar Ormens koordinater
	ldi rTemp2, 0b00001111		
	and rTemp2, rTemp			// Tar ut Ormens Y koordinat
	// Bit-Switchar 4 till höger för att få Ormens X koordinat
	lsr rTemp					
	lsr rTemp				
	lsr rTemp
	lsr rTemp

	// rTemp = 

	add YL, rTemp2	// Plussar på DisplayMatrixen med Y-koordVärdet.

	
	mov rTemp3, rTemp
	ldi rTemp, 0b00000001
BitSwitch:
	subi rTemp3, 1
	lsl rTemp
	cpi rTemp3, 0
brne BitSwitch

	// rTemp ska nu plussar/or med MatrisDisplayen
	ld	rTemp2, Y
	or rTemp2, rTemp
	st Y, rTemp2

	// 2 RÄknare som plussas på
	subi rMatrixTemp, -1	// rMatrixTemp++
	subi XL, -1

	cp rMatrixTemp, rSL
brne STMDLoop
ret // Loopa igenom alla kroppsdelar

timerCount:
	mov rTemp, rTimerCount
	subi rTemp, -1
	mov rTimerCount, rTemp
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

getInput:
	// Load ADMUX to rTemp
	lds rTemp, ADMUX
	// Clear ADMUX from input register get
	andi rTemp, 0xF0
	// get Input from rArg, send in 4 for X-axis and 5 for Y-axis
	or  rTemp, rArg
	// reset rArg (Argument to subroutine) for next call
	ldi rArg, 0
	sts ADMUX, rTemp
	// Start AD converting
	lds rTemp, ADCSRA
	sbr rTemp, 1<<6
	sts ADCSRA, rTemp
waitForAD:
	// Busy Wait loop
	ldi rArg, 1
	rcall wait
	// sbrc = Skip if bit 6 in register is cleared
	lds rTemp, ADCSRA
	sbrc rTemp, 6
	jmp waitForAD
	// --Call for X-Axis--
	//   ldi rArg, 4
	//   call getInput
	// --Call for Y-Axis--
	//   ldi rArg, 5
	//   call getInput
	// --Get value after convert is done with--
	//   lds rTemp, ADCH
ret
