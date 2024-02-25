.286
.model tiny
.code
org 100h
locals @@

Start:		jmp main

ScreenWidth	equ 80
ScreenHeight	equ 26

RegsNum		equ 7 			; regs list config
RegsNames 	db "axbxcxdxspbpes"
RegsPush	equ es bp sp dx cx bx ax

F12pushKeycode		equ 58h
F12releaseKeycode	equ F12pushKeycode + 128

HotKeyOpenKeycode 	equ 57h
HotKeyCloseKeycode 	equ 58h

TimerPeriod	equ 2

Space		equ ' '

FrameBegLine	equ 8
FrameBegCol	equ 67

FrameHeight	equ RegsNum + 4
FrameWidth	equ 12

FrameSize	equ FrameHeight * FrameWidth

;--------------------------------------
; Draws frame
;
; Assumes:	es = 0b800h
; Destr:	ax, bx, cx, dx, si, bp
;--------------------------------------
DrawFrame	proc

		mov bp, offset FrameStyle
		mov dh, 4eh ; color
		mov si, offset MemBuffer

		mov bx, (FrameBegLine * ScreenWidth + FrameBegCol) * 2
		; bx => x = 0; y = 0

		call DrawFrameEmptyLine
		add bx, (ScreenWidth - FrameWidth) * 2

		; top line
		call DrawFrameLine
		add bx, (ScreenWidth - FrameWidth) * 2


		; middle lines
		add bp, 3

		mov ax, (ScreenWidth * FrameHeight) * 2 - (4 * ScreenWidth) * 2
		add ax, bx

		jmp @@DFwhileClause
@@DFwhile:
		push ax ; save ax
		call DrawFrameLine
		add bx, (ScreenWidth - FrameWidth) * 2

		pop ax ; restore ax
@@DFwhileClause:
		cmp bx, ax
		jb @@DFwhile

		; bottom line
		add bp, 3

		call DrawFrameLine
		add bx, (ScreenWidth - FrameWidth) * 2

		call DrawFrameEmptyLine


		; print regs names
		mov bp, (ScreenWidth * (FrameBegLine + 2) + (FrameBegCol + 2)) * 2
		mov si, offset MemBuffer + FrameSize * 2 + (FrameWidth * 2 + 2) * 2

		mov bx, 0
		jmp @@DFforClause
@@DFforBegin:
		mov cl, cs:[offset RegsNames + bx]
		mov byte ptr es:[bp], cl
		mov byte ptr cs:[si], cl
		add bp, 2
		add si, 2

		mov cl, cs:[offset RegsNames + bx + 1]
		mov byte ptr es:[bp], cl
		mov byte ptr cs:[si], cl

		add bp, (ScreenWidth - 1) * 2
		add si, (FrameWidth - 2 + 1) * 2

		add bx, 2
@@DFforClause:
		cmp bx, RegsNum * 2
		jb @@DFforBegin

		ret
		endp
;---------------------------------------

;--------------------------------------
; Draws one empty line of frame
; DrawFrameEmptyLine
; Entry:	bx = line beginning symbol addr
;		si = position in mem buf
;		dh = color
;
; Assumes:	es = 0b800h
;
; Destr:	ax, cx, dl
; Return:	bx = symbol after the last symbol in the line
;		si = symbol after the last symbol in mem buf
;-------------------------------------

DrawFrameEmptyLine	proc

		mov dl, Space

		mov ax, FrameWidth * 2
		add ax, bx

		jmp @@DFLEwhileClause
@@DFLEwhile:
		mov cx, es:[bx]
		mov cs:[si], cx

		mov es:[bx], dx
		mov cs:[si + FrameSize * 2], dx
		add bx, 2
		add si, 2

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
;		si = position in mem buf
;		dh = color
;
; Assumes:	es = 0b800h
;		ds allows to reach style_str
;
; Destr:	ax, cx, dl
; Return:	bx = symbol after the last symbol in the line
;		si = symbol after the last symbol in mem buf
;-------------------------------------

DrawFrameLine	proc

		; write empty symbol
		mov dl, Space
		mov cx, es:[bx]
		mov cs:[si], cx
		mov es:[bx], dx
		mov cs:[si + FrameSize * 2], dx
		add bx, 2
		add si, 2

		; write left symbol
		mov dl, cs:[bp]
		mov cx, es:[bx]
		mov cs:[si], cx
		mov es:[bx], dx
		mov cs:[si + FrameSize * 2], dx
		add bx, 2
		add si, 2

		mov dl, cs:[bp + 1]

		mov ax, (FrameWidth - 2 * 2) * 2
		add ax, bx

		jmp @@DFLwhileClause
@@DFLwhile:
		mov cx, es:[bx]
		mov cs:[si], cx
		mov es:[bx], dx
		mov cs:[si + FrameSize * 2], dx
		add bx, 2
		add si, 2

@@DFLwhileClause:
		cmp bx, ax
		jb @@DFLwhile

		; write right symbol
		mov dl, cs:[bp + 2]
		mov cx, es:[bx]
		mov cs:[si], cx
		mov es:[bx], dx
		mov cs:[si + FrameSize * 2], dx
		add bx, 2
		add si, 2

		; write empty symbol
		mov dl, Space
		mov cx, es:[bx]
		mov cs:[si], cx
		mov es:[bx], dx
		mov cs:[si + FrameSize * 2], dx
		add bx, 2
		add si, 2

		ret
		endp
