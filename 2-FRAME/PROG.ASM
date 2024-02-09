.model tiny
.286
.code
org 100h

include ..\macros.asm

Start:		jmp main

ScreenWidth	equ 80
ScreemHeight	equ 26

;--------------------------------------
; Draws symbol
; Entry:	DH - line num
;		DL - col num
;		CL - symbol
;		CH - attr
; Assumes:	ES = 0b800h
; Destr:	AX, BX
;--------------------------------------
DrawSymbol	proc

		push DX

		mov AL, DH
		mov BL, ScreenWidth
		mul BL	   ; AX = DH * ScreenWidth

		mov DH, 0
		add AX, DX ; AX += DL (col num)

		mov BX, 2
		mul BX     ; (DX, AX) = AX * 2

		mov BX, AX
		mov word ptr ES:[BX], CX

		pop DX
		ret
		endp
;--------------------------------------

;--------------------------------------
; Draws frame
; Entry:
; Assumes:	ES = 0b800h
; Destr:	AX, BX, CX, DX
;--------------------------------------

FrameColorAttr	equ 01001110b
TLCorner	equ '1'
TRCorner	equ '2'
BLCorner	equ '3'
BRCorner	equ '4'
VLine		equ '5'
HLine		equ '6'
Space		equ ' '

FrameBegLine	equ 5
FrameWidth	equ 40
FrameHeight	equ 10

DrawFrame	proc

		; init attr
		mov CH, FrameColorAttr

		; top line
		mov DH, FrameBegLine
		mov CL, TLCorner
		mov AH, HLine
		mov AL, TRCorner
		call DrawFrameLine

		; middle lines
DFWhile:	inc DH
		cmp DH, FrameHeight - 2 + FrameBegLine
		ja DFWhileEnd

		mov CL, VLine
		mov AH, Space
		mov AL, VLine
		call DrawFrameLine
		jmp DFWhile
DFWhileEnd:


		; bottom line
		mov CL, BLCorner
		mov AH, HLine
		mov AL, BRCorner
		call DrawFrameLine

		ret
		endp
;---------------------------------------

;---------------------------------------
; Draws one line of fram (1 symbol + n symbols + 1 symbol)
;
; Entry: 	DH - line number
;		CH - color attr
;		CL - left symbol
;		AH - middle symbols
;		AL - right symbol
; Assumes:	ES = 0b800h
;
; Destr:	AX, BX, CL, DL
;--------------------------------------

FrameBegCol	equ 20
MidSymNum	equ FrameWidth - 2

DrawFrameLine	proc

		push AX ; right and middle symbols
		push AX

		; write left symbol
		mov DL, FrameBegCol
		call DrawSymbol

		; write middle symbols
		pop BX
		mov CL, BH

		; while (DL++ < MidSymNum + FrameBegCol):
		; 	DrawSymbol()
DFLwhile:	inc DL
		cmp DL, MidSymNum + FrameBegCol
		ja DFLwhileEnd

		call DrawSymbol

		jmp DFLWhile
DFLwhileEnd:
		; write right symbol
		pop BX
		mov CL, BL
		call DrawSymbol

		ret
		endp

;--------------------------------------

;======================================
main:
		mov BX, 0b800h
		mov ES, BX ; videomem seg

		;call FillBackground
		call DrawFrame

		EOP

end		Start
