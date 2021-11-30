;Apdoroti MOV,OUT, NOT, RCR, XLAT
.model small
.stack 100
.data
     
    inFile dw 0000h 
    outFile dw 0000h
    inFileName db 13 dup(' '), 0h ;  Input file
    outFileName db 13 dup('$'), 0h ;  output file
    inputError db "Problem with files!$"
    debug db "Problemo!$"
    buff db 0h
    ; Simbols
    spaces db " " 
    
    registers db "alahaxclchcxblbhbxdldhdxspbpsidi"
    
    segments db "escsssds"
    segmentOff dw 0h
        
    commands db "movoutnotrcrxlat"
    unkownOperation db "Nezinoma"
    known dw 0h
    
    endl db 0Ah
    
        
.code
start:
  

    mov dx, @data
    mov ds, dx
    
    ; --------------- Reading from ES ---------------------
    mov di, offset inFileName
    
    mov si, 81h ; Es start
    
    xor cx, cx ; For going trough es  
    mov cl, es:[80h] ; Number of chars
    
    cmp cl, 0
    jz PrintError
    cmp cl, 23  ; Not too long
    ja PrintError
    
    xor bx, bx ; For counting spaces

    call ReadFileName ; In file
    
    cmp cl, 0
    jz PrintError
    
    xor bx, bx  
    mov di, offset outFileName ; Out file
    call ReadFileName
    
    ;-------------- Opening files ------------------
    
    ; Opening in file
    mov ah, 3dh
    mov al, 0 
    mov dx, offset inFileName     
    int 21h
    
    jc PrintError 
    mov inFile, ax ; File handle
    
    ; Read file fhr
    ;mov ah, 3fh
    ;mov bx, inFile ; File handle
    ;mov cx, 2000 ; Number of bytes to read
    ;mov dx, offset maze 
    ;int 21h   
    ;jc Error ; Error CF = 1
    
    ;cmp ax, 2000 ; Is map big enough?
    ;jb Error

    
    ; Open out file
    mov ah, 3ch
    mov dx, offset outFileName 
    int 21h
    jc PrintError 
    mov outFile, ax
    
    jmp Begin
    
; ---------- Closing -------------
exit:
    ; Close in file
    mov ah, 3eh
    mov bx, inFile 
    int 21h
    ; Close out file
    mov ah, 3eh
    mov bx, outFile 
    int 21h
    
    mov ax, 4c00h
    int 21h   
    
Problemo:
    xor ax, ax 
    mov ah, 09h
    mov dx, offset debug
    int 21h    
    mov ax, 4c00h
    int 21h
    
PrintError:    
    mov ah, 09h
    mov dx, offset inputError
    int 21h
    mov ax, 4c00h
    int 21h    


ReadFileName:
    ciklas:
        mov al, es:[si]
        cmp bx, 1
        ja terminate
        
        cmp al, 20h ; Al = ' ' ? 
        jz space    ; Skip
        
        mov ds:[di], al
        inc di 
        jmp next
    space:
        inc bx 
    next:
        inc si
        loop ciklas
    terminate: 
    ret
;-----------Begining-----------
; Gets al changes segmentOff
Prefix:
    cmp al, 26h ; ES
    jz Begin1
    
    add segmentOff, 2h ; CS
    cmp al, 2eh
    jz Begin1
    
    add segmentOff, 2h ; SS
    cmp al, 36h
    jz Begin1
    
    add segmentOff, 2h ; DS
    cmp al, 3eh
    jz Begin1
    mov segmentOff, 0h
    ;segments db "es cs ss ds"
    jmp begin2
Begin:
    call Read
    mov al, buff
    ; If prefix
    jmp Prefix
Begin1: 
    call Read  
Begin2: 
    xor ah, ah
    mov bx, ax
    ; Mov 1
            
    and ax, 11111100b
    cmp ax, 10001000b
    jne next1
    mov known, 1
    call mov1
    ; Mov 2
next1:
    mov ax, bx
    and ax, 11111110b
    cmp ax, 11000110b
    jne next2
    mov known, 1
    call mov2
next2:
    mov ax, bx
    and ax, 11110000b
    cmp ax, 10110000b
    jne next3
    mov known, 1
    call mov3 
next3:
    mov ax, bx
    and ax, 11111110b
    cmp ax, 10100000b
    jne next4
    mov known, 1
    call mov4
next4:
    mov ax, bx
    and ax, 11111110b
    cmp ax, 10100010b
    jne next5
    mov known, 1
    call mov5
next5:
    mov ax, bx
    and ax, 11111101b
    cmp ax, 10001100b
    jne next6
    mov known, 1
    call mov6
next6:
    mov ax, bx
    and ax, 11111110b
    cmp ax, 11100110b
    jne next7
    mov known, 1
    call out1
next7:
    mov ax, bx
    and ax, 11111110b
    cmp ax, 11101110b
    jne next8
    mov known, 1
    call out2
next8:
    mov ax, bx
    and ax, 11111100b
    cmp ax, 11110000b
    jne next9
    mov known, 1
    call not1
next9:
    mov ax, bx
    and ax, 11111100b
    cmp ax, 11010000b
    jne next10
    mov known, 1
    call rcr1
next10:
    mov ax, bx
    and ax, 11111111b
    cmp ax, 11010111b
    jne next11
    mov known, 1
    call xlat1
    
next11:
    cmp known, 0
    jne next12
    call unknownOp
next12: 
   
    mov known, 0
    mov segmentOff, 0h  
    jmp begin 
    
exit1:
    jmp exit 
 
    
Read:
    push bx
    push ax
    
    xor ax, ax
    mov ah, 3fh
    mov bx, inFile ; File handle
    mov cx, 1
    mov dx, offset buff
    int 21h
    
    jc exit1
    cmp ax, 1
    jb exit1
    
    pop ax
    pop bx
    
    ret 
    
    
  ;Example
 ;mov cx, 3
 ;mov dx, [offset commands + 6]    
 ;call print_n    
Print_n: ; Gets cx - how much to print, dx - what to print
    push ax
    push bx
    
    xor ax, ax
    mov ah, 40h
    mov bx, outFile  
    int 21h
   
    pop bx
    pop ax
    ret
    
    
unknownOp:
    mov dx, offset unkownOperation
    mov cx, 8
    call print_n
    mov dx, offset endl
    mov cx, 1
    call print_n
    ret
mov1:
    mov dx, offset commands
    mov cx, 3
    call print_n
    mov dx, offset endl
    mov cx, 1
    call print_n
    ret
mov2:
    mov dx, offset commands
    mov cx, 3
    call print_n
    mov dx, offset endl
    mov cx, 1
    call print_n
    ret
mov3:
    mov dx, offset commands
    mov cx, 3
    call print_n
    mov dx, offset endl
    mov cx, 1
    call print_n
    ret
mov4:
    mov dx, offset commands
    mov cx, 3
    call print_n
    mov dx, offset endl
    mov cx, 1
    call print_n
    ret
mov5:
    mov dx, offset commands
    mov cx, 3
    call print_n
    mov dx, offset endl
    mov cx, 1
    call print_n
    ret
mov6:
    mov dx, offset commands
    mov cx, 3
    call print_n
    mov dx, offset endl
    mov cx, 1
    call print_n
    ret
    ;commands db "movoutnotrcrxlat"
out1:
    mov dx, offset commands + 3
    mov cx, 3
    call print_n
    
    mov dx, offset endl
    mov cx, 1
    call print_n
    ret
out2:
    mov dx, offset commands + 3
    mov cx, 3
    call print_n
    mov dx, offset endl
    mov cx, 1
    call print_n
    ret
not1:
    mov dx, offset commands + 6
    mov cx, 3
    call print_n
    mov dx, offset endl
    mov cx, 1
    call print_n
    ret
rcr1:
    mov dx, offset commands + 9
    mov cx, 3
    call print_n
    mov dx, offset endl
    mov cx, 1
    call print_n
    ret
xlat1:
    mov dx, offset commands + 12
    mov cx, 4
    call print_n
    mov dx, offset endl
    mov cx, 1
    call print_n
    ret

    
end start