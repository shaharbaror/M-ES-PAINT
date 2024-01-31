IDEAL
MODEL small
STACK 100h

DATASEG
; --------------------------
;Vars here
   
    ;the data bytes variables ==========================================================

    mainBrushColor db ? ;the color of the brush

    lastBrushColor db ? ;the last color chosen
    sideBarColor db 0fh ;the color of the side bar
    eraserColor db 7h

 
    mainScreenFile db 'test.bmp',0 
	homePageFile db 'HomeP.bmp',0
    
    header db 54 dup(0)
    Palette db 256*4 dup(0)
    scrLine db 320 dup(0)
    ErrorMsg db 'Error',13,10,'$'
 

	ripMouseText db 'rip mouse',13,10,'$'
    ;the double word variables ==========================================================

	mainBrushSize dw 5  ;the brush size


	fileHandle dw ?

   	indicatorPos dw 52	;indicates the position of the thing that marks your position on the side bar

	counter1 dw 0	;a counter to count for loops
	counter2 dw 0	;;a counter to count for loops


	topDrawingLimit dw 32		;a limiter to the brush places
	rightDrawingLimit dw 320	;a limiter to the brush places
	leftDrawingLimit dw 0		;a limiter to the brush places
	
	
	startXV dw ?    ;start value of the x for creating a shape
    startYV dw ?    ;start value of the y for creating a shape
    endXV dw ?      ;end value of the x for creating a shape
    endYV dw ?      ;end value of the y for creating a shape

	;the booleans ================================================================
   
   	isDraw db 1 ;a boolean that tells if you can draw or not
	isOnbar db 0
	isNotHomePage db 0
   
; --------------------------
 
CODESEG
start:
    mov ax, @data
    mov ds, ax

; --------------------------
;Code here
 
 
;Set graphics mode 300x200x256

 
 
mov ax,13h
int 10h

;call main		;start the whole program
call main

proc SetCursor
 
    ;reset the mouse
    mov ax,0h
    int 33h
    ;Showing the mouse on the board
    mov ax,1h
    int 33h
 
    ret
endp SetCursor
proc CursorPos
    
    mov ah,2
    mov bh,0
    int 10h

    ret
endp CursorPos
 
proc OpenFile   
 
    mov ah,3Dh
    xor al,al
    lea dx, [mainScreenFile]
    int 21h
    jc openerror
    mov [fileHandle],ax
    ret
    openerror:
 
    lea dx, [ErrorMsg]
    mov ah,9h
    int 21h
    ret
endp OpenFile
 
proc ReadHeader
    mov ah,3fh
    mov bx,[fileHandle]
    mov cx,54
    lea dx,[header]
    int 21h
    ret
endp ReadHeader
 
proc ReadPalette
    mov ah,3fh
    mov cx,400h
    lea dx,[Palette]
    int 21h
    ret
endp ReadPalette
 
 
proc CopyPal
 
    ; Copy the colors palette to the video memory
	; The number of the first color should be sent to port 3C8h
	; The palette is sent to port 3C9h
	lea si, [Palette]
	mov cx, 256
	mov dx, 3C8h
	mov al, 0
	; Copy starting color to port 3C8h
	out dx, al
	; Copy palette itself to port 3C9h
	inc dx
	PalLoop :
	;Colors in a BMP file are saved as BGR values rather than RGB .
	mov al, [si+2] ; Get red value .
	shr al, 2 ; Max. is 255, but video palette maximal
	; value is 63. Therefore dividing by 4.
	out dx, al ; Send it .
	mov al, [si+1] ; Get green value .
	shr al, 2
	out dx, al ; Send it .
	mov al, [si] ; Get blue value .
	shr al, 2
	out dx, al ; Send it .
	add si, 4 ; Point to next color .
	; (There is a null chr. after every color.)
	loop PalLoop 
    ret
endp CopyPal
 
