;--------------------------------------
; Checks if argc is exceeded
;
; Entry:	bx = current symbol in argv
; Effect:	bx = -1 if argc is exceeded
; Destr:	ax
;--------------------------------------
CheckArgc	proc

		; bx < *argc + argv
		xor ah, ah
		mov al, ds:[ArgcAddr]
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
		call CheckArgc
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
		call CheckArgc
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
		call CheckArgc
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
; GetText(byte* header, byte* text, word* header_len_text_len)
; Entry:	bx = current symbol in argv
; Assumes:
; Effect:
; Destr:	ax, bx, dx
;--------------------------------------
GetText	proc

		push bp
		mov bp, sp

		call SkipSpaces
		cmp bx, -1
		je @@GetTextEnd

		push bx
		mov ax, bx
		mov bx, [bp + 4]
		mov word ptr [bx], ax
		pop bx

		push bx
		sub bx, ArgvAddr
		mov dl, ds:[ArgcAddr]
		sub dl, bl ; dl = len(header + ':' + text)
		pop bx

		push es
		xor dh, dh
		push dx
		push ':'
		push bx
		call mymemchr
		add sp, 6
		pop es


		cmp ax, 0
		je @@NoText

		; cnt len
		mov cx, ax
		sub cx, bx ; cx = len(header)

		mov bx, ax
		inc bx

		push bx
		mov bx, [bp + 8]
		mov byte ptr [bx], cl

		sub dl, cl
		dec dl ; dl = len(text)

		mov bx, [bp + 8]
		mov byte ptr [bx + 1], dl
		pop bx

		push bx
		mov ax, bx
		mov bx, [bp + 6]
		mov word ptr [bx], ax
		pop bx

		jmp @@GetTextEnd
@@NoText:

		push bx
		mov bx, [bp + 8]
		xor dh, dh
		mov word ptr [bx], dx

		mov bx, [bp + 6]
		mov word ptr [bx], 0

		pop bx


@@GetTextEnd:	pop bp
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
; Entry:	dl = col num
;		dh = line num
;		ch = line end ptr
;		bx = str
;
; Destr:	cl, dl, bx
;--------------------------------------
PrintLine	proc

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
		ret
		endp

;--------------------------------------

;--------------------------------------
; Prints text
; GetText(byte* header, byte* text, word width_height, word header_len_text_len)
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

		mov dh, FrameBegLine + 1

		mov ch, [bp + 10] ; ch = header_len
		mov dl, [bp + 8]
		sub dl, ch
		shr dl, 1
		add dl, FrameBegCol

		mov bx, [bp + 4]  ; bx = header

		add ch, dl        ; ch = header_len + col_num

		call PrintLine    ; header


		mov ch, [bp + 11] ; ch = text_len

		cmp ch, 0
		je @@PrintNoText

		mov dl, [bp + 8]
		sub dl, ch
		shr dl, 1
		add dl, FrameBegCol

		mov dh, [bp + 9]
		shr dh, 1
		add dh, FrameBegLine

		mov bx, [bp + 6]  ; bx = text

		add ch, dl        ; ch = text_len + col_num

		call PrintLine    ; text

@@PrintNoText:	pop bp
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
		call CheckArgc
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
