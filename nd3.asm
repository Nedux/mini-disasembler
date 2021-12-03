;Apdoroti MOV,OUT, NOT, RCR, XLAT
.model small
.stack 100
.data
    ; Files
    inFile dw 0000h 
    outFile dw 0000h
    inFileName db 13 dup(' '), 0h ;  Input file
    outFileName db 13 dup('$'), 0h ;  output file
    inputError db "Problem with files!$"
    buff db 0h
    
    ; Count
    count dw 100h
    countBuff db "0000: "
    byteBuff db "  "
    wordBuff db "    "
    
    debug db "Problemo!$"
    ; Simbols
    spaces db " " 
    hex db "h"
    endl db 0Ah
    bracket db "]"
    comma db ","
    one db "1"
    plus db "+"
    colon db ":"
    
    ; Registers
    registers db "alaxclcxdldxblbxahspchbpdhsibhdi"
    segments db "  escsssds"
    segmentOff dw 0h       
    commands db "movoutnotrcrxlat"
    rmfield db "[bx+si[bx+di[bp+si[bp+di[si[di[bp[bx"
    rcrop db "1cl"
    ; 
    adrB db 0
    opk db 0
    modd db 0
    reg db 0
    rm db 0
    v db 0
    w db 0
    d db 0
    posl1 db 0
    posl2 db 0
    
    unkownOperation db "Nezinoma"
    known dw 0h
    
    
        
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

; Gets al, Changes: segmentOff
Prefix:

    add segmentOff, 2h ; ES
    cmp al, 26h 
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
    
    mov segmentOff, 0h ; Normal command
    jmp Begin2
    
Begin:
    call Read
    call FormatCount
    mov al, buff
    call FormatByte
    call print_space
    inc count
    
    jmp Prefix
Begin1:  ; Prefix detected 
    call Read 
    mov al, buff
    call FormatByte
    call print_space
    inc count
Begin2: ; No prefix

    ; Mov 1
    xor ah, ah
    mov bx, ax      
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
    ; Mov 3
next2:
    mov ax, bx
    and ax, 11110000b
    cmp ax, 10110000b
    jne next3
    mov known, 1
    call mov3 
    ; Mov 4
next3:
    mov ax, bx
    and ax, 11111110b
    cmp ax, 10100000b
    jne next4
    mov known, 1
    call mov4
    ; Mov 5
next4:
    mov ax, bx
    and ax, 11111110b
    cmp ax, 10100010b
    jne next5
    mov known, 1
    call mov5
    ; Mov 6
next5:
    mov ax, bx
    and ax, 11111101b
    cmp ax, 10001100b
    jne next6
    mov known, 1
    call mov6
    ; OUT 1
next6:
    mov ax, bx
    and ax, 11111110b
    cmp ax, 11100110b
    jne next7
    mov known, 1
    call out1
    ; OUT 2
next7:
    mov ax, bx
    and ax, 11111110b
    cmp ax, 11101110b
    jne next8
    mov known, 1
    call out2
    ; NOT 
next8:
    mov ax, bx
    and ax, 11111110b
    cmp ax, 11110110b
    jne next9
    mov known, 1
    call not1
    ; RCR
next9:
    mov ax, bx
    and ax, 11111100b
    cmp ax, 11010000b
    jne next10
    mov known, 1
    call rcr1
    ; XLAT
next10:
    mov ax, bx
    and ax, 11111111b
    cmp ax, 11010111b
    jne next11
    mov known, 1
    call xlat1
    ; Unknow
next11:
    cmp known, 0 ; Not found
    jne next12
    call unknownOp
    
    ; Preparing for new command
next12: 
    mov known, 0
    mov segmentOff, 0h  
    jmp begin 
    
exit1:
    jmp exit 
 
;------------- Reads 1 byte -------------
; changes buff
Read: 
    push bx
    push ax
    push cx
    
    xor ax, ax
    mov ah, 3fh
    mov bx, inFile ; File handle
    mov cx, 1
    mov dx, offset buff
    int 21h
    jc exit1 ; Error occured
    cmp ax, 1
    jb exit1 ; Read less
    
    pop cx    
    pop ax
    pop bx
    
    ret 
;-------------- Prints count --------------
FormatCount:  
    push ax
    push si
    push cx
    push bx
    push dx
    
    mov ax, count
    ; Formating the results
    mov si, offset countBuff + 3   
    xor cx, cx
    mov cx, 4   ; 4 times since 4 digits max number
 
    mov bx, 10h 
    
ciklas3:
    xor dx, dx
    div bx      ; ax - sveikoji dalis, dx - liekana
    add dx, 30h
    cmp dl, 39h 
    jbe write
    add dl, 7h ; If 10 - 16
