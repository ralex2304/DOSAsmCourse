.model tiny
.286
.code
org 100h

include ..\macros.asm

Start:		jmp main

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
; Draws symbol
; Entry:	dh - line num
;		dl - col num
;		cl - symbol
;		ch - attr
; Assumes:	es = 0b800h
; Destr:	ax, bx
;--------------------------------------
DrawSymbol	proc

		mov al, dh
		mov bl, ScreenWidth
		mul bl	   ; ax = dh * ScreenWidth

		xor bx, bx
		mov bl, dl
		add ax, bx ; ax += dl (col num)

		shl ax, 1 ; ax *= 2

		mov bx, ax
		mov word ptr es:[bx], cx

		ret
		endp
;--------------------------------------

;--------------------------------------
; Draws symbol wirhout changing attributes
; Entry:	dh - line num
;		dl - col num
;		cl - symbol
; Assumes:	es = 0b800h
; Destr:	ax, bx
;--------------------------------------
ModSymbol	proc

		mov al, dh
		mov bl, ScreenWidth
		mul bl	   ; ax = dh * ScreenWidth

		xor bx, bx
		mov bl, dl
		add ax, bx ; ax += dl (col num)

		shl ax, 1 ; ax *= 2

		mov bx, ax
		mov byte ptr es:[bx], cl

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

		xor dh, dh
		add ax, dx ; ax += dl (col num)

		shl ax, 1 ; ax *= 2

		mov bx, ax
		inc bx ; attr address

		and byte ptr es:[bx], ch

		pop dx
		ret
		endp
;--------------------------------------

;--------------------------------------
; Draws frame (const byte* style_str, word width_height, byte color)
; Entry:
; Assumes:	es = 0b800h
; Destr:	ax, bx, cx, dx
;--------------------------------------
DrawFrame	proc

		push bp
		mov bp, sp

		; init attr
		mov ch, [bp + 8]

		mov dh, FrameBegLine

		; top empty line
		push [bp + 6]
		call DrawFrameEmptyLine
		; [bp + 6] is used in next call
		inc dh

		; top line
		push [bp + 4]
		call DrawFrameLine
		add sp, 2 ; [bp + 6] is used in next call

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

		pop bp
		ret
		endp
;---------------------------------------

;---------------------------------------
; Draws one line of fram (1 symbol + n symbols + 1 symbol)
; DrawDrameEmptyLine (word width)
;
; RegEntry:	ch = color attr
;		dh = line num
; Assumes:	es = 0b800h
;		ds allows to reach style_str
;
; Destr:	ax, bx, cl, dl
;--------------------------------------
DrawFrameEmptyLine	proc

		push bp
		mov bp, sp

		mov cl, Space
		mov dl, FrameBegCol

		; while (dl++ < FrameWidth + FrameBegCol - 1):
		; 	DrawSymbol()
DFLEwhile:	mov al, [bp + 4]
		add al, FrameBegCol - 1
		cmp dl, al
		ja DFLEwhileEnd

		call DrawSymbol

		inc dl
		jmp DFLEwhile
DFLEwhileEnd:

		pop bp
		ret
		endp

;--------------------------------------

;--------------------------------------
; Draws one line of fram (1 symbol + n symbols + 1 symbol)
; DrawDrameLine (const byte* style_str, word width_height)
;
; RegEntry:	ch = color attr
; Assumes:	es = 0b800h
;		ds allows to reach style_str
;
; Destr:	ax, bx, cl, dl
;-------------------------------------

DrawFrameLine	proc

		push bp
		mov bp, sp

		; write empty symbol
		mov dl, FrameBegCol
		mov cl, Space
		call DrawSymbol

		; write left symbol
		inc dl
		mov bx, [bp + 4]
		mov cl, [bx]
		call DrawSymbol

		; write middle symbols
		mov bx, [bp + 4]
		mov cl, [bx + 1]

		; while (dl++ < FrameWidth - 4 + (FrameBegCol + 1)):
		; 	DrawSymbol()
DFLwhile:	inc dl
		mov al, [bp + 6]
		add al, (FrameBegCol + 1) - 4
		cmp dl, al
		ja DFLwhileEnd

		call DrawSymbol

		jmp DFLWhile
DFLwhileEnd:
		; write right symbol
		mov bx, [bp + 4]
		mov cl, [bx + 2]
		call DrawSymbol

		; write empty symbol
		inc dl
		mov cl, Space
		call DrawSymbol

		pop bp
		ret
		endp

;--------------------------------------