proc CopyBitmap
 
    ; BMP graphics are saved upside-down .
	; Read the graphic line by line (200 lines in VGA format), 
	; displaying the lines from bottom to top.
	mov ax, 0A000h
	mov es, ax
	mov cx, 200
	PrintBMPLoop :
        push cx
        ; di = cx*320, point to the correct screen line
        mov di, cx
        shl cx, 6
        shl di, 8
        add di, cx
        ; Read one line
        mov ah, 3fh
        mov cx, 320
        lea dx, [scrLine]
        int 21h
        ; Copy one line into video memory
        cld ; Clear direction flag, for movsb
        mov cx, 320
        lea si, [scrLine] 
        rep movsb ; Copy line to the screen
        ;rep movsb is same as the following code :
        ;mov es:di, ds:si
        ;inc si
        ;inc di
        ;dec cx
        ;loop until cx=0
        pop cx
	loop PrintBMPLoop 
    ret
endp CopyBitmap
 
 
 
 
 
;this procedure wait untill there is a left click on the mouse and returns the x and y values of it
proc GetMouseInput
 
 
    MouseInput:             ;start of the loop to get the mouse input
        mov ax,3h   
        int 33h
        cmp bx,00000001B    ;check if there was a left click on the mouse
    jne MouseInput  
   
    shr cx,1                ;the cx is the x value and it starts twice as big as the X value, so divide by 2
    dec dx                  ;decrease the y value by 1 so the mouse pointer wouldnt get in the way of drawing or clicking
   
    ret
endp GetMouseInput

;this procedure wait untill the left click button on the mouse is released and returns the x and y values of it
proc GetMouseUp
   
    _MouseUp:
        mov ax,3h
        int 33h
        cmp bx,1
    je _MouseUp
    shr cx,1
    dec dx
   
    ret
endp GetMouseUp
 
 
;this procedure will draw a pixel with the brush size on the x and y values of the mouse
proc PrintPixel
    mov bh,0
    mov ah,0Ch
    cmp [isDraw],1                      ;if the boolean "isDraw" equals to 1 then draw with the "mainBrushColor" color, else change it to earaser color
    jne _ErasePixel
		mov al,[mainBrushColor]         ;moves the main brush color to al for the drawing
		;int 10h -------------------------------
        jmp _ToPrint                    ;jumps to printing the pixel
    _ErasePixel:                        ;if "isDraw" equals 0 the go here
        mov al,[eraserColor]            ;moves the eraser color to al

	_ToPrint:                           ;the start of printing
		push ax                         ;pushing ax to save it in the stack
		mov ax,[mainBrushSize]          ;moving ax the brush size
		shr ax,1
		sub cx,ax
		mov [counter1],0
		_PixelYLoop:
			add cx,[mainBrushSize]
			mov [counter2],0
			_PixelXLoop:
				pop ax                  ;getting ax back from the stack
				int 10h
				dec cx
				inc [counter2]
				push ax                 ;save ax in the stack
				mov ax,[counter2]
				cmp ax,[mainBrushSize]      ;checking if the counter2 value equals to the brush size if yes then continue, else then jump to _pixelXLoop
			jne _PixelXLoop
			
			inc [counter1]
			dec dx
			mov ax,[counter1]
			cmp ax,[mainBrushSize]          ;checking if the counter1 value equals to the brush size if yes then continue, else then jump to _pixelYLoop
		jne _PixelYLoop
		pop ax                         ;get ax back from the stack
    ret
endp PrintPixel
 
proc GetPixel ;THIS FUNCTION GETS THE PIXEL THEW MOUSE IS CURRENTLY ON
    mov ah,0Dh
    int 10h
    mov [mainBrushColor],al
    mov [lastBrushColor],al
    mov [isDraw],1

	
	push 30
	push 13
	push 143
	push 126
	call DrawCube       ;changes the color of the cube that shows what color the user is using


    ret
