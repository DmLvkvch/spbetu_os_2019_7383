CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK

; ���������
;---------------------------------------
; ��� ���������� ���������� 
ROUT PROC FAR
	jmp nextJump
	SIGNATURA 	dw 0ABCDh
	KEEP_PSP 	dw 0 ; ��� �������� psp ������ �����������
	KEEP_IP 	dw 0 ; ���������� ��� �������� �������� ������������ ����������� ����������
	KEEP_CS 	dw 0 ; ��� �������� ��� �������� 
	COUNTER		dw 0 ; ��� �������� ���������� ������� �����������
	COUNT_MESSAGE	db 'ROUT CALLED:      $'
	KEEP_SS 	dw 0
	KEEP_AX 	dw ?
	KEEP_SP 	dw 0
	INT_STACK 	dw 100 dup (?)
	s_top		=$
	
	nextJump:
	mov KEEP_SP,SP
	mov KEEP_SS,SS
	mov AX,seg INT_STACK
	mov SS,AX
	mov SP, offset s_top

	;���������� ���� ���������:
	push AX
	push BX
	push CX
	push DX

	mov AH,03h
	mov BH,00h
	int 10h
	push DX	
	mov AH,02h
	mov BH,0
	mov DX,071Ch
	int 10h
	;���������� ��������:
	push DS
	mov AX,seg COUNTER
	mov DS,AX
	mov AX,COUNTER
	inc AX
	mov COUNTER,AX
	push DI
	mov DI,offset COUNT_MESSAGE
	add DI,17
	call WRD_TO_HEX
	pop DI
	pop DS
	;����� ������:
	push ES
	push BP
	mov AX,seg COUNT_MESSAGE
	mov ES,AX
	mov BP,offset COUNT_MESSAGE
	mov AH,13h
	mov AL,0
	mov CX,12h
	mov BH,0
	int 10h
	pop BP
	pop ES
	pop DX
	mov AH,02h
	mov BH,00h
	int 10h

	pop DX
	pop CX
	pop BX
	pop AX
	mov SP,KEEP_SP
	mov SS,KEEP_SS
	mov AL,20h
	out 20h,AL
	iret	
ROUT ENDP 

; --------------------------------------
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP
;---------------------------------------
BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX
	pop CX
	ret
BYTE_TO_HEX ENDP
;---------------------------------------
; ������� � 16�/� 16-�� ���������� �����
; � AX - �����, DI - ����� ���������� �������
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
;---------------------------------------
LAST_BYTE:
;---------------------------------------
PRINT PROC
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------
; ��������, ���������� �� ��� ���������� ����������:
PROV_ROUT PROC
	mov ah,35h
	mov al,1ch
	int 21h ; �������� � ES:BX ����� ����������� ����������
	mov si,offset SIGNATURA
	sub si,offset ROUT ; � SI - �������� ��������� ������������ ������ �����������
	mov ax,0ABCDh
	cmp ax,ES:[BX+SI] ; ���������� ���������
	je ROUT_EST
		call SET_ROUT
		jmp PROV_KONEC
	ROUT_EST:
		call DEL_ROUT
	PROV_KONEC:
	ret
PROV_ROUT ENDP
;---------------------------------------
; ��������� ������ �����������:
SET_ROUT PROC
	mov ax,KEEP_PSP 
	mov es,ax ; ����� � es PSP ����� ��������
	cmp byte ptr es:[80h],0
		je UST
	cmp byte ptr es:[82h],'/'
		jne UST
	cmp byte ptr es:[83h],'u'
		jne UST
	cmp byte ptr es:[84h],'n'
		jne UST
	
	mov dx,offset PRER_NE_SET_VIVOD
	call PRINT
	ret
	
	UST:
	; ��������� ����������� ����������:
	call SAVE_STAND	
	
	mov dx,offset PRER_SET_VIVOD
	call PRINT
	
	push ds
	; ����� � ds:dx ����� ������ �����������:
	mov dx,offset ROUT
	mov ax,seg ROUT
	mov ds,ax
	
	; ������ ����� ����������� ���������� 1Ch:
	mov ah,25h
	mov al,1ch
	int 21h
	pop ds
	
	; ��������� ��������� ����������:
	mov dx,offset LAST_BYTE
	mov cl,4
	shr dx,cl ; ����� dx �� 16
	add dx,1
	add dx,20h
		
	xor AL,AL
	mov ah,31h
	int 21h ; ��������� ��� ���������� � ������
		
	xor AL,AL
	mov AH,4Ch
	int 21H
SET_ROUT ENDP
;---------------------------------------
; �������� ������ �����������:
DEL_ROUT PROC
	push dx
	push ax
	push ds
	push es
	
	
	mov ax,KEEP_PSP 
	mov es,ax ; ����� � es PSP ����� ��������
	cmp byte ptr es:[80h],0
		je UDAL_KONEC
	cmp byte ptr es:[82h],'/'
		jne UDAL_KONEC
	cmp byte ptr es:[83h],'u'
		jne UDAL_KONEC
	cmp byte ptr es:[84h],'n'
		jne UDAL_KONEC
	
	mov dx,offset PRER_DEL_VIVOD
	call PRINT
	
	mov ah,35h
	mov al,1ch
	int 21h ; �������� � ES:BX ����� ������ �����������
	mov si,offset KEEP_IP
	sub si,offset ROUT
	
	; ���������� ����������� ����������:
	mov dx,es:[bx+si]
	mov ax,es:[bx+si+2]
	mov ds,ax
	mov ah,25h
	mov al,1ch
	int 21h
	
	; ������� �� ������ ��� ����������:
	mov ax,es:[bx+si-2] ; �������� psp ������ �����������
	mov es,ax
	mov ax,es:[2ch] ; �������� ���������� ����� �����
	push es
	mov es,ax
	mov ah,49h
	int 21h
	pop es
	mov ah,49h
	int 21h

	jmp UDAL_KONEC2
	
	UDAL_KONEC:
	mov dx,offset PRER_UZHE_SET_VIVOD
	call PRINT
	UDAL_KONEC2:
	
	pop es
	pop ds
	pop ax
	pop dx
	ret
DEL_ROUT ENDP
;---------------------------------------
; ���������� ������ ������������ ����������� � KEEP_IP � KEEP_CS:
SAVE_STAND PROC
	push ax
	push bx
	push es
	mov ah,35h
	mov al,1ch
	int 21h ; �������� � ES:BX ����� ����������� ����������
	mov KEEP_CS, ES
	mov KEEP_IP, BX
	pop es
	pop bx
	pop ax
	ret
SAVE_STAND ENDP
;---------------------------------------
BEGIN:
	mov ax,DATA
	mov ds,ax
	mov KEEP_PSP, es
	call PROV_ROUT
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS

; ������
DATA SEGMENT
	PRER_SET_VIVOD db 'Setup interrupt','$'
	PRER_DEL_VIVOD db 'Uninstall interrupt',0DH,0AH,'$'
	PRER_UZHE_SET_VIVOD db 'Interrupt is already set',0DH,0AH,'$'
	PRER_NE_SET_VIVOD db 'Interrupt is not set',0DH,0AH,'$'
	STRENDL db 0DH,0AH,'$'
DATA ENDS
; ����
ASTACK SEGMENT STACK
	dw 100h dup (?)
ASTACK ENDS
 END BEGIN