/*
 * SneakySnake.asm
 *
 *  Created: 2014-04-25 08:52:10
 *   Author: Rasmus Wallberg, Patrik Johansson, Johan Lautakoski
 */ 

.DEF rTemp         = r16
.DEF rDirection    = r23
.DEF rToRegister   = r17
.DEF rInitRegs	   = r18
.DEF rRowCountC	   = r19
.DEF rRowCountD	   = r20

.EQU NUM_COLUMNS   = 8
.EQU MAX_LENGTH    = 25
.DSEG
matrix:   .BYTE 8
snake:    .BYTE MAX_LENGTH+1

.CSEG
// Interrupt vector table
.ORG 0x0000
	jmp init // Reset vector
//... fler interrupts
.ORG INT_VECTORS_SIZE
init:
	// Sätt stackpekaren till högsta minnesadressen
	ldi rTemp, HIGH(RAMEND)
	ldi	rInitRegs, 0b11001111
	out	DDRC, rInitRegs
	ldi	rInitRegs, 0b11111111
	out DDRD, rInitRegs
	ldi	rInitRegs, 0b00111111
	out DDRB, rInitRegs
	out SPH, rTemp
	ldi rTemp, LOW(RAMEND)
	out SPL, rTemp
reset:
	ldi rRowCountC, 0b00000001
	ldi rRowCountD, 0b00000000
	jmp	loop
plusD:
	lsl rRowCountD
	jmp loop
initD:
	ldi rRowCountD, 0b00000100
	ldi	rRowCountC, 0b00000000
	jmp loop
plusC:
	lsl	rRowCountC
loop:
	// PORT D
	ldi	rToRegister, 0b11000000
	or	rToRegister, rRowCountD
	out	PORTD, rToRegister
	// PORT B
	ldi	rToRegister, 0b00111111
	out	PORTB, rToRegister
	// PORT C
	out PORTC, rRowCountC
	cpi	rRowCountD, 0b00100000
	brsh reset
	cpi	rRowCountD, 0b00000100
	brsh plusD
	cpi	rRowCountC, 0b00001000
	brsh initD
	jmp	plusC