endp GetPixel
 
 
proc GetCubeD
	call GetMouseUp			;checks when the user stopped clicking the button
    call GetMouseInput		;gets the first cordinates
    mov [startXV],cx		;import the x cordinates
    mov [startYV],dx		;import the y cordinates
    call GetMouseUp			;checks when the user stopped makeing a cube
    mov [endXV],cx			;imports the x cordinates
    mov [endYV],dx			;imports the y cordinates

    cmp cx,[startXV]		;checks if the start value is bigger than the end value
    jnb _UseEndX
        push cx             ;pushes cx and saves in in a stack
        mov cx,[startXV]    ;mov the start x value to cx
        mov [endXV],cx      ;move start x value to the end value
        pop cx              ;get cx back from the push
        mov [startXV],cx    ;move the "end value" cx to the start value x
    _UseEndX:
    cmp dx,[startYV]
    jnb _UseEndY
        push dx             ;pushes dx and saves in in a stack
        mov dx,[startYV]    ;move the start of y value to dx
        mov [endYV],dx      ;move start y value to the end y value
        pop dx              ;get the dx with the last end value
        mov [startYV],dx    ;move the end value to the start value
    _UseEndY:

	cmp [startYV],32		;checks if the cube is on the side bar
	jnb _ContinueWithCube	;if it isn't continue to check
		ret					;if it is then stop
	_ContinueWithCube:
 
	mov al,[mainBrushColor]
    push [endYV]
    push [startYV]
    push [endXV]
    push [startXV]
    call DrawCube
 
 
    ret
endp GetCubeD
 
 
 
;this procedure will get the start x and y values and the end x and y values and make with them a cube
proc DrawCube
    mov bp,sp
   
    mov dx,[bp +6]      ;moving dx the start y value

	dec dx              ;decreasing dx so when we increase it in the beginning of the loop it will be the original one 

    mov bh,0
    mov ah,0Ch
    _CubeYLoop:
		inc dx      ;increasing dx so the loop wont be infinte
        mov cx,[bp +2]      ;moving the start x value to cx
		dec cx      ;the same reasong we did with dx
        _CubeXLoop:
			inc cx              ;the same reason we did with dx 
			int 10h
			cmp cx,[bp +4]      ;comparing cx with the end x value
        jne _CubeXLoop

		cmp dx,[bp+8]       ;comparing dx with the end y value
	jne _CubeYLoop
 
    ret 8
endp DrawCube
 
proc UpdateBar 				;this function will show the current size on the bar
    mov bp,sp
    
    
	;mov ax,[bp+2]
    ;mov [iandictorPos],ax
    ;pop ax
    xor ax,ax   ;reset the cursor so that the cursor wont interfere with the bar
    mov ah,0h
    int 33h
    mov ax,[bp+2]
    push ax

	mov al,0
	push 31
	push 24
	push 118
	push 50
	call DrawCube           ;reset the size bar color to black
    pop ax
	push 31
	push 24
	inc ax
    push ax
	dec ax
	push ax
    mov [indicatorPos],ax
    xor ax,ax
    mov al, 0fh
	call DrawCube       ;showing the size indicator on the size bar
    xor ax,ax
    call SetCursor  ;get the cursor back on the screen


	ret 4
endp UpdateBar
 
 
 
