.model tiny
.286
.code
org 100h
locals @@

include ..\macros.asm

Start:		jmp main

StringSrc  db "1234567890"
StringDest db "abcdefghji"

include LIB.ASM

;======================================
main:
		cld

		push 4
		push offset String2
		push offset String1
		call mymemcmp
		add sp, 6

		EOP

String1 db "abcde"
String2 db "abcee"

end		Start