;--------------------------------------
; Draws shadow
; DrawShadow (word width_height)
; Entry:
; Assumes:	es = 0b800h
;
; Destr: ax, bx, cx, dx
;--------------------------------------
DrawShadow	proc

		push bp
		mov bp, sp

		mov ch, ShadowAttrMask
		mov dh, FrameBegLine + 1
		mov dl, FrameBegCol
		add dl, [bp + 4]

		mov cl, FrameBegLine
		add cl, [bp + 5] ; FrameHeight
DSvertWhile:	cmp dh, cl
		ja DSvertWhileEnd

		call ModSymbolAttr
		inc dl
		call ModSymbolAttr
		dec dl

		inc dh
		jmp DSvertWhile
DSvertWhileEnd:
		dec dh

DShorWhile:	cmp dl, FrameBegCol + 2 ; 2 symbols margin
		jb DShorWhileEnd

		call ModSymbolAttr
		dec dl
		jmp DShorWhile
DShorWhileEnd:

		pop bp
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

;--------------------------------------
; Checks if argc is exceeded
;
; Entry:	bx = current symbol in argv
; Effect:	bx = -1 if argc is exceeded
; Destr:	ax
;--------------------------------------
CheckArgc	proc

		mov ax, ds:[ArgcAddr]
		add ax, ArgvAddr
		cmp bx, ax
		jb @@CheckOK

		mov bx, -1
@@CheckOK:
		ret
		endp


;--------------------------------------

;--------------------------------------
; Skips spaces in argv. Also stops and puts bx to -1 if argc is exceeded
;
; Entry:	bx = current symbol in argv
; Assumes:
; Effect:	bx - moves it to next non space symbol
; Destr:	ax
;--------------------------------------
SkipSpaces 	proc

@@while:	cmp byte ptr [bx], Space
		jne @@endwhile

		inc bx

		call CheckArgc
		cmp bx, -1
		jne @@while
@@endwhile:
		ret
		endp
;--------------------------------------

;--------------------------------------
; Gets decimal number into cl from argv
; Entry:	bx = current symbol in argv
; Assumes:
; Effect:	bx - moves it to the symbol after number
;		cl - returns number
;
; Destr:	ax, cl
;--------------------------------------
GetDecimalNumber proc

		call SkipSpaces
		cmp bx, -1
		je @@GetDecEnd

		mov cl, [bx]
		sub cl, '0'
		inc bx

		cmp byte ptr [bx], Space
		je @@GetDecEnd
		cmp byte ptr [bx], NewLine
		je @@GetDecEnd

		call CheckArgc
		cmp bx, -1
		je @@GetDecEnd

		mov al, 10
		mul cl
		mov cl, al

		mov cl, [bx]
		sub al, '0'
		add cl, al

		inc bx
@@GetDecEnd:
		ret
		endp
;--------------------------------------

;--------------------------------------
; Gets hex number into cl from argv
; Entry:	bx = current symbol in argv
; Assumes:
; Effect:	bx - moves it to the symbol after number
;		cl - returns number
;
; Destr:	ax, cl
;--------------------------------------
GetHexNumber proc

		call SkipSpaces
		cmp bx, -1
		je @@GetHexEnd

		mov al, [bx]
		call ConvertHexDigit
		mov cl, al
		inc bx

		cmp byte ptr [bx], Space
		je @@GetHexEnd
		cmp byte ptr [bx], NewLine
		je @@GetHexEnd

		call CheckArgc
		cmp bx, -1
		je @@GetHexEnd

		shl cl, 4

		mov al, [bx]
		call ConvertHexDigit
		add cl, al

		inc bx
@@GetHexEnd:
		ret
		endp
;--------------------------------------

;--------------------------------------
; Converts hex digit in al
; Entry:	al - symbol
; Assumes:
; Effect:	al - number
;
; Destr:
;--------------------------------------
ConvertHexDigit proc

		; if ('0' <= al && al <= '9')
		cmp al, '0'
		jb @@CHDelseif
		cmp al, '9'
		ja @@CHDelseif

		sub al, '0'
		jmp @@CHDendif
@@CHDelseif:
		; else if ('a' <= al && al <= 'f')
		cmp al, 'a'
		jb @@CHDelse
		cmp al, 'f'
		ja @@CHDelse

		sub al, 'a' - 10
		jmp @@CHDendif
@@CHDelse:
		sub al, 'A' - 10
@@CHDendif:
		ret
		endp
;--------------------------------------

;--------------------------------------
; Gets width and height from argv
; GetWidthHeight(word* width_height)
; Entry:	bx = current symbol in argv
; Assumes:
; Effect:	bx - moves it to next token
; Destr:	ax, cl
;--------------------------------------
GetWidthHeight	proc

		push bp
		mov bp, sp

		call GetDecimalNumber
		cmp bx, -1
		je @@FuncEnd

		push bx
		mov bx, [bp + 4]
		mov byte ptr [bx], cl
		pop bx

		call GetDecimalNumber
		cmp bx, -1
		je @@FuncEnd

		push bx
		mov bx, [bp + 4]
		mov byte ptr [bx + 1], cl
		pop bx

