.model small
.stack 100h
.data

    X1 dw 0
    X2 dw 0
    Y1 dw 0
    Y2 dw 0

    X dw 0
    Y dw 0

    digit dw 0

    count dw 0

    turnflag db 0
    gamewinflag db 0
    validindexflag db 0
    temp dw 0

    BOARD db 9 dup (0)

    mouseX dw 0
    mouseY dw 0
    mbutton dw 0

    delaylength dw 0

.code
main PROC
    mov ax,@data
    mov ds,ax

    call populatearray

    .while (gamewinflag == 0)
        call Playgame
    .endw

    ;mov byte ptr BOARD[0], 1
    ;mov byte ptr BOARD[3], 2

    ;call Printgrid

    mov ah,4ch
    int 21h    
main ENDP

;func to clear screen
clearscreen PROC uses ax
    mov ah,00
    mov al,12h
    int 10h
    
    ret
clearscreen ENDP

;prints a 3x3 grid on the screen
gridbox PROC uses ax cx dx
    mov ah,0ch
    mov al,0Fh      ;white in color

    mov dx,150

    .while(dx<=330)
         mov cx,230
        .while(cx<=410)
            int 10h
            inc cx
        .endw
        add dx,60
    .endw

    mov cx,230
    .while(cx<=410)
         mov dx,150
        .while(dx<=330)
            int 10h
            inc dx
        .endw
        add cx,60
    .endw

    ret
gridbox ENDP

showmouse PROC uses ax
    mov ax,01h
    int 33h
    ret
showmouse ENDP

;delay
delay PROC uses cx
    mov cx,delaylength

    Startdelay:
        dec cx

        cmp cx,0
        JNE Startdelay

    ret
delay ENDP

;get cordinates
getmousepos PROC uses ax bx cx dx
    Againmousepos:
        mov ax,03h
        int 33h

        mov mouseX,cx
        mov mouseY,dx
        mov mbutton,bx

        mov delaylength,0FFFh
        call delay

        mov ax,1
        int 33h

        cmp mbutton,1
        JNE Againmousepos

    ret
getmousepos ENDP

;returns the index
getindex PROC uses ax bx dx
    mov X,0
    mov Y,0

    .if((mouseX>=230 && mouseX<=410) && (mouseY>=150 && mouseY<=330))
        mov validindexflag,1

        mov dx,0
        mov ax, mouseX
        sub ax,230
        mov bx,60
        div bx

        mov X,ax

        mov dx,0
        mov ax, mouseY
        sub ax,150
        mov bx,60
        div bx

        mov Y,ax

    .else
        mov validindexflag,0

    .endif
    
    ret
getindex ENDP

newline PROC
    mov dx,13
    mov ah,02
    int 21h

    mov dx,10
    mov ah,02
    int 21h

    ret
newline ENDP

printmultidigitnumber PROC
    mov ax,digit
    mov bx,10
    mov cx,0

    PUSHINTOSTACK:
        cmp ax,0
        je POPFROMSTACK

        inc cx
        mov dx,0
        div bx

        PUSH dx

        jmp PUSHINTOSTACK

    POPFROMSTACK:
        cmp cx,0
        je FINISHPRINTING

        dec cx

        pop dx

        add dx,'0'
        mov ah,02
        int 21h

        jmp POPFROMSTACK

    FINISHPRINTING:
        call newline
        ret
printmultidigitnumber ENDP

Playgame PROC
    L1:
        call Printgrid
        mov validindexflag,0
        call showmouse
        call getmousepos

        call getindex

        cmp validindexflag,1
        JNE L1
    
    mov cx,X
    mov dx,Y
    mov Y,cx
    mov X,dx

    mov ax,X
    mov bl,3
    mul bl


    add ax,Y
    mov bx,ax

    .if(byte ptr BOARD[bx]!=0)  
        JMP L1
    .endif

    .if(turnflag==0);tick
        mov byte ptr BOARD[bx],1
       
        call printgrid      
        call Winlogic
        call Youwin
        mov turnflag,1
    .elseif(turnflag==1);cross
        mov byte ptr BOARD[bx],2
        
        call printgrid   
        call Winlogic
        call Youwin
        mov turnflag,0
    .endif
    
    ret
Playgame ENDP

Winlogic PROC
    mov gamewinflag,0
    call verticalcheck
    call horizontalcheck
    call leftdiagnol
    call rightdiagnol

    ret
Winlogic ENDP

Youwin PROC
    .if(gamewinflag==1)
        .if(turnflag==0)
            mov dx,49
            mov ah,02
            int 21h
        .elseif(turnflag==1)
            mov dx,50
            mov ah,02
            int 21h

        .endif

        mov ah,4ch
        int 21h
    .endif
    ret
Youwin ENDP

