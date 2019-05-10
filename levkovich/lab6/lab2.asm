TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START:
	JMP BEGIN
	UntouchMem 		DB 'Segment address of untouchable memory -     ',10,13,'$'
	Envir 			DB 'Segment address of environment -     ',10,13,'$'
	Tail 			DB 'Tail of command string', '$'
	EndStr 			DB ' ',10,13,'$'
	ContEnvAr 		DB 'Contents of the environment area', '$'
	WayMod 			DB 'Way of module', '$'

TETR_TO_HEX PROC NEAR
	and al,0fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT:
	add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX ; ? AL aa ae i ??aa 
	pop CX           ; ? AH мл дe i
	ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near

    push BX
	mov BH,AH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	dec DI
	mov AL,BH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	pop BX
	ret
WRD_TO_HEX ENDP

PRINT_STR PROC near
	mov ah,09h
	int 21h
	ret
PRINT_STR ENDP

GET_UNTOUCH_MEM PROC NEAR
	push ax
	push di
	mov ax,ds:[02h]
	mov di,offset UntouchMem+43
	call WRD_TO_HEX
	mov dx,offset UntouchMem
	call PRINT_STR
	pop di
	pop ax
	ret
GET_UNTOUCH_MEM ENDP

GET_ENV_ADR_SEG PROC NEAR
	push ax
	push di
	mov ax, ds:[02Ch] 
	mov di, offset Envir+36 	
	call WRD_TO_HEX
	mov dx, offset Envir 	
	call PRINT_STR
	pop di
	pop ax
	ret
GET_ENV_ADR_SEG ENDP

GET_TAIL PROC NEAR
	mov dx,offset Tail
	call PRINT_STR
	mov cx,0
	mov cl,es:[80h]
	cmp cl,0
	je TAIL_END
	mov dx,81h
	mov bx,0
	mov ah,02h
	TAIL_loop:
		mov dl,es:[bx+81h]
		int 21h
		inc	bx
	loop TAIL_loop
	mov dx,offset EndStr
	call PRINT_str
	TAIL_END:
	ret
GET_TAIL ENDP

NEW_LINE		PROC	near
		lea		dx,EndStr
		call	PRINT_STR
		ret
NEW_LINE		ENDP

GET_ENVIRONMENT_DATA PROC NEAR
		push 	es 
		push	ax  
		push	bx  
		push	cx 
		mov	bx,1 
		mov	es,es:[2ch]
		mov	si,0 
	line: 
		call 	NEW_LINE
		mov	ax,si 
	metka:
		cmp 	byte ptr es:[si], 0 
		je 	NEXT_ 
		inc	si 
		jmp 	metka 
	NEXT_:
		push	es:[si] 
		mov	byte ptr es:[si], '$' 
		push	ds 
		mov	cx,es 
		mov	ds,cx 
		mov	dx,ax 
		call	PRINT_STR
		pop	ds 
		pop	es:[si] 
		cmp	bx,0 
		jz 	LAST 
		inc	si 
		cmp 	byte ptr es:[si], 01h 
    		jne 	line
    		lea	dx,WayMod
    		call	PRINT_STR 
    		mov	bx,0 
    		add 	si,2 
    		jmp 	line 
    	LAST:
		pop	cx 
		pop	bx 
		pop	ax 
		pop	es 
		ret
GET_ENVIRONMENT_DATA ENDP

BEGIN:
call GET_UNTOUCH_MEM
call GET_ENV_ADR_SEG
call GET_TAIL
mov dx, offset Endstr
call PRINT_STR
mov dx, offset ContEnvAr
call PRINT_STR
call GET_ENVIRONMENT_DATA

mov ah, 01h
int 21h
mov ah, 4Ch
int 21h
	
TESTPC 	ENDS
		END START