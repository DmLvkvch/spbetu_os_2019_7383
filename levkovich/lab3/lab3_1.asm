testpc segment
		assume cs:testpc, ds: testpc, es:nothing, ss:nothing
		org 100h
start: jmp begin

;data segment
AVAILABLE_MEMORY db "Available memory:        ", 0dh, 0ah, '$'
EXTENDED_MEMORY db "Extended memory:       ", 0dh, 0ah, '$'

NEW_LINE db 0dh, 0ah, '$'

TABLE_TITLE db " Adress	   MSB type	PSP address	  Size       NAME    ", 0dh, 0ah, '$'
DATA_IN_TABLE  db "                                                               ", 0dh, 0ah, '$'
;end data segment

;--------------------------------------------------------------------------------
PRINT PROC near
		push ax
		mov ah, 09h
		int	21h
		pop ax
		ret
PRINT ENDP
;--------------------------------------------------------------------------------

TETR_TO_HEX PROC near

	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT:	add AL,30h
	ret
TETR_TO_HEX ENDP

;--------------------------------------------------------------------------------
BYTE_TO_HEX PROC near
;aaeo AL ia?aaiaeony a aaa neiaiea oanoi. ?enea a AX
	push CX
	mov AH,AL
	call TETR_TO_HEX 
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX  ;a AL - noa?oay, a AH - ieaaoay
	pop CX
	ret
BYTE_TO_HEX ENDP
;--------------------------------------------------------------------------------

WRD_TO_HEX PROC near
;ia?aaia a 16 n/n 16-oe ?ac?yaiiai ?enea  a AX - ?enei, DI - aa?an iineaaiaai neiaiea
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

;--------------------------------------------------------------------------------
BYTE_TO_DEC PROC near
;ia?aaia a 10n/n, SI - aa?an iiey ieaaoae oeo?u
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
	_bd: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae _bd
	cmp AL,00h
	je end_
	or AL,30h
	mov [SI],AL
	end_:	pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP

;--------------------------------------------------------------------------------
WRD_TO_DEC PROC near
	push CX
	push DX
	mov CX,10
	_b: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae _b
	cmp AL,00h
	je endl
	or AL,30h
	mov [SI],AL
	endl: pop DX
	pop CX
	ret
WRD_TO_DEC ENDP

;--------------------------------------------------------------------------------
GET_AVAILABLE_MEMORY PROC NEAR
	xor ax, ax
	mov ah, 04Ah
	mov bx, 0FFFFh
	int 21h
	mov ax, 10h
	mul bx
	mov si, offset AVAILABLE_MEMORY
	add si, 017h
	call WRD_TO_DEC
	mov dx, offset AVAILABLE_MEMORY
	call PRINT
	ret
GET_AVAILABLE_MEMORY ENDP

;--------------------------------------------------------------------------------
GET_EX_MEMORY PROC NEAR
	sub dx, dx
	mov al, 30h
    	out 70h, al
    	in al, 71h 
    	mov bl, al 
    	mov al, 31h  
    	out 70h, al
    	in al, 71h
	mov ah, al
	mov al, bl
	mov si, offset EXTENDED_MEMORY
	add si, 015h
	call WRD_TO_DEC
	mov dx, offset EXTENDED_MEMORY
	call PRINT
	ret
GET_EX_MEMORY ENDP

;--------------------------------------------------------------------------------
GET_MCB_DATA PROC near
	mov di, offset DATA_IN_TABLE
	mov ax, es
	add di, 05h
	call WRD_TO_HEX
	mov di, offset DATA_IN_TABLE
	add di, 0Fh
	xor ah, ah
	mov al, es:[00h]
	call BYTE_TO_HEX
	mov [di], al
	inc di
	mov [di], ah
	mov di, offset DATA_IN_TABLE
	mov ax, es:[01h]
	add di, 1Dh
	call WRD_TO_HEX
	mov di, offset DATA_IN_TABLE
	mov ax, es:[03h]
	mov bx, 10h
	mul bx
	add di, 2Eh
	push si
	mov si, di
	call WRD_TO_DEC
	pop si
	mov di, offset DATA_IN_TABLE
	add di, 35h
   	 mov bx, 0h
	GETTING_8_BYTES:
        mov dl, es:[bx + 8]
		mov [di], dl
		inc di
		inc bx
		cmp bx, 8h
	jne GETTING_8_BYTES
	mov ax, es:[03h]
	mov bl, es:[00h]
	ret
GET_MCB_DATA ENDP

GET_ALL_MSB_DATA PROC NEAR
	mov ah, 52h
	int 21h
	sub bx, 2h
	mov es, es:[bx]

FOR_EACH_MSB:
		call GET_MCB_DATA
		mov dx, offset DATA_IN_TABLE
		call PRINT

		mov cx, es
		add ax, cx
		inc ax
		mov es, ax

		cmp bl, 4Dh
		je FOR_EACH_MSB
		
		sub al, al
		mov ah, 4ch
		int 21h
GET_ALL_MSB_DATA ENDP

begin:
    	call GET_AVAILABLE_MEMORY
	call GET_EX_MEMORY
	mov dx, offset NEW_LINE
	call PRINT
	mov dx, offset TABLE_TITLE
	call PRINT
	call GET_ALL_MSB_DATA
	sub al, al
	mov ah, 4Ch
	int 21h
testpc ends
end start