;Apdoroti MOV,OUT, NOT, RCR, XLAT
.model small
.stack 100
.data
     
    inFile dw 0000h 
    outFile dw 0000h
    inFileName db 13 dup(' '), 0h ;  Input file
    outFileName db 13 dup('$'), 0h ;  output file
    inputError db "Problem with files!$"
    
    registers db "alahaxclchcxblbhbxdldhdxspbpsidi"
    segments db "escsssds"
    commands db "movoutnotrcrxlat"
    
        
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
    
    jmp begin
    
   

    
    
    
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
begin:
    mov cx, 3
    mov dx, [offset commands + 6]    

    call print_n
    
    jmp exit


        
print_n: ; Gets cx - how much to print, dx - what to print
    push ax
    push bx
    
    xor ax, ax
    mov ah, 40h
    mov bx, outFile  
    int 21h
   
    pop bx
    pop ax
    ret


    
end start