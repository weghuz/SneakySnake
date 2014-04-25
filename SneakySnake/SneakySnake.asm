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
	// Sätt stackpekaren till högsta minnesadressen
	ldi	YH, HIGH(matrix*2)
	ldi	YL, LOW(matrix*2)
	ldi	rMatrixTemp, 0b10000000
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b00000001
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b00110000
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b00000000
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b00000001
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b00100000
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b00000100
	st	Y+, rMatrixTemp
	ldi	rMatrixTemp, 0b00001000
	st	Y, rMatrixTemp
	ldi rTemp, HIGH(RAMEND)
	ldi	rTemp2, 0b11001111
	out	DDRC, rTemp2
	ldi	rTemp2, 0b11111111
	out DDRD, rTemp2
	ldi	rTemp2, 0b00111111
	out DDRB, rTemp2
	out SPH, rTemp
	ldi rTemp, LOW(RAMEND)
	out SPL, rTemp
	ldi	rTemp, 0
reset:
	ldi	YH, HIGH(matrix*2)
	ldi	YL, LOW((matrix*2)+7)
	ldi	rTemp2, 0b00000001
	ldi	rTemp, 0b00000000
	jmp checkrow
plusC:
	lsl	rTemp2
	jmp checkrow
checkrow:
	ldi	rOutputB, 0b00000000
	ldi	rOutputC, 0b00000000
	ldi	rOutputD, 0b00000000
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

	out	PORTB, rOutputB
	out PORTC, rOutputC
	out	PORTD, rOutputD

	cpi	YL, LOW(matrix*2)
	breq reset
	cpi	rTemp2, 0b0001000
	brsh reset
	subi YL, 1
	jmp	plusC
