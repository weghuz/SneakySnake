/*
 * SneakySnake.asm
 *
 *  Created: 2014-04-25 08:52:10
 *   Author: Rasmus Wallberg, Patrik Johansson, Johan Lautakoski
 */ 

.DEF rTemp			= r16
.DEF rTemp2			= r17
.DEF rInitRegs		= r18
.DEF rOutputB		= r19
.DEF rOutputC		= r20
.DEF rOutputD		= r21
.DEF rMatrixTemp	= r22
.DEF rWait			= r23
.DEF rArg			= r24

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
	// Ladda in matrisen rad 0
	ldi	rMatrixTemp, 0b10000000
	st	Y+, rMatrixTemp
	// Ladda in matrisen rad 1
	ldi	rMatrixTemp, 0b00000001
	st	Y+, rMatrixTemp
	// Ladda in matrisen rad 2
	ldi	rMatrixTemp, 0b00110000
	st	Y+, rMatrixTemp
	// Ladda in matrisen rad 3
	ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp
	// Ladda in matrisen rad 4
	ldi	rMatrixTemp, 0b00000001
	st	Y+, rMatrixTemp
	// Ladda in matrisen rad 5
	ldi	rMatrixTemp, 0b00100000
	st	Y+, rMatrixTemp
	// Ladda in matrisen rad 6
	ldi	rMatrixTemp, 0b00000100
	st	Y+, rMatrixTemp
	// Ladda in matrisen rad 7
	ldi	rMatrixTemp, 0b00001000
	st	Y, rMatrixTemp
	// Initiera PORTB
	ldi	rTemp2, 0b00111111
	out DDRB, rTemp2
	// Initiera PORTC
	ldi	rTemp2, 0b11001111
	out	DDRC, rTemp2
	// Initiera PORTD
	ldi	rTemp2, 0b11111111
	out DDRD, rTemp2
	// Sätt stackpekaren till högsta minnesadressen
	ldi rTemp, HIGH(RAMEND)
	out SPH, rTemp
	ldi rTemp, LOW(RAMEND)
	out SPL, rTemp
	ldi	rTemp, 0
reset:
	ldi	YH, HIGH(matrix*2)
	ldi	YL, LOW((matrix*2)+7)
	ldi	rTemp2, 0b00000001
	ldi	rTemp, 0b00000000
	rjmp checkrow
plusC:
	lsl	rTemp2
	rjmp checkrow
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
	ldi rArg, 100
	rcall wait
	// Check if loop has gone through all the rows
	cpi	YL, LOW(matrix*2)
	breq reset
	// Check if 4 first rows are lit
	cpi	rTemp2, 0b0001000
	brsh reset
	subi YL, 1
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
	// Read Next Row
	brsh plusC
	// This is a waiting Subroutine, it takes one argument in rArg and it is the number of times it loops.
wait:
	ldi	rWait, 0
waitloop:
	subi rWait, -1
	cp	rWait, rArg
	brne waitloop
	// ret Returns to caller from subroutine
ret