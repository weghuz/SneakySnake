/*
 * SneakySnake.asm
 *
 *  Created: 2014-04-25 08:52:10
 *   Author: Rasmus Wallberg, Patrik Johansson, Johan Lautakoski
 */ 
.DEF rTempStatic	= r15
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

.EQU NUM_COLUMNS	= 8
.EQU MAX_LENGTH		= 25
.DSEG
matrix:		.BYTE 8
snake:		.BYTE MAX_LENGTH+1

.CSEG
// Interrupt vector table
.ORG 0x0000
	jmp init // Reset vector
//... fler interrupts
.ORG INT_VECTORS_SIZE
init:
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
	// Load ADMUX to rTemp
	lds rTemp, ADMUX
	// 1<<2 = 0b00000100
	andi rTemp, 1<<2
	sts ADMUX, rTemp


	// Initiera PORTB
	ldi	rTemp, 0b11111111
	out DDRB, rTemp
	// Initiera PORTC
	ldi	rTemp, 0b11001111
	out	DDRC, rTemp
	// Initiera PORTD
	ldi	rTemp, 0b11111111
	out DDRD, rTemp
	// Sätt stackpekaren till högsta minnesadressen
	ldi rTemp, HIGH(RAMEND)
	out SPH, rTemp
	ldi rTemp, LOW(RAMEND)
	out SPL, rTemp
// Här skall all spellogik vara
GameLoop:
	/*
	// Initiera Matrisen i Minnet
	ldi	YH, HIGH(matrix*2)
	ldi	YL, LOW(matrix*2)
	// Ladda in matrisens rader
	ld	rTemp, Y
	subi rTemp, -1
	st	Y+, rTemp
	ld	rTemp, Y
	subi rTemp, -1
	st	Y+, rTemp
	ld	rTemp, Y
	subi rTemp, -1
	st	Y+, rTemp
	ld	rTemp, Y
	subi rTemp, -1
	st	Y+, rTemp
	ld	rTemp, Y
	subi rTemp, -1
	st	Y+, rTemp
	ld	rTemp, Y
	subi rTemp, -1
	st	Y+, rTemp
	ld	rTemp, Y
	subi rTemp, -1
	st	Y+, rTemp
	ld	rTemp, Y
	subi rTemp, -1
	st	Y, rTemp
	*/
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
	ldi rArg, 10
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