write:
    mov ds:[si], dl           
    dec si          
    loop ciklas3    
    
    mov dx, offset countBuff
    mov cx, 6
    call print_n
    
    pop dx
    pop bx
    pop cx
    pop si
    pop ax
    ret
        ; gets ax
FormatByte:
    push ax
    push si
    push cx
    push bx
    push dx
    
    ; Formating the results
    mov si, offset byteBuff + 1   
    xor cx, cx
    mov cx, 2
 
    mov bx, 10h 
ciklas4:
    xor dx, dx
    div bx      ; ax - sveikoji dalis, dx - liekana
    add dx, 30h
    cmp dl, 39h 
    jbe write1
    add dl, 7h ; If 10 - 16
write1:
    mov ds:[si], dl           
    dec si          
    loop ciklas4    
    
    mov dx, offset byteBuff
    mov cx, 2
    call print_n
    
    pop dx
    pop bx
    pop cx
    pop si
    pop ax
    ret

Print_space:
    mov dx, offset spaces
    mov cx, 1
    call print_n 
    ret
    
Print_n: ; Gets cx - how much to print, dx - what to print; changes nothing
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
    mov opk, bl
    call getInfo
    
    
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
    call pos1B
    ; out
    mov dx, offset commands + 3
    mov cx, 3
    call print_n
    call print_space
    ; poslinkis
    xor ax, ax
    mov al, posl1
    call FormatByte
    ; h
    mov dx, offset hex
    mov cx, 1
    call print_n
    ; ,
    mov dx, offset comma
    mov cx, 1
    call print_n
    call print_space
    call out_universal

    ret
out2:
    ; out
    mov dx, offset commands + 3
    mov cx, 3
    call print_n
    call print_space
    ; dx
    mov dx, offset registers + 10 ; dx
    mov cx, 2
    call print_n
    ; ,
    mov dx, offset comma
    mov cx, 1
    call print_n
    call print_space
out_universal:
    ; Getting w bit
    xor ax, ax
    mov al, bl
    mov cx, 10b
    div cl
    mov w, ah
    ; al / ax
    mov cx, 2
    cmp w, 0
    jne out_n1
    mov dx, offset registers ; al
    call print_n
    mov dx, offset endl
    mov cx, 1
    call print_n
    ret
out_n1: 
    mov dx, offset registers + 2 ; ax
    call print_n
    mov dx, offset endl
    mov cx, 1
    call print_n
    ret

not1:
    mov opk, bl
    call getInfo
    
    cmp modd, 00b  ; mod 00
    jne not_n3
    
    cmp rm, 110b 
    jne not_n2
    call pos2B ; Tiesioginis adresas   
not_n2: 
    mov dx, offset commands + 6
    mov cx, 3
    call print_n
    call print_space 
    call prefix_print
    call rm0b
    
not_n3: ; mod 11
    cmp modd, 11b
    jne not_n5
    mov dx, offset commands + 6
    mov cx, 3
    call print_n
    call print_space
    call regp
    
not_n5:; mod 01
    cmp modd, 01b 
    jne not_n6
    
    call pos1B
    mov dx, offset commands + 6
    mov cx, 3
    call print_n
    call print_space
    call prefix_print
    call rm1b
    
not_n6:; mod 10
    cmp modd, 10b 
    jne not_n7
    call pos2B
    mov dx, offset commands + 6
    mov cx, 3
    call print_n
    call print_space
    call prefix_print
    call rm2b
not_n7:
    
    mov dx, offset endl
    mov cx, 1
    call print_n
    ret

rcr1:
    mov opk, bl
    call getInfo
    
    cmp modd, 00b  ; mod 00
    jne rcr_n3
    
    cmp rm, 110b 
    jne rcr_n2
    call pos2B ; Tiesioginis adresas
rcr_n2: 
    mov dx, offset commands + 9
    mov cx, 3
    call print_n
    call print_space
    
    call prefix_print
    
    call rm0b
    
rcr_n3: ; mod 11
    cmp modd, 11b
    jne rcr_n5
    mov dx, offset commands + 9
    mov cx, 3
    call print_n
    call print_space
    call regp
    
rcr_n5:; mod 01
    cmp modd, 01b 
    jne rcr_n6
    
    call pos1B
    mov dx, offset commands + 9
    mov cx, 3
    call print_n
    call print_space
    call prefix_print
    call rm1b
    
rcr_n6:; mod 10
    cmp modd, 10b 
    jne rcr_n7
    call pos2B
    mov dx, offset commands + 9
    mov cx, 3
    call print_n
    call print_space
    call prefix_print
    call rm2b
    
rcr_n7:
    mov dx, offset comma
    mov cx, 1
    call print_n
    call print_space
    cmp d, 0 ; in this case v is in d
    jne rcr_end
    mov dx, offset one
    mov cx, 1  
    call print_n
    mov dx, offset endl
    mov cx, 1
    call print_n
    ret
