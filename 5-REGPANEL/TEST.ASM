.model tiny
.code
.286
org 100h

Start:		mov di, offset MyStr

		mov ax, cs

		; ax - data
		mov cx, 4
@@ConvertHexLoop:
		mov bx, ax
		shr bx, 12
		mov bl, [offset HexTable + bx]

		mov byte ptr [di], bl
		inc di

		shl ax, 4
		loop @@ConvertHexLoop

		mov ah, 09h
		mov dx, offset MyStr
		int 21h			; puts(MyStr)

		mov ax, 1111h
		mov bx, 2222h
		mov cx, 3333h
		mov dx, 4444h
		mov si, 5555h
		mov di, 6666h
		mov bp, 7777h

		push 9999h
		pop ds
		push 0aaaah
		pop es

@@whileBegin:
		in al, 60h
		cmp al, 1
		jne @@whileBegin

		mov ax, 4c00h
		int 21h			; exit(al = 0)

HexTable	db "0123456789ABCDEF"
MyStr 		db "XXXX$"

end Start
