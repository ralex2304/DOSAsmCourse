.286
.model tiny
.code
org 100h
locals @@

ScreenWidth	equ 80
ScreenHeight	equ 26

Space		equ ' '

FrameBegLine	equ 8
FrameBegCol	equ 69

FrameHeight	equ 10
FrameWidth	equ 10


Start:		jmp main

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
		mov dl, cs:[bp]
		mov es:[bx], dx
		add bx, 2

		mov dl, cs:[bp + 1]


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
		mov dl, cs:[bp + 2]
		mov es:[bx], dx
		add bx, 2

		; write empty symbol
		mov dl, Space
		mov es:[bx], dx
		add bx, 2

		ret
		endp
;--------------------------------------

main:		push 0
		pop es

		mov ax, 3509h
		int 21h		; get int vector addr: es:bx

		mov Old09Offs, bx
		mov bx, es
		mov Old09Seg, bx

		push ds ; save ds
		mov dx, offset IntOverride09
		push cs
		pop ds
		mov ax, 2509h
		int 21h		; set int vector addr: ds: dx
		pop ds ; restore ds

		mov dx, offset EndOfProg
		shr dx, 4
		inc dx 		; sizeof(prog) / 16 + 1
		mov ax, 3100h
		int 21h

IntOverride09	proc
		push ax bx cx dx es bp

		push 0b800h
		pop es

		push offset FrameStyle
		pop bp
		mov cx, FrameHeight * 100h + FrameWidth
		mov dh, 4eh	; color
		call DrawFrame

		pop bp es dx cx bx ax

		db 0eah ; far jmp
Old09Offs	dw 0
Old09Seg	dw 0

		endp

FrameStyle db 0dah, 0c4h, 0bfh, 0b3h, Space, 0b3h, 0c0h, 0c4h, 0d9h ; single frame

EndOfProg:

end		Start

