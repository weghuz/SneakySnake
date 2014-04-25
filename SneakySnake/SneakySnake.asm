/*
 * SneakySnake.asm
 *
 *  Created: 2014-04-25 08:52:10
 *   Author: Rasmus Wallberg, Patrik Johansson, Johan Lautakoski
 */ 

.DEF rTemp         = r16
.DEF rDirection    = r23
.DEF rOne		   = r17

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
	ldi	r18, 0b11001111
	out	DDRC, r18
	ldi	r18, 0b11111111
	out DDRD, r18
	out SPH, rTemp
	ldi rTemp, LOW(RAMEND)
	out SPL, rTemp
loop:
	ldi	rOne, 0b01000000
	out	PORTD, rOne
	ldi	rOne, 0b00000001
	out PORTC, rOne
	jmp	loop