verticalcheck PROC uses ax bx cx dx si
    mov count,1
    mov ax,X
    mov bx,3
    mul bx
    mov si,ax

    mov bx,Y

    mov dx,X
    dec dx
    mov ch,BOARD[si+bx]

    .while(dx>=0)
        mov ax,dx
        mov cl,3
        mul cl

        mov si,ax
        .if(BOARD[si+bx]==ch)
            inc count
        .else 
            .break
        .endif
        
        dec dx
    .endw
    
    mov dx,X
    inc dx
    .while(dx<3)
        mov ax,dx
        mov cl,3
        mul cl

        mov si,ax
        .if(BOARD[si+bx]==ch)
            inc count
        .else 
            .break
        .endif
        inc dx
    .endw

    .if(count>=3)
        mov gamewinflag,1
    .endif

    ret
verticalcheck ENDP

horizontalcheck PROC uses ax bx cx dx si
    mov count,1
    
    mov ax,X
    mov bx,3
    mul bx
    mov si,ax

    mov bx,Y

    mov ch,BOARD[si+bx]
    dec bx
    .while(bx>=0)
        .if(BOARD[si+bx]==ch)
            inc count
        .else 
            .break
        .endif
        dec bx
    .endw
    
    mov bx,Y
    inc bx
    .while(bx<3)
        .if(BOARD[si+bx]==ch)
            inc count
        .else 
            .break
        .endif
        inc bx
    .endw

    .if(count>=3)
        mov gamewinflag,1
    .endif

    ret
horizontalcheck ENDP

leftdiagnol PROC uses ax bx cx dx si
    mov count,1

    mov ax,X
    mov bx,3
    mul bx
    mov si,ax

    mov bx,Y

    mov dx,X
    mov ch,BOARD[si+bx]
    dec dx
    .while(dx>=0)
        dec bx
        mov ax,dx
        mov cl,3
        mul cl

        mov si,ax
        .if(BOARD[si+bx]==ch)
            inc count
        .else 
            .break
        .endif
        dec dx
    .endw
    
    mov bx,Y
    mov dx,X
    inc dx
    .while(dx<3)
        inc bx
        mov ax,dx
        mov cl,3
        mul cl

        mov si,ax
        .if(BOARD[si+bx]==ch)
            inc count
        .else 
            .break
        .endif
        inc dx
    .endw

    .if(count>=3)
        mov gamewinflag,1
    .endif

    ret
leftdiagnol ENDP

rightdiagnol PROC uses ax bx cx dx si
    mov count,1
    mov ax,X
    mov bx,3
    mul bx
    mov si,ax
    mov bx,Y

    mov dx,X
    mov ch,BOARD[si+bx]
    dec dx
    .while(dx>=0)
        inc bx
        mov ax,dx
        mov cl,3
        mul cl

        mov si,ax
        .if(BOARD[si+bx]==ch)
            inc count
        .else 
            .break
        .endif
        dec dx
    .endw
    
    mov bx,Y
    mov dx,X
    inc dx
    .while(dx<3)
        dec bx
        mov ax,dx
        mov cl,3
        mul cl

        mov si,ax
        .if(BOARD[si+bx]==ch)
            inc count
        .else 
            .break
        .endif
        inc dx
    .endw

    .if(count>=3)
        mov gamewinflag,1
    .endif

    ret
rightdiagnol ENDP

populatearray PROC uses ax bx dx
    mov bx,0

    populatingarray:
        mov byte ptr BOARD[bx],0

        inc bx

        cmp bx,9
        jne populatingarray

    ret
populatearray ENDP

printarray PROC uses ax bx dx
    mov bx,0
    mov dx,0
    printingarray:
        mov dl,BOARD[bx]
        add dl,'0'
        mov ah,02
        int 21h

        inc bx

        cmp bx,9
        jne printingarray

    ret
printarray ENDP

;prints grid and shapes on the screen
Printgrid PROC uses bx cx dx
    call clearscreen
    call gridbox

    mov cx,230
    mov dx,150
    mov bx,0

    .while(bx<9)
        .if(BOARD[bx]==1)
            mov X1,cx
            add X1,10

            mov X2,0

            mov Y1,dx
            add Y1,35

            mov Y2,dx
            add Y2,45

            call tick
        .elseif(BOARD[bx]==2)
            mov X1,cx
            add X1,10

            mov X2,cx
            add X2,50

            mov Y1,dx
            add Y1,10

            mov Y2,dx
            add Y2,50

            call cross
        .endif

        .if(cx==350)
            mov cx,230
            add dx,60
        .else
            add cx,60
        .endif

        inc bx
    .endw

    ret
Printgrid ENDP

;draws a tick on the board
tick PROC uses ax cx dx
    mov ah,0ch
    mov al,02h

    mov cx,X1
    mov dx,Y1
    .while(dx<Y2)
        int 10h
        inc cx
        inc dx
    .endw

    sub Y1,20
    .while(dx>=Y1)
        int 10h
        dec dx
        inc cx
    .endw
    
    ret
tick ENDP

;draws a cross on the board
cross PROC uses ax cx dx
    mov ah,0ch
    mov al,04h

    mov cx,X1
    mov dx,Y1
    .while(dx<Y2)
        int 10h
        inc cx
        inc dx
    .endw

    mov cx,X1
    .while(dx>=Y1)
        int 10h
        inc cx
        dec dx
    .endw

    ret
cross ENDP

end main