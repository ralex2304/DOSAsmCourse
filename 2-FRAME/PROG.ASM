.model tiny
.286
.code
org 100h

include ..\macros.asm

Start:		jmp main

ScreenWidth	equ 80
ScreenHeight	equ 26

ShadowAttrMask	equ 10000111b

FrameColorAttr	equ 01001110b
TLCorner	equ 0c9h
TRCorner	equ 0bbh
BLCorner	equ 0c8h
BRCorner	equ 0bch
VLine		equ 0bah
HLine		equ 0cdh
Space		equ ' '

FrameBegLine	equ 5
FrameBegCol	equ 20
FrameWidth	equ 40
FrameHeight	equ 10

;--------------------------------------
; Draws symbol
; Entry:	dh - line num
;		dl - col num
;		cl - symbol
;		ch - attr
; Assumes:	es = 0b800h
; Destr:	ax, bx
;--------------------------------------
DrawSymbol	proc

		push dx

		mov al, dh
		mov bl, ScreenWidth
		mul bl	   ; ax = dh * ScreenWidth

		mov dh, 0
		add ax, dx ; ax += dl (col num)

		mov bx, 2
		mul bx     ; (dx, ax) = ax * 2

		mov bx, ax
		mov word ptr es:[bx], cx

		pop dx
		ret
		endp
;--------------------------------------

;--------------------------------------
; Modifies symbol attr (applies & operation with attr mask)
; Entry:	dh - line num
;		dl - col num
;		ch - attr mask
; Assumes:	es = 0b800h
; Destr:	ax, bx
;--------------------------------------
ModSymbolAttr	proc

		push dx

		mov al, dh
		mov bl, ScreenWidth
		mul bl	   ; ax = dh * ScreenWidth

		mov dh, 0
		add ax, dx ; ax += dl (col num)

		mov bx, 2
		mul bx     ; (dx, ax) = ax * 2

		mov bx, ax
		inc bx ; attr address

		and byte ptr es:[bx], ch

		pop dx
		ret
		endp
;--------------------------------------

;--------------------------------------
; Draws frame
; Entry:
; Assumes:	es = 0b800h
; Destr:	ax, bx, cx, dx
;--------------------------------------
DrawFrame	proc

		; init attr
		mov ch, FrameColorAttr

		mov dh, FrameBegLine

		; top empty line
		mov cl, Space
		call DrawFrameEmptyLine
		inc dh

		; top line
		mov cl, TLCorner
		mov ah, HLine
		mov al, TRCorner
		call DrawFrameLine

		; middle lines
DFWhile:	inc dh
		cmp dh, FrameHeight - 3 + FrameBegLine
		ja DFWhileEnd

		mov cl, VLine
		mov ah, Space
		mov al, VLine
		call DrawFrameLine
		jmp DFWhile
DFWhileEnd:

		; bottom line
		mov cl, BLCorner
		mov ah, HLine
		mov al, BRCorner
		call DrawFrameLine
		inc dh

		; bottom empty line
		mov cl, Space
		call DrawFrameEmptyLine

		ret
		endp
;---------------------------------------

;---------------------------------------
; Draws one line of fram (1 symbol + n symbols + 1 symbol)
;
; Entry: 	dh - line number
;		ch - color attr
;		cl - empty symbol
; Assumes:	es = 0b800h
;
; Destr:	ax, bx, cl, dl
;--------------------------------------
DrawFrameEmptyLine	proc

		mov dl, FrameBegCol

		; while (dl++ < FrameWidth + FrameBegCol - 1):
		; 	DrawSymbol()
DFLEwhile:	cmp dl, FrameWidth + FrameBegCol - 1
		ja DFLEwhileEnd

		call DrawSymbol

		inc dl
		jmp DFLEwhile
DFLEwhileEnd:

		ret
		endp

;--------------------------------------

;--------------------------------------
; Draws one line of fram (1 symbol + n symbols + 1 symbol)
;
; Entry: 	dh - line number
;		ch - color attr
;		cl - left symbol
;		ah - middle symbol
;		al - right symbol
; Assumes:	es = 0b800h
;
; Destr:	ax, bx, cl, dl
;-------------------------------------
MidSymNumber	equ FrameWidth - 4

DrawFrameLine	proc

		push ax ; right and middle symbols
		push ax
		push cx ; left symbol

		; write empty symbol
		mov dl, FrameBegCol
		mov cl, Space
		call DrawSymbol

		; write left symbol
		inc dl
		pop bx
		mov cl, bl
		call DrawSymbol

		; write middle symbols
		pop bx
		mov cl, bh

		; while (dl++ < MidSymNumber + (FrameBegCol + 1)):
		; 	DrawSymbol()
DFLwhile:	inc dl
		cmp dl, MidSymNumber + (FrameBegCol + 1)
		ja DFLwhileEnd

		call DrawSymbol

		jmp DFLWhile
DFLwhileEnd:
		; write right symbol
		pop bx
		mov cl, bl
		call DrawSymbol

		; write empty symbol
		inc dl
		mov cl, Space
		call DrawSymbol

		ret
		endp

;--------------------------------------

;--------------------------------------
; Draws shadow
;
; Entry:
; Assumes:	es = 0b800h
;
; Destr:
;--------------------------------------
DrawShadow	proc

		mov ch, ShadowAttrMask
		mov dh, FrameBegLine + 1
		mov dl, FrameBegCol + FrameWidth

DSvertWhile:	cmp dh, FrameBegLine + FrameHeight
		ja DSvertWhileEnd

		call ModSymbolAttr
		inc dh
		jmp DSvertWhile
DSvertWhileEnd:
		dec dh

DShorWhile:	cmp dl, FrameBegCol + 1
		jb DShorWhileEnd

		call ModSymbolAttr
		dec dl
		jmp DShorWhile
DShorWhileEnd:

		ret
		endp
;--------------------------------------

;--------------------------------------
; Paints console in blue
;
; Entry:
; Assumes:	es = 0b800h
; Destr:	ch, bx
;--------------------------------------
MakeConsoleBrightAgain	proc

		mov ch, 00011111b
		mov bx, 1

MCBAwhile:	cmp bx, ScreenHeight * ScreenWidth * 2
		ja MCBAwhileEnd

		mov byte ptr es:[bx], ch
		inc bx
		inc bx

		jmp MCBAwhile
MCBAwhileEnd:

		ret
		endp
;--------------------------------------

;======================================
main:
		mov bx, 0b800h
		mov es, bx ; videomem seg

		call MakeConsoleBrightAgain

		call DrawFrame
		call DrawShadow

		EOP

end		Start
