.286
.model tiny
.code
org 100h
locals @@

Start:		jmp main

ScreenWidth	equ 80
ScreenHeight	equ 26

RegsNum		equ 5 			; regs list config
RegsNames 	db "axbxcxdxsp"
RegsPush	equ sp dx cx bx ax

F12pushKeycode		equ 58h
F12releaseKeycode	equ F12pushKeycode + 128

HotKeyOpenKeycode 	equ F12pushKeycode
HotKeyCloseKeycode 	equ F12releaseKeycode

Space		equ ' '

FrameBegLine	equ 8
FrameBegCol	equ 67

FrameHeight	equ RegsNum + 4
FrameWidth	equ 12

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

main:		; timer - IRQ0
		mov ax, 3508h
		int 21h		; get int vector addr in es:bx

		mov Old08Offs, bx
		mov bx, es
		mov Old08Seg, bx

		push ds ; save ds
		mov dx, offset IntOverride08
		push cs
		pop ds
		mov ax, 2508h
		int 21h		; set int vector addr from ds: dx
		pop ds ; restore ds

		; keybord - IRQ1
		mov ax, 3509h
		int 21h		; get int vector addr in es:bx

		mov Old09Offs, bx
		mov bx, es
		mov Old09Seg, bx

		push ds ; save ds
		mov dx, offset IntOverride09
		push cs
		pop ds
		mov ax, 2509h
		int 21h		; set int vector addr from ds: dx
		pop ds ; restore ds

		; stay resident
		mov dx, offset EndOfProg
		shr dx, 4
		inc dx 		; sizeof(prog) / 16 + 1
		mov ax, 3100h
		int 21h

IntOverride08	proc

		cmp cs:PopupCnt, 0
		je @@IO08noneLong

		inc cs:PopupCnt
		cmp cs:PopupCnt, 5
		jb @@IO08noneLong

		mov cs:PopupCnt, 1

		push ax bx cx dx es bp
		push RegsPush

		push 0b800h
		pop es

		mov bp, (ScreenWidth * (FrameBegLine + 2) + (FrameBegCol + 2) + 3) * 2

		; printing

		mov cx, RegsNum
		jmp @@IO08forClause

@@IO08noneLong: jmp @@IO08none

@@IO08forBegin: dec cx
		pop ax

		mov bx, ax
		;and bx, 0f000h
		shr bx, 16 - 4
		mov bl, cs:[offset HexTable + bx]
		mov byte ptr es:[bp], bl
		add bp, 2

		mov bx, ax
		and bx, 00f00h
		shr bx, 16 - 8
		mov bl, cs:[offset HexTable + bx]
		mov byte ptr es:[bp], bl
		add bp, 2

		mov byte ptr es:[bp], ':'
		add bp, 2

		mov bx, ax
		and bx, 000f0h
		shr bx, 16 - 12
		mov bl, cs:[offset HexTable + bx]
		mov byte ptr es:[bp], bl
		add bp, 2

		mov bx, ax
		and bx, 0000fh
		;shr bx, 16 - 16
		mov bl, cs:[offset HexTable + bx]
		mov byte ptr es:[bp], bl

		add bp, (ScreenWidth - 4) * 2

@@IO08forClause:
		cmp cx, 0
		ja @@IO08forBegin

		pop bp es dx cx bx ax
@@IO08none:
		db 0eah ; far jmp
Old08Offs	dw 0
Old08Seg	dw 0

		endp


IntOverride09	proc

		push ax

		in al, 60h
		cmp al, HotKeyOpenKeycode
		jne @@IO09elseif

		cmp cs:PopupCnt, 0
		jne @@IO09endif

		; enable frame and draw it
		mov cs:PopupCnt, 1

		push bx cx dx es bp

		push 0b800h
		pop es

		push offset FrameStyle
		pop bp
		mov cx, FrameHeight * 100h + FrameWidth
		mov dh, 4eh	; color
		call DrawFrame


		mov bp, (ScreenWidth * (FrameBegLine + 2) + (FrameBegCol + 2)) * 2

		mov bx, 0
		jmp @@IO09forClause
@@IO09forBegin:
		mov cl, cs:[offset RegsNames + bx]
		mov byte ptr es:[bp], cl
		add bp, 2

		mov cl, cs:[offset RegsNames + bx + 1]
		mov byte ptr es:[bp], cl

		add bp, (ScreenWidth - 1) * 2

		add bx, 2
@@IO09forClause:
		cmp bx, RegsNum * 2
		jb @@IO09forBegin

		pop bp es dx cx bx

		jmp @@IO09endif

@@IO09elseif:	cmp al, HotKeyCloseKeycode
		jne @@IO09endif

		mov cs:PopupCnt, 0
@@IO09endif:
		pop ax

		db 0eah ; far jmp
Old09Offs	dw 0
Old09Seg	dw 0

		endp


PopupCnt	db 0 ; 0 - off; >0 - on

FrameStyle 	db 0dah, 0c4h, 0bfh, 0b3h, Space, 0b3h, 0c0h, 0c4h, 0d9h ; single frame

HexTable	db "0123456789ABCDEF"

EndOfProg:

end		Start