proc CheckIfButton
	cmp dx,32
	jnb _NotSizeBar
    cmp cx,37 				;CHECKS IF MOUSE CLICKED ONE OF THE COLOURS IN THE CUBE
    jnb _NotColourCube
        call GetPixel
        ret
    _NotColourCube:
    cmp dx,15
    jnb _NotBrushBtn 		;CHECKS IF THE MOUSE CLICKED ONE OF THE BUTTONS
       
        cmp cx,51 			;CHECK IF THE MOUSE CLICKED DRAW
        jnb _NotDrawMode
            mov [isDraw], 1
            ret
        _NotDrawMode:
       
        cmp cx,65   		;CHECK IF MOSUE CLICKED ERASE
        jnb _NotEraseMode
            mov [isDraw],0
            ret
        _NotEraseMode:
 
        cmp cx,80   		;CHECK IF MOUSE CLICKED MAKE CUBE
        jnb _NotMakeCube
            call GetCubeD
            ret
        _NotMakeCube:

		cmp cx,290		;if pressed exit the program
		jna _NotExit
			call FinishProgram
		_NotExit:

        ret
    _NotBrushBtn:

	cmp dx,30
	jnb _NotSizeBar     ;check if the mouse is on the size bar
	cmp dx,23
	jna _NotSizeBar
	cmp cx,50
	jna _NotSizeBar
	cmp cx,117
	jnb _NotSizeBar     
	cmp [isOnbar],1
	je _ChangeSize
		mov [isOnbar],1
		call GetMouseUp     ;calling GetMouseUp to see where the mouse is on the bar when the clicked buttong was realesed
		jmp _NotBrushBtn
	_ChangeSize:
		mov [isOnbar],0
		mov [mainBrushSize],cx      ;mov  cx to the brush size 
		sub [mainBrushSize],47      ;decrese it by 47 to get the size on the bar itself and not on the screed
		;shr [mainBrushSize],1
        push cx
		call UpdateBar              ;change the indicator position
	_NotSizeBar:
    mov [isOnbar],0
   
    ret
endp CheckIfButton
 
proc openFiles      ;opening the main screen and displaying it
 
    call OpenFile
    call ReadHeader
    call ReadPalette
    call CopyPal
    call CopyBitmap
 
    ret
endp openFiles
 
;THIS FUNCTION WILL BE CALLED IF YOU PRESSED THE MOUSE ON DRAW AND CHECK IF YOU CAN DRAW ON THE CURRENT POSTITION
proc IsPrint
	mov [topDrawingLimit],32
	mov [leftDrawingLimit],0
	mov [rightDrawingLimit],319
	
	
	push ax
	mov ax,[mainBrushSize]
	add [topDrawingLimit],ax
	
	shr ax,1
	sub [rightDrawingLimit],ax

	sub ax,2
	mov [leftDrawingLimit],ax

	pop ax

	cmp cx,[leftDrawingLimit]
	jna _NotPrint

    cmp dx,[topDrawingLimit]
    jna _NotPrint

	cmp cx,[rightDrawingLimit]
	jnb _NotPrint
    	call PrintPixel
    	ret
    _NotPrint:
    call CheckIfButton
 
 
    ret
endp IsPrint
 
;THIS IS THE MAIN FUNCTION THAT CALLS AND MANAGE ALL OF THE OTHER FUNCTIONS
proc main
    mov [mainBrushColor],4
    call openFiles
    call SetCursor
	
	mov ah,0Dh
    int 10h                     ;gets the color of the board and inserts it into al
    mov [eraserColor],al        ;insert the color of the boar to the eraser color and to the main brush color
	mov [mainBrushColor],al
	xor ax,ax
	;push 31
	;push 24
	;push [indicatorPos]
	;sub [indicatorPos],2
	;push [indicatorPos]
	;call DrawCube           ;prints the indicator on the size bar so that you can see your brush size from the beginning
	;add [indicatorPos],2
	;xor ax,ax

    ;mov [indicatorPos],47
    ;mov ax,[mainBrushSize]
    ;add [indicatorPos],ax
    ;push [indicatorPos]
    mov ax,47
    add ax,[mainBrushSize]
    push ax
    call UpdateBar
    xor ax,ax



    _MainLoop:
        call GetMouseInput
       
        call IsPrint
       
       
    jmp _MainLoop
    ret
endp main

proc FinishProgram
	mov ax,2h
	int 10h

	xor dx,dx
	lea dx,[ripMouseText]
	mov ah,9h
	int 21h
	jmp exit
	ret
endp FinishProgram
 
;--------------------------
   
   
exit:
    mov ax, 4c00h
    int 21h
END start