;--------------------------------------

;--------------------------------------
; Restores data from buf to videomem
;
; Assumes:	es = 0b800h
; Destr:	ax, bx, cx, dx, si
;--------------------------------------
RestoreFromBuf	proc

		mov si, offset MemBuffer

		mov bx, (FrameBegLine * ScreenWidth + FrameBegCol) * 2

		mov ax, FrameHeight
		jmp @@RFBforLinesClause
@@RFBforLinesBegin:

		mov cx, FrameWidth
		jmp @@RFBforColsClause
@@RFBforColsBegin:

		mov dx, cs:[si]
		mov es:[bx], dx

		add bx, 2
		add si, 2

		dec cx
@@RFBforColsClause:
		cmp cx, 0
		ja @@RFBforColsBegin

		add bx, (ScreenWidth - FrameWidth) * 2

		dec ax
@@RFBforLinesClause:
		cmp ax, 0
		ja @@RFBforLinesBegin

		ret
		endp
;---------------------------------------

;--------------------------------------
; Check if something has changed frame
;
; Assumes:	es = 0b800h
; Destr:	ax, bx, cx, dx, si
;--------------------------------------
CheckIfChanged	proc

		mov si, offset MemBuffer

		mov bx, (FrameBegLine * ScreenWidth + FrameBegCol) * 2

		mov ax, FrameHeight
		jmp @@CICforLinesClause
@@CICforLinesBegin:

		mov cx, FrameWidth
		jmp @@CICforColsClause
@@CICforColsBegin:

		mov dx, es:[bx]
		cmp cs:[FrameSize * 2 + si], dx
		je @@CICnothingChanged

		mov cs:[si], dx
		mov dx, cs:[FrameSize * 2 + si]
		mov es:[bx], dx

@@CICnothingChanged:
		add bx, 2
		add si, 2

		dec cx
@@CICforColsClause:
		cmp cx, 0
		ja @@CICforColsBegin

		add bx, (ScreenWidth - FrameWidth) * 2

		dec ax
@@CICforLinesClause:
		cmp ax, 0
		ja @@CICforLinesBegin

		ret
		endp
;---------------------------------------

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

		cmp cs:PopupCnt, 1
		jne @@IO08isAlreadyInit

		push ax bx cx dx si es bp

		push 0b800h
		pop es

		call DrawFrame

		pop bp es si dx cx bx ax

@@IO08isAlreadyInit:
		inc cs:PopupCnt
		cmp cs:PopupCnt, TimerPeriod
		jb @@IO08noneLong

		mov cs:PopupCnt, 2

		push ax bx cx dx si es bp
		push RegsPush

		push 0b800h
		pop es

		call CheckIfChanged

		; printing regs values
		mov bp, (ScreenWidth * (FrameBegLine + 2) + (FrameBegCol + 2) + 3) * 2
		mov si, offset MemBuffer + FrameSize * 2 + (FrameWidth * 2 + 5) * 2

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
		mov byte ptr cs:[si], bl
		add bp, 2
		add si, 2

		mov bx, ax
		and bx, 00f00h
		shr bx, 16 - 8
		mov bl, cs:[offset HexTable + bx]
		mov byte ptr es:[bp], bl
		mov byte ptr cs:[si], bl
		add bp, 2
		add si, 2

		mov byte ptr es:[bp], ':'
		mov byte ptr cs:[si], ':'
		add bp, 2
		add si, 2

		mov bx, ax
		and bx, 000f0h
		shr bx, 16 - 12
		mov bl, cs:[offset HexTable + bx]
		mov byte ptr es:[bp], bl
		mov byte ptr cs:[si], bl
		add bp, 2
		add si, 2

		mov bx, ax
		and bx, 0000fh
		;shr bx, 16 - 16
		mov bl, cs:[offset HexTable + bx]
		mov byte ptr es:[bp], bl
		mov byte ptr cs:[si], bl

		add bp, (ScreenWidth - 4) * 2
		add si, (FrameWidth - 5 + 1) * 2

@@IO08forClause:
		cmp cx, 0
		ja @@IO08forBegin

		pop bp es si dx cx bx ax
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

		jmp @@IO09endif

@@IO09elseif:	cmp al, HotKeyCloseKeycode
		jne @@IO09endif

		mov cs:PopupCnt, 0

		push bx cx dx es si
		push 0b800h
		pop es
		call RestoreFromBuf
		pop si es dx cx bx
@@IO09endif:
		pop ax

		db 0eah ; far jmp
Old09Offs	dw 0
Old09Seg	dw 0

		endp


PopupCnt	db 0 ; 0 - off; 1 - on; >= 2 - on and has already been drawn

FrameStyle 	db 0dah, 0c4h, 0bfh, 0b3h, Space, 0b3h, 0c0h, 0c4h, 0d9h ; single frame

HexTable	db "0123456789ABCDEF"

MemBuffer	dw (FrameWidth * FrameHeight * 2) dup(0) ; first  half - old values
							 ; second half - actual

EndOfProg:

end		Start