@@FuncEnd:	pop bp
		ret
		endp
;--------------------------------------

;--------------------------------------
; Gets frame style from argv
; GetStyle(char* style)
; Entry:	bx = current symbol in argv
; Assumes:
; Effect:	bx - moves it to next token
; Destr:	ax, cx, dx
;--------------------------------------
GetStyle	proc

		push bp
		mov bp, sp

		call SkipSpaces
		cmp bx, -1
		je @@GetStyleEnd

		cmp byte ptr [bx], '*'
		jne @@DefinedStyle

		inc bx
		call CheckArgc
		cmp bx, -1
		je @@GetStyleEnd

		mov cx, bx
		add bx, 9

		jmp @@WriteStyle

@@DefinedStyle:
		mov al, 9
		mov ah, [bx]
		sub ah, '0'
		mul ah

		inc bx

		mov cx, offset Styles
		add cx, ax

@@WriteStyle:
		push bx
		mov bx, [bp + 4]
		mov word ptr [bx], cx
		pop bx

@@GetStyleEnd:	pop bp
		ret
		endp
;--------------------------------------

;--------------------------------------
; Gets text from argv
; GetText(byte* text, byte* text_len)
; Entry:	bx = current symbol in argv
; Assumes:
; Effect:
; Destr:	ax, bx
;--------------------------------------
GetText	proc

		push bp
		mov bp, sp

		call SkipSpaces
		cmp bx, -1
		je @@GetTextEnd

		push bx
		sub bx, ArgvAddr
		mov al, ds:[ArgcAddr]
		sub al, bl

		mov bx, [bp + 6]
		xor ah, ah
		mov word ptr [bx], ax

		pop bx
		mov ax, bx
		mov bx, [bp + 4]
		mov word ptr [bx], ax

@@GetTextEnd:	pop bp
		ret
		endp
;--------------------------------------

;--------------------------------------
; Prints text
; GetText(byte* text, word width_height, byte text_len)
; Entry:
; Assumes:	es = 0b800h
; Effect:
; Destr:	ax, bx, cx, dx
;--------------------------------------
PrintText	proc

		push bp
		mov bp, sp

		; dh - line num
		; dl - col num

		mov dh, [bp + 7]
		shr dh, 1
		add dh, FrameBegLine

		mov ch, [bp + 8]
		mov dl, [bp + 6]
		sub dl, ch
		shr dl, 1
		add dl, FrameBegCol

		mov bx, [bp + 4]

		add ch, dl

@@printchar:	cmp dl, ch
		jae @@endprint

		push bx
		mov cl, [bx]
		call ModSymbol
		pop bx

		inc dl
		inc bx

		jmp @@printchar

@@endprint:
		pop bp
		ret
		endp
;--------------------------------------


;--------------------------------------
; Gets hex color from argv
; GetColor(byte* color)
; Entry:	bx = current symbol in argv
; Assumes:
; Effect:	bx - moves it to next token
; Destr:	ax
;--------------------------------------
GetColor	proc

		push bp
		mov bp, sp

		call SkipSpaces
		cmp bx, -1
		je @@GetColorEnd

		call GetHexNumber

		push bx
		mov bx, [bp + 4]
		mov byte ptr [bx], cl
		pop bx

@@GetColorEnd:	pop bp
		ret
		endp
;--------------------------------------

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
		; [bp - 8]  = text
		; [bp - 10] = text len
		sub sp, 10

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

		lea ax, [bp - 10]
		push ax
		lea ax, [bp - 8]
		push ax
		call GetText
		add sp, 4
		cmp bx, -1
		je @@ErrNotEnoughArgs

		push [bp - 4]
		push [bp - 2]
		push [bp - 6]
		call DrawFrame
		add sp, 6

		push [bp - 2]
		call DrawShadow
		add sp, 2

		push [bp - 10]
		push [bp - 2]
		push [bp - 8]
		call PrintText
		add sp, 6

		jmp @@ProgramEnd

@@ErrNotEnoughArgs:
		; TODO err print


@@ProgramEnd:	add sp, 10
		EOP

Styles 	db "/-\| |\-/"
	db 0dah, 0c4h, 0bfh, 0b3h, Space, 0b3h, 0c0h, 0c4h, 0d9h ; single frame
	db 0c9h, 0cdh, 0bbh, 0bah, Space, 0bah, 0c8h, 0cdh, 0bch ; double frame
	db 003h, 003h, 003h, 003h, Space, 003h, 003h, 003h, 003h ; hearts


FrameColorAttr	equ 4eh ; 01001110b


end		Start
