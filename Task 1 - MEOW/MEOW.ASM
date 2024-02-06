.model tiny
.code
.286
org 100h

Start:		mov ah, 09h
		mov dx, offset MyStr
		int 21h			; puts(MyStr)

		mov ax, 4c00h
		int 21h			; exit(al = 0)

MyStr db "Pupupu", 0dh, 0ah, "$"

end Start