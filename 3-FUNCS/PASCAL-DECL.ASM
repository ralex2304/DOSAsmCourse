.model tiny
.286
.code
org 100h
locals @@

include ..\macros.asm

Start:		jmp main

StringSrc  db "1234567890"
StringDest db "abcdefghji"

;--------------------------------------
; Copies n bytes of src to dest
;
; byte* pascal mymemcpypascal(byte* dest, const byte* src, word n)
; 	return dest;
;
; Assumes:
;
; Destr: ax, cx, es, si
;--------------------------------------

mymemcpypascal	proc

		push bp
		mov bp, sp

		mov ax, ds
		mov es, ax 	 ; es = ds

		mov di, [bp + 8] ; di = offset dest

		mov si, [bp + 6] ; si = offset src
		mov cx, [bp + 4] ; cx = n
		rep movsb

		mov ax, [bp + 8]

		pop bp
		ret 6
		endp
;--------------------------------------

;--------------------------------------
; Copies n bytes of src to dest. Also handles overlay
;
; byte* pascal mymemmovepascal(byte* dest, const byte* src, word n)
; 	return dest;
;
; Assumes:
;
; Destr: ax, cx, es, si
;--------------------------------------

mymemmovepascal	proc

		push bp
		mov bp, sp

		mov ax, ds
		mov es, ax 	 ; es = ds

		mov di, [bp + 8] ; di = offset dest

		mov si, [bp + 6] ; si = offset src
		mov cx, [bp + 4] ; cx = n

		; if (src < dest && dest < src + n)
		cmp si, di
		jae @@else

		mov ax, si
		add ax, cx
		cmp di, ax
		jae @@else

		add di, cx ; di += n - 1
		dec di
		add si, cx ; si += n - 1
		dec si
		std
		rep movsb
		cld
		jmp @@endif

@@else:		rep movsb
@@endif:

		mov ax, [bp + 8]

		pop bp
		ret 6
		endp
;--------------------------------------

;--------------------------------------
; Compares n bytes
;
; word pascal mymemcmppascal(const byte* buf1, const byte* buf2, word n)
; 	return ax;
;
; Assumes:
;
; Destr: ax, cx, es
;--------------------------------------

mymemcmppascal	proc

		push bp
		mov bp, sp

		mov ax, ds
		mov es, ax 	 ; es = ds
		mov di, [bp + 8] ; di = offset buf1
		mov si, [bp + 6] ; si = offset buf2
		mov cx, [bp + 4] ; cx = n

		repe CMPSB

		xor al, al
		mov ah, es:[di - 1]
		sub ah, ds:[si - 1]

		pop bp
		ret 6
		endp
;--------------------------------------

;======================================
main:
		cld


		push offset String1
		push offset String2
		push 4
		call mymemcmppascal

		EOP

String1 db "abcde"
String2 db "abcee"

end		Start
