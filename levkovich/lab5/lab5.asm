ASSUME CS:CODE, DS:DATA, SS:ASTACK
ASTACK SEGMENT STACK 
	DW 64 DUP(?)
ASTACK ENDS
CODE SEGMENT
;----------------------------
PRINT PROC NEAR 
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
;----------------------------
ROUT PROC FAR
jmp begin
	ADDR_PSP1   	dw 0 
	ADDR_PSP2  	dw 0 
	KEEP_IP 	dw 0 
	KEEP_CS 	dw 0 
	KEEP_SS		dw 0
	KEEP_AX		dw 0
	KEEP_SP		dw 0
	INTER_SET 	dw 0ABCDh 
	REQ_KEY_6	db 07h
	REQ_KEY_7	db 08h
	REQ_KEY_8	db 09h
	REQ_KEY_9	db 0Ah
	REQ_KEY_0	db 0Bh
	INT_STACK	dw 64 dup (?)

begin:
	mov KEEP_SS, ss
 	mov KEEP_SP, sp
 	mov KEEP_AX, ax
 	mov ax, seg INT_STACK
 	mov ss, ax
 	mov sp, 0
 	mov ax, KEEP_AX  
	
	mov ax,0040h
	mov es,ax
	mov al,es:[17h]
	and al,00000010b
	jnz stand_set
	
	in al,60h ;Cчитать ключ
	
	cmp al, REQ_KEY_6
	je 	key6 
		
	cmp al, REQ_KEY_7 
	je 	key7

	cmp al, REQ_KEY_8
	je 	key8
	
	cmp al, REQ_KEY_9
	je 	key9
	
	cmp al, REQ_KEY_0
	je 	key0
	
	mov ss, KEEP_SS 
 	mov sp, KEEP_SP
	
	stand_set:
		pop es
		pop ds
		pop dx
		mov ax, CS:KEEP_AX
		mov sp, CS:KEEP_SP
		mov ss, CS:KEEP_SS
		jmp dword ptr cs:[KEEP_IP]

	key6:
		mov cl, 'A'
		jmp do_req
	key7:
		mov cl, 'B'
		jmp do_req
	key8:
		mov cl, 'C'
		jmp do_req
	key9:
		mov cl, 'D'
		jmp do_req
	key0:
		mov cl, 'E'

	do_req:
		in al,61h	
		mov ah,al	
		or al,80h	
		out 61h,al	
		xchg ah, al	
		out 61h,al	
		mov al,20h	 
		out 20h,al	
		
		push bx
		push cx
		push dx	
	
		mov ah, 05h
		mov ch, 00h 	
		int 16h
		or 	al, al
		jnz skip 	
		jmp return	
	
	skip: 			
		push es
		push si
		mov ax, 0040h
		mov es, ax
		mov si, 001ah
		mov ax, es:[si] 
		mov si, 001ch
		mov es:[si], ax	
		pop si
		pop es
		
	return:
		pop dx    
		pop cx
		pop bx	
		mov ax, KEEP_SS
		mov ss, ax
		mov ax, KEEP_AX
		mov sp, KEEP_SP
		iret
ROUT ENDP

LAST_BYTE:
PROV_ROUT PROC NEAR	
	push bx
	push dx
	push es

	mov ah, 35h	
	mov al, 09h	
	int 21h

	mov dx, es:[bx + 11]
	cmp dx, 0ABCDh 
	je install_
	mov al, 00h
	jmp end_install

install_:
	mov al, 01h
	jmp end_install

end_install:
	pop es
	pop dx
	pop bx
	ret
PROV_ROUT ENDP
;----------------------------
UN_CHECK PROC NEAR
	push es
	mov ax, ADDR_PSP1
	mov es, ax

	cmp byte ptr es:[82h], '/'		
	jne not_enter
	cmp byte ptr es:[83h], 'u'		
	jne not_enter
	cmp byte ptr es:[84h], 'n'
	jne not_enter
	mov al, 1h

not_enter:
	pop es
	ret
UN_CHECK ENDP
;----------------------------
SET_ROUT PROC NEAR
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 09h
	int 21h

	mov KEEP_IP, bx
	mov KEEP_CS, es

	push ds
	lea dx, ROUT
	mov ax, seg ROUT
	mov ds, ax

	mov ah, 25h
	mov al, 09h
	int 21h 
	pop ds

	lea dx, PRER_SET_VIVOD  
	call PRINT

	pop es
	pop dx
	pop bx
	pop ax
	
	ret
SET_ROUT ENDP
;----------------------------
DEL_ROUT PROC NEAR	
	push ax
	push bx
	push dx
	push es
	
	mov ah, 35h
	mov al, 09h
	int 21h

	cli
	push ds            
	mov dx, es:[bx + 7]   
	mov ax, es:[bx + 9]   
		
	mov ds, ax
	mov ah, 25h
	mov al, 09h
	int 21h
	pop ds
	sti
	
	lea dx, PRER_DEL_VIVOD
	call PRINT 

	push es 
	mov cx,es:[bx+3]
	mov es,cx
	mov ah,49h
	int 21h
	
	pop es
	mov cx,es:[bx+5]
	mov es,cx
	int 21h

	pop es
	pop dx
	pop bx
	pop ax
	
	mov ah, 4Ch	
	int 21h
	ret
DEL_ROUT ENDP
;----------------------------
MAIN  PROC FAR
    mov bx,2Ch
	mov ax,[bx]
	mov ADDR_PSP2,ax
	mov ADDR_PSP1,ds
	mov dx, ds 
	sub ax,ax    
	xor bx,bx
	mov ax,data  
	mov ds,ax 
	xor dx, dx

	call UN_CHECK 
	cmp al, 01h
	je unload_		

	call PROV_ROUT
	cmp al, 01h
	jne not_resident
	
	lea dx, PRER_UZHE_SET_VIVOD
	call PRINT
	jmp quit


not_resident: 
	call SET_ROUT
	lea dx, last_byte
	mov cl, 04h
	shr dx, cl
	add dx, 1Bh
	mov ax, 3100h
	int 21h
	
   
unload_:
	call PROV_ROUT
	cmp al, 0h
	je not_install_
	call DEL_ROUT
	jmp quit
not_install_: 
	lea dx, PRER_NE_SET_VIVOD
	call PRINT
	
quit:
	mov ah, 4Ch
	int 21h
MAIN  	ENDP
CODE 	ENDS

DATA SEGMENT
	PRER_SET_VIVOD    	db 'Setup interrupt', 0dh, 0ah, '$'
   	PRER_NE_SET_VIVOD 	db 'Interrupt is not set', 0dh, 0ah, '$'
   	PRER_UZHE_SET_VIVOD	db 'Interrupt is already set', 0dh, 0ah, '$'
	PRER_DEL_VIVOD		db 'Uninstall interrupt', 0dh, 0ah, '$'
DATA ENDS
END MAIN