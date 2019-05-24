ASSUME CS:OVL2,DS:OVL2,SS:NOTHING,ES:NOTHING
OVL2 SEGMENT
;---------------------------------------------------------------
MAIN2 PROC FAR 
	push ds
	push dx
	push di
	push ax
	mov ax,cs
	mov ds,ax
	mov bx, offset ForPrint
	add bx, 47h			
	mov di, bx		
	mov ax, cs			
	call WRD_TO_HEX
	mov dx, offset ForPrint	
	call PRINT
	pop ax
	pop di
	pop dx	
	pop ds
	retf
MAIN2 ENDP
;---------------------------------------------------------------
PRINT PROC NEAR ;печать на экран 
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
;--------------------------------------------------------------------------------
TETR_TO_HEX		PROC near ;половина байт AL переводится в символ шестнадцатиричного числа в AL
		and		al, 0Fh ;and 00001111 - оставляем только вторую половину al
		cmp		al, 09 ;если больше 9, то надо переводить в букву
		jbe		NEXT ;выполняет короткий переход, если первый операнд МЕНЬШЕ или РАВЕН второму операнду
		add		al, 07 ;дополняем код до буквы
	NEXT:	add		al, 30h ;16-ричный код буквы или цифры в al
		ret
TETR_TO_HEX		ENDP
;--------------------------------------------------------------------------------
BYTE_TO_HEX		PROC near ;байт AL переводится в два символа шестнадцатиричного числа в AX
		push	cx
		mov		ah, al ;копируем al в ah
		call	TETR_TO_HEX ;переводим al в символ 16-рич.
		xchg	al, ah ;меняем местами al и  ah
		mov		cl, 4 
		shr		al, cl ;cдвиг всех битов al вправо на 4
		call	TETR_TO_HEX ;переводим al в символ 16-рич.
		pop		cx 			
		ret
BYTE_TO_HEX		ENDP
;--------------------------------------------------------------------------------
WRD_TO_HEX		PROC	near ;регистр AX переводится в шестнадцатеричную систему, DI - адрес последнего символа
		push	bx
		mov		bh, ah ;копируем ah в bh, т.к. ah испортится при переводе
		call	BYTE_TO_HEX ;переводим al в два символа шестнадцатиричного числа в AX
		mov		[di], ah ;пересылка содержимого регистра ah по адресу, лежащему в регистре DI
		dec		di 
		mov		[di], al ;пересылка содержимого регистра al по адресу, лежащему в регистре DI
		dec		di
		mov		al, bh ;копируем bh в al, восстанавливаем значение ah
		xor		ah, ah ;очищаем ah
		call	BYTE_TO_HEX ;переводим al в два символа шестнадцатиричного числа в AX
		mov		[di], ah ;пересылка содержимого регистра al по адресу, лежащему в регистре DI
		dec		di
		mov		[di], al ;пересылка содержимого регистра al по адресу, лежащему в регистре DI
		pop		bx
		ret
WRD_TO_HEX		ENDP
;--------------------------------------------------------------------------------
ForPrint  DB 0DH,0AH, 'The address of the segment to which the second overlay is loaded:                 ',0DH,0AH,'$'
;--------------------------------------------------------------------------------
OVL2 ENDS
END