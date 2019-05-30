STACK SEGMENT STACK
	DW 80h DUP (?)
STACK ENDS

ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK

DATA SEGMENT
	ERROR_FREEING       db 'Error when freeing memory: $'
	ERROR_MCM           db 'MCB is destroyed$'
	ERROR_NO_MEM        db 'Not enough memory for function processing$'
	ERROR_WRONG_ADDR    db 'Wrong addres of memory block$'
	STRENDL             db 13,10,'$'
	OVL_PATH            db 64	dup (0), '$'
	DTA                 db 43 DUP (?)
	KEEP_PSP            dw 0
	ERROR_ALLOC         db 'Failed to allocate memory to load overlay!',13,10,'$'
	BLOCK_ADDR          dw 0
	CALL_ADDR           dd 0
	ERROR_OVL_LOAD      db 'The overlay was not been loaded: '
	Err1                db 'a non-existent function!',13,10,'$'
        Err2                db 'The file was not found!',13,10,'$'
	Err3                db 'The route was not found!',13,10,'$'
	Err4                db 'too many open files!',13,10,'$'
	Err5                db 'no access!',13,10,'$'
	Err8                db 'low memory!',13,10,'$'
	Err10               db 'incorrect environment!',13,10,'$'
	OVL1                db 'overlay1.ovl',0
	OVL2                db 'overlay2.ovl',0	
DATA ENDS
;---------------------------------------------------------------
CODE SEGMENT

PRINT PROC NEAR 
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
;--------------------------------------------------------------------------------
FREE_MEM PROC 
	mov bx, offset LAST_BYTE
	mov ax,es
	sub bx, ax
	mov cl,4h
	shr bx,cl 
	mov ah,4ah
	int 21h
	jnc MEM_FREED	

	mov dx,offset ERROR_FREEING
	call PRINT
	cmp ax,7
	mov dx,offset ERROR_MCM
	je FREE_MEM_PRINT_ERROR
	cmp ax,8
	mov dx,offset ERROR_NO_MEM
	je FREE_MEM_PRINT_ERROR
	cmp ax,9
	mov dx,offset ERROR_WRONG_ADDR
	je FREE_MEM_PRINT_ERROR	
		
FREE_MEM_PRINT_ERROR:
	call PRINT
	mov dx,offset STRENDL
	call PRINT

	xor AL,AL
	mov AH,4Ch
	int 21H
	
MEM_FREED:
	ret
FREE_MEM ENDP
;---------------------------------------------------------------
FIND_PATH PROC 
	push ds
	push dx
	mov dx, seg DTA 
	mov ds, dx
	mov dx,offset DTA 
	mov ah,1Ah 
	int 21h 
	pop dx
	pop ds
		
	push es 
	push dx
	push ax
	push bx
	push cx
	push di
	push si
	mov es, KEEP_PSP 
	mov ax, es:[2Ch] 
	mov es, ax
	xor bx, bx 
COPY_CONT: 
	mov al, es:[bx] 
	cmp al, 0h 
	je	STOP_COPY_CONT 
	inc bx	
	jmp COPY_CONT
STOP_COPY_CONT:
	inc bx	
	cmp byte ptr es:[bx], 0h 
	jne COPY_CONT 
	add bx, 3h 
	mov si, offset OVL_PATH
COPY_PATH: 
	mov al, es:[bx] 
	mov [si], al 
	inc si 
	cmp al, 0h 
	je	STOP_COPY_PATH
	inc bx 
	jmp COPY_PATH
STOP_COPY_PATH:	
	sub si, 9h 
	mov di, bp 
ENTRY_WAY: 
	mov ah, [di] 
	mov [si], ah 
	cmp ah, 0h 
	je	STOP_ENTRY_WAY 
	inc di
	inc si
	jmp ENTRY_WAY
STOP_ENTRY_WAY:
	pop si
	pop di
	pop cx
	pop bx
	pop ax
	pop dx
	pop es
	ret
FIND_PATH ENDP
;---------------------------------------------------------------
FIND_OVL_SIZE PROC
	push ds
	push dx
	push cx
	xor cx, cx 
	mov dx, seg OVL_PATH 
	mov ds, dx
	mov dx, offset OVL_PATH
	mov ah,4Eh 
	int 21h 
	jnc FILE_FOUND
	cmp ax,3
	je Error3
	mov dx, offset Err2
	jmp EXIT_FILE_ERROR
Error3:
	mov dx, offset Err3 
EXIT_FILE_ERROR:
	call PRINT
	pop cx
	pop dx
	pop ds
	xor al,al
	mov ah,4Ch
	int 21H
	
FILE_FOUND: 
	push es
	push bx
	mov bx, offset DTA 
	mov dx,[bx+1Ch] 
	mov ax,[bx+1Ah] 
	mov cl,4h 
	shr ax,cl
	mov cl,12 
	sal dx, cl 
	add ax, dx 
	inc ax 
	mov bx,ax 

	mov ah,48h 
	int 21h 
	jnc SUCSESS_ALLOC 
	mov dx, offset ERROR_ALLOC 
	call PRINT
	xor al,al
	mov ah,4Ch
	int 21h
	
SUCSESS_ALLOC:
	mov BLOCK_ADDR, ax 
	pop bx
	pop es
	pop cx
	pop dx
	pop ds
	ret
FIND_OVL_SIZE ENDP
;---------------------------------------------------------------
CALL_OVL PROC 
	push dx
	push bx
	push ax
	mov bx, seg BLOCK_ADDR 
	mov es, bx
	mov bx, offset BLOCK_ADDR
		
	mov dx, seg OVL_PATH 
	mov ds, dx	
	mov dx, offset OVL_PATH	

	mov ax, 4B03h 
	int 21h
	push dx
	jnc OVL_NO_ERROR 
	
	mov dx, offset ERROR_OVL_LOAD
	call PRINT
	
	cmp ax, 1 
	mov dx, offset Err1
	je OVL_ERROR_PRINT
	cmp ax, 2 
	mov dx, offset Err2
	je OVL_ERROR_PRINT
	cmp ax, 3 
	mov dx, offset Err3
	je OVL_ERROR_PRINT
	cmp ax, 4 
	mov dx, offset Err4
	je OVL_ERROR_PRINT
	cmp ax, 5 
	mov dx, offset Err5
	je OVL_ERROR_PRINT
	cmp ax, 8 
	mov dx, offset Err8
	je OVL_ERROR_PRINT
	cmp ax, 10 
	mov dx, offset Err10
	je OVL_ERROR_PRINT
	
OVL_ERROR_PRINT:
	call PRINT
	jmp OVL_RET

OVL_NO_ERROR:
	mov AX,DATA 
	mov DS,AX
	mov ax, BLOCK_ADDR
	mov word ptr CALL_ADDR+2, ax
	call CALL_ADDR 
	mov ax, BLOCK_ADDR
	mov es, ax
	mov ax, 4900h 
	int 21h
	mov AX,DATA 
	mov DS,AX

OVL_RET:
	pop dx
	mov es, KEEP_PSP
	pop ax
	pop bx
	pop dx
	ret
CALL_OVL ENDP
;---------------------------------------------------------------
MAIN PROC FAR
	mov ax,DATA
	mov ds,ax
	mov KEEP_PSP, ES
	call FREE_MEM 
	mov bp, offset OVL1
	call FIND_PATH
	call FIND_OVL_SIZE 
	call CALL_OVL 
	sub bx,bx
	mov bp, offset OVL2
	call FIND_PATH
	call FIND_OVL_SIZE 
	call CALL_OVL 
	xor al,al
	mov ah,4Ch 
	int 21h
MAIN ENDP
CODE ENDS

LAST_BYTE SEGMENT	
LAST_BYTE ENDS	

END MAIN
