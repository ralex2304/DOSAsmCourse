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
; Counts string length
;
; word cdecl mystrlen(const byte* s)
; 	return ax;
;
; Assumes:
;
; Destr: ax, cx, es
;--------------------------------------

mystrlen	proc

		push bp
		mov bp, sp

		mov ax, ds
		mov es, ax 	 ; es = ds
		mov di, [bp + 4] ; di = offset s

		mov cx, -1
		mov al, '$'
		repne scasb

		neg cx
		sub cx, 2
		mov ax, cx

		pop bp
		ret
		endp
;--------------------------------------

;--------------------------------------
; Finds byte
;
; byte* cdecl mymemchr(const byte* s, byte c, word n)
; 	return es:ax;
;
; Assumes:
;
; Destr: ax, cx, es
;--------------------------------------

mymemchr	proc

		push bp
		mov bp, sp

		mov ax, ds
		mov es, ax 	 ; es = ds


		mov di, [bp + 4] ; di = offset s


		mov al, [bp + 6] ; al = c
		mov cx, [bp + 8]
		inc cx		 ; cx = n + 1
		repne scasb

		cmp cx, 0
		jne @@IsFound
		mov ax, 0
		jmp @@IsNotFound
@@IsFound:
		lea ax, [di - 1]
@@IsNotFound:

		pop bp
		ret
		endp
;--------------------------------------

;--------------------------------------
; Sets n bytes of memory with c
;
; byte* cdecl mymemset(const byte* p, byte c, word n)
; 	return p;
;
; Assumes:
;
; Destr: ax, cx, es
;--------------------------------------

mymemset	proc

		push bp
		mov bp, sp

		mov ax, ds
		mov es, ax 	 ; es = ds

		mov di, [bp + 4] ; di = offset s

		mov al, [bp + 6] ; al = c
		mov cx, [bp + 8] ; cx = n
		rep stosb

		mov ax, [bp + 4]

		pop bp
		ret
		endp
;--------------------------------------

;--------------------------------------
; Copies n bytes of src to dest
;
; byte* cdecl mymemcpy(byte* dest, const byte* src, word n)
; 	return dest;
;
; Assumes:
;
; Destr: ax, cx, es, si
;--------------------------------------

mymemcpy	proc

		push bp
		mov bp, sp

		mov ax, ds
		mov es, ax 	 ; es = ds

		mov di, [bp + 4] ; di = offset dest

		mov si, [bp + 6] ; si = offset src
		mov cx, [bp + 8] ; cx = n
		rep movsb

		mov ax, [bp + 4]

		pop bp
		ret
		endp
;--------------------------------------

;--------------------------------------
; Copies n bytes of src to dest. Also handles overlay
;
; byte* cdecl mymemmove(byte* dest, const byte* src, word n)
; 	return dest;
;
; Assumes:
;
; Destr: ax, cx, es, si
;--------------------------------------

mymemmove	proc

		push bp
		mov bp, sp

		mov ax, ds
		mov es, ax 	 ; es = ds

		mov di, [bp + 4] ; di = offset dest

		mov si, [bp + 6] ; si = offset src
		mov cx, [bp + 8] ; cx = n

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

		mov ax, [bp + 4]

		pop bp
		ret
		endp
;--------------------------------------

;--------------------------------------
; Compares n bytes
;
; word cdecl mymemcmp(const byte* buf1, const byte* buf2, word n)
; 	return ax;
;
; Assumes:
;
; Destr: ax, cx, es
;--------------------------------------

mymemcmp	proc

		push bp
		mov bp, sp

		mov ax, ds
		mov es, ax 	 ; es = ds
		mov di, [bp + 4] ; di = offset buf1
		mov si, [bp + 6] ; si = offset buf2
		mov cx, [bp + 8] ; cx = n

		repe CMPSB

		xor al, al
		mov ah, es:[di - 1]
		sub ah, ds:[si - 1]

		pop bp
		ret
		endp
;--------------------------------------

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
