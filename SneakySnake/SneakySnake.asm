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
.DEF rInitRegs		= r19
.DEF rOutputB		= r20
.DEF rOutputC		= r21
.DEF rOutputD		= r22
.DEF rMatrixTemp	= r23
.DEF rWait			= r24
.DEF rArg			= r25


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
	ldi	YH, HIGH(snake*2)
	ldi	YL, LOW(snake*2)

	// Sätter
	ldi	rMatrixTemp, 0b00100100
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b00110100
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b01000100
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b01010100
	st	Y, rMatrixTemp

	// Laddar in värdet 4 till rSL; rSL = 4
	ldi rTemp, 4
	MOV rSL, rTemp

	// Initiera Matrisen i Minnet
	ldi	YH, HIGH(matrix*2)
	ldi	YL, LOW(matrix*2)
	// Ladda in matrisens rader
	ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b00011110
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b00010000
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b00010000
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b00110000
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
	ldi rTimerCount, 0
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
	ldi	YH, HIGH(matrix*2)
	ldi	YL, LOW(matrix*2)
	
	// Load ADMUX to rTemp
	lds rTemp, ADMUX
	// Clear ADMUX from input register get
	andi rTemp, 0xF0
	// 1<<2 = 0b00000100
	// get Input from Y-axis
	sbr rTemp, 1<<2
	sts ADMUX, rTemp
	// Start AD converting
	lds rTemp, ADCSRA
	sbr rTemp, 1<<6
	sts ADCSRA, rTemp
waitForAD1:
	// Busy Wait loop
	ldi rArg, 1
	rcall wait
	// sbrc = Skip if bit 6 in register is cleared
	lds rTemp, ADCSRA
	sbrc rTemp, 6
	jmp waitForAD1

	// Spara matrisens rad0
	lds rMatrixTemp, ADCH
	//lds rTemp, ADCL
	st	Y+, rMatrixTemp

	// Spara matrisens rad1
	// ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp
	// Spara matrisens rad2
	//ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp
	// Spara matrisens rad3
	//ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp	

	// Load ADMUX to rTemp
	lds rTemp, ADMUX
	// Clear ADMUX from input register get
	andi rTemp, 0xF0
	// 1<<2 = 0b00000100
	ori rTemp, 5
	sts ADMUX, rTemp
	
	// Start AD converting
	lds rTemp, ADCSRA
	sbr rTemp, 1<<6
	sts ADCSRA, rTemp
waitForAD2:
	// Busy Wait loop
	ldi rArg, 1
	rcall wait
	// sbrc = Skip if bit 6 in register is cleared
	lds rTemp, ADCSRA
	sbrc rTemp, 6
	jmp waitForAD2

	// Spara matrisens rad4
	lds rMatrixTemp, ADCH
	st	Y+, rMatrixTemp
	
	// Spara matrisens rad5
	//ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp
	// Spara matrisens rad6
	//ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp
	// Spara matrisens rad7
	//ldi	rMatrixTemp, 0b00000000
	st	Y, rMatrixTemp
	// Här börjar draw funktionen
reset:
	ldi	YH, HIGH(matrix*2)
	ldi	YL, LOW((matrix*2)+7)
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
	lsl	rMatrixTemp
	lsl	rMatrixTemp
	lsl	rMatrixTemp
	lsl	rMatrixTemp
	lsl	rMatrixTemp
	lsl	rMatrixTemp
	or	rOutputD, rMatrixTemp
	or	rOutputD, rTemp
	ld	rMatrixTemp, Y
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
	ldi rArg, 255
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
	cpi	YL, LOW(matrix*2)
	brne dontJump
	jmp GameLoop
dontJump:
	// Subtract the iterator ( Y adress is the Matrix )
	subi YL, 1
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
	ldi	YH, HIGH(snake*2)
	ldi	YL, LOW(snake*2)

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


MoveRight:


MoveDown:


MoveLeft:



	// Loopa igenom alla kroppsdelar
timerCount:
	subi rTimerCount, -1
	reti
