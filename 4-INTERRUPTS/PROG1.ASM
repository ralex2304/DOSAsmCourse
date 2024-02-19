.286
.model tiny
.code
org 100h
locals @@


Start:		push 0b800h
		pop es

		mov bx, ((80 * 3) + 40) * 2
		mov ah, 4eh ; color

Next:		in al, 60h ; symbol
		mov es:[bx], ax

		cmp al, 0eh ; backspace
		jne Next

		ret

end		Start