rcr_end:
    mov dx, offset registers + 4 ; cl
    mov cx, 2
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
    
    ; Gets opk - bx
getInfo:
    push bx
    push ax
    push cx
    ; Getting adresavimo baitas
    call Read
    inc count
    xor ax, ax
    mov al, buff
    mov adrB, al 
    call FormatByte
    call print_space
    
    xor ax, ax
    mov al, adrB
    mov cx, 1000b
    div cl
    mov rm, ah
    
    xor ah, ah
    div cl
    mov reg, ah  
    mov modd, al
    
    
    xor ax, ax
    mov al, opk
    mov cx, 10b
    div cl
    mov w, ah
    
    div cl
    mov d, ah
    cmp d, 0b

      
    pop cx
    pop ax
    pop bx
    ret
prefix_print:
    push ax
    cmp segmentOff, 0
    jz  prefix_out
    mov cx, 2
    mov ax, segmentOff
    mov dx, offset segments
    add dx, ax
    call print_n
    mov cx, 1
    mov dx, offset colon
    call print_n    
prefix_out:
    pop ax
    ret
   
rm2b:
    push ax
    push bx
    push cx
    ; R/m field
    mov cx, 6
    xor ax, ax
    mov al, rm
    mov bx, 6
    mul bx
    mov dx, offset rmfield
    add dx, ax
    call print_n
    ; +
    mov dx, offset plus
    mov cx, 1
    call print_n
    ; posl1
    mov al, posl2
    call FormatByte
    ; posl2
    mov al, posl1
    call FormatByte
    ; h
    mov dx, offset hex
    mov cx, 1
    call print_n
    ; Bracket
    mov dx, offset bracket
    mov cx, 1
    call print_n
    
    pop cx
    pop bx
    pop ax
    ret
      
rm1b:
    push ax
    push bx
    push cx
    ; R/m field
    mov cx, 6
    xor ax, ax
    mov al, rm
    mov bx, 6
    mul bx
    mov dx, offset rmfield
    add dx, ax
    call print_n
    ; +
    mov dx, offset plus
    mov cx, 1
    call print_n
    ; Poslinkis
    mov al, posl1
    call FormatByte
    mov dx, offset hex
    mov cx, 1
    call print_n
    ; Bracket
    mov dx, offset bracket
    mov cx, 1
    call print_n
    
    
    pop cx
    pop bx
    pop ax
    ret
rm0b:
    push ax
    push bx
  
    xor ax, ax
    cmp rm, 110b
    jne rm0bn_1
    mov dx, offset rmfield
    mov cx, 1
    call print_n
    mov al, posl2
    call FormatByte
    mov al, posl1
    call FormatByte
    mov dx, offset hex
    mov cx, 1
    call print_n
    mov dx, offset bracket
    mov cx, 1
    call print_n
    
    pop bx
    pop ax
    ret
rm0bn_1: ; 6 chars
    cmp rm, 3    
    ja rm0bn_2
    
    mov cx, 6
    xor ax, ax
    mov al, rm
    mov bx, 6
    mul bx
    mov dx, offset rmfield
    add dx, ax
    call print_n
    mov dx, offset bracket
    mov cx, 1
    call print_n
    pop ax
    pop bx
    ret
rm0bn_2: ; size 3 chars
    xor ax, ax
    mov al, rm
    sub al, 4
    mov cx, 3
    mul cx
    mov dx, offset rmfield + 24 ; Skipping elements with 6 chars  
    add dx, ax
    call print_n
   
    mov dx, offset bracket
    mov cx, 1
    call print_n
    
    pop ax
    pop bx
    ret
pos1B:
    push ax
    push bx
    call Read 
    mov bl, buff
    inc count
    mov posl1, bl
    mov al, bl
    call FormatByte
    call print_space
    pop bx
    pop ax
    ret    
pos2B:
    push ax
    push bx
    call Read 
    mov bl, buff
    inc count
    mov posl1, bl
    
    mov al, bl
    call FormatByte
    call print_space
    
    call Read
    mov bl, buff
    inc count
    mov posl2, bl
    
    mov al, bl
    call FormatByte
    call print_space
    
    pop bx
    pop ax
    ret
regp:
    push ax
    push bx
    
    cmp w, 0 
    jne regpn_1
    ; 1 byte
    mov ax, 4
    mov bl, rm
    mul bl
    mov cx, 2
    mov dx, offset registers
    add dx, ax
    call print_n
    pop bx
    pop ax
    ret
regpn_1:
    ; 2 bytes
    mov ax, 4
    mov bl, rm
    mul bl
    add ax, 2
    mov cx, 2
    mov dx, offset registers
    add dx, ax
    call print_n
  
    pop bx
    pop ax
    ret
  
Problemo:
    xor ax, ax 
    mov ah, 09h
    mov dx, offset debug
    int 21h    
    mov ax, 4c00h
    int 21h


    
end start
