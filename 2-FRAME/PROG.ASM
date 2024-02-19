.model tiny
.286
.code
org 100h

locals @@

include ..\macros.asm

Start:		jmp main

include ..\3-FUNCS\LIB.ASM

ScreenWidth	equ 80
ScreenHeight	equ 26

ShadowAttrMask	equ 10000111b

Space		equ ' '
NewLine		equ 0dh

FrameBegLine	equ 5
FrameBegCol	equ 20

ArgcAddr	equ 0080h
ArgvAddr	equ 0081h

;--------------------------------------
; Draws frame
; Entry:	bp = style str addr
;		cl = width
;		ch = height
;		dh = color
;
; Assumes:	es = 0b800h
; Destr:	ax, bx, dl
;--------------------------------------
DrawFrame	proc

		mov bx, (FrameBegLine * ScreenWidth + FrameBegCol) * 2
		; bx => x = 0; y = 0

		call DrawFrameEmptyLine
		add bx, ScreenWidth * 2
		xor ah, ah
		mov al, cl
		shl ax, 1  ; ax = width * 2
		sub bx, ax ; bx => x = 0; y = 1

		; top line
		call DrawFrameLine
		add bx, ScreenWidth * 2
		xor ah, ah
		mov al, cl
		shl ax, 1  ; ax = width * 2
		sub bx, ax ; bx => x = 0; y = 2

		; middle lines
		add bp, 3

		mov ax, ScreenWidth * 2
		mul ch
		sub ax, (4 * ScreenWidth) * 2
		add ax, bx

		jmp @@DFwhileClause
@@DFwhile:
		push ax ; save ax
		call DrawFrameLine
		add bx, ScreenWidth * 2
		xor ah, ah
		mov al, cl
		shl ax, 1
		sub bx, ax

		pop ax ; restore ax
@@DFwhileClause:
		cmp bx, ax
		jb @@DFwhile

		; bottom line
		add bp, 3

		call DrawFrameLine
		add bx, ScreenWidth * 2
		xor ah, ah
		mov al, cl
		shl ax, 1
		sub bx, ax

		call DrawFrameEmptyLine

		ret
		endp
;---------------------------------------

;--------------------------------------
; Draws one empty line of frame
; DrawFrameEmptyLine
; Entry:	bx = line beginning symbol addr
;		cl = width
;		ch = height
;		dh = color
;
; Assumes:	es = 0b800h
;
; Destr:	ax, dl
; Return:	bx = symbol after the last symbol in the line
;-------------------------------------

DrawFrameEmptyLine	proc

		mov dl, Space

		mov es:[bx], dx
		add bx, 2

		xor ax, ax
		mov al, cl
		sub al, 1
		shl ax, 1
		add ax, bx

		jmp @@DFLEwhileClause
@@DFLEwhile:
		mov es:[bx], dx
		add bx, 2

@@DFLEwhileClause:
		cmp bx, ax
		jb @@DFLEwhile

		ret
		endp
;--------------------------------------

;--------------------------------------
; Draws one line of fram (1 symbol + n symbols + 1 symbol)
; DrawDrameLine
; Entry:	bp = style str addr
;		bx = line beginning symbol addr
;		cl = width
;		ch = height
;		dh = color
;
; Assumes:	es = 0b800h
;		ds allows to reach style_str
;
; Destr:	ax, dl
; Return:	bx = symbol after the last symbol in the line
;-------------------------------------

DrawFrameLine	proc

		; write empty symbol
		mov dl, Space
		mov es:[bx], dx
		add bx, 2

		; write left symbol
		mov dl, [bp]
		mov es:[bx], dx
		add bx, 2

		mov dl, [bp + 1]


		xor ax, ax
		mov al, cl
		sub al, 2 * 2
		shl ax, 1
		add ax, bx

		jmp @@DFLwhileClause
@@DFLwhile:
		mov es:[bx], dx
		add bx, 2

@@DFLwhileClause:
		cmp bx, ax
		jb @@DFLwhile

		; write right symbol
		mov dl, [bp + 2]
		mov es:[bx], dx
		add bx, 2

		; write empty symbol
		mov dl, Space
		mov es:[bx], dx
		add bx, 2

		ret
		endp
;--------------------------------------

;--------------------------------------
; Draws shadow
; DrawShadow
; Entry:	cl = width
;		ch = height
;
; Assumes:	es = 0b800h
;
; Destr:	ax, bx
;--------------------------------------
DrawShadow	proc

		xor bh, bh
		mov bl, cl
		add bx, ScreenWidth * (FrameBegLine + 1) + FrameBegCol
		shl bx, 1

		mov ax, ScreenWidth * 2
		mul ch
		sub ax, ScreenWidth * 2
		add ax, bx

		jmp @@DSVwhileClause
@@DSVwhile:
		and byte ptr es:[bx + 1], ShadowAttrMask
		and byte ptr es:[bx + 3], ShadowAttrMask

		add bx, ScreenWidth * 2

@@DSVwhileClause:
		cmp bx, ax
		jb @@DSVwhile

		add bx, 2

		xor ah, ah
		mov al, cl
		shl ax, 1
		sub ax, bx
		neg ax

		jmp @@DSHwhileClause
@@DSHwhile:
		and byte ptr es:[bx + 1], ShadowAttrMask
		sub bx, 2

@@DSHwhileClause:
		cmp bx, ax
		ja @@DSHwhile

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
		add bx, 2

		jmp MCBAwhile
MCBAwhileEnd:

		ret
		endp
;--------------------------------------

include INTERF~1.ASM

;======================================
main:
		cld
		mov bp, sp

		mov bx, 0b800h
		mov es, bx ; videomem seg

		call MakeConsoleBrightAgain

		; locals:
		; [bp - 2]  = width_height
		; [bp - 4]  = color
		; [bp - 6]  = style
		; [bp - 8]  = header
		; [bp - 10] = text
		; [bp - 12] = header_len_text_len
		sub sp, 12

		mov bx, ArgvAddr

		lea ax, [bp - 2]
		push ax
		call GetWidthHeight
		add sp, 2
		cmp bx, -1
		je @@ErrNotEnoughArgs

		lea ax, [bp - 4]
		push ax
		call GetColor
		add sp, 2
		cmp bx, -1
		je @@ErrNotEnoughArgs

		lea ax, [bp - 6]
		push ax
		call GetStyle
		add sp, 2
		cmp bx, -1
		je @@ErrNotEnoughArgs

		lea ax, [bp - 12]
		push ax
		lea ax, [bp - 10]
		push ax
		lea ax, [bp - 8]
		push ax
		call GetText
		add sp, 6
		cmp bx, -1
		je @@ErrNotEnoughArgs

		push bp ; save bp
		mov cx, [bp - 2] ; width_height
		mov dh, [bp - 4] ; color attr
		push [bp - 6]
		pop bp		 ; style
		call DrawFrame
		pop bp ; restore bp

		call DrawShadow

		push [bp - 12]
		push [bp - 2]
		push [bp - 10]
		push [bp - 8]
		call PrintText
		add sp, 8

		jmp @@ProgramEnd

@@ErrNotEnoughArgs:
		; TODO err print
		mov ah, 09h
		mov dx, offset ErrNotEnoughArgsStr
		int 21h

@@ProgramEnd:	add sp, 12
		EOP

Styles 	db "/-\| |\-/"
	db 0dah, 0c4h, 0bfh, 0b3h, Space, 0b3h, 0c0h, 0c4h, 0d9h ; single frame
	db 0c9h, 0cdh, 0bbh, 0bah, Space, 0bah, 0c8h, 0cdh, 0bch ; double frame
	db 003h, 003h, 003h, 003h, Space, 003h, 003h, 003h, 003h ; hearts

ErrNotEnoughArgsStr db "Not enough arguments$"

FrameColorAttr	equ 4eh ; 01001110b


end		Start


; middle lines
		mov ax, [bp + 4]
		add ax, 3
		push ax

DFWhile:	inc dh
		mov bl, [bp + 7]
		add bl, FrameBegLine - 3
		cmp dh, bl
		ja DFWhileEnd

		call DrawFrameLine
		jmp DFWhile
DFWhileEnd:
		add sp, 2 ; [bp + 6] is used in next call

		; bottom line
		mov ax, [bp + 4]
		add ax, 6
		push ax
		call DrawFrameLine
		add sp, 2 ; [bp + 6] is used in next call
		inc dh

		; bottom empty line
		call DrawFrameEmptyLine
		add sp, 2
