;*******************************************
;*           Text Mode Up Scroller         *
;*                  v1.0                   *
;*                                         *
;*                Coding By                *
;*           G”ran "Gurra" Nylen           *
;*                                         *
;*******************************************
		.MODEL  compact         ; Large DataSegments
		.STACK  512h            ; SetUp a StackSegment
		Jumps                   ; Setting Long Jumps
		.486                    ; Enable All 486 Commands.
		.Data                   ; SetUp a DataSegment
;****************************************************************************
;*************************** Datas & Variables ******************************
;****************************************************************************
WaitValue	equ	30		;
DataStart	dw	0		;
SaveINT         db      0,0             ;                
ScrollPtr	db	0		;
ScrollWait	db	0		;
		.Code                   ; SetUp a CodeSegment
;****************************************************************************
;***************************** Init Routines ********************************
;****************************************************************************
Init:           Assume  Cs:@Code,Ds:@Data,Es:@Data,SS:@Stack
		mov     ax,Seg DataStart; Get address to where all the variables
		mov     ds,ax		; are going to be stored.
		call    CloseSystem	; Disable ComPorts, HardDrive etc.
;****************************************************************************
;****************************** Main Loop ***********************************
;****************************************************************************
MainLoop:       call    WaitVbl         ; Wait For Vertical Blanking
		call	UpScroll	; Scroll The Screen Up

		mov     dx,60h          ; Get Keyboard Port Value
		in      al,dx           ; Read Value from port into AL
		cmp     al,1            ; Check If AL contains the code for ESC
		jne     MainLoop        ; If not, then go back to MainLoop
;***************************************************************************
;*********************** Let Us Exit Nice And Quiet ************************
;***************************************************************************
Exit:        	call	RestoreMode	;
		call    OpenSystem      ;
		mov     ax,0c00h        ; Clear Keyboard function
		int     21h             ; Clear It!
		mov     ax,0003h        ; Set back to the standard
		int     10h             ; dos gfx mode. (Nr.3)
		mov     ax,4c00h        ; Exit Nice And Quietly
		int     21h             ; Without Any Trouble To Dos.
;****************************************************************************
;**************************** Wait Vbl Routine ******************************
;****************************************************************************
WaitVbl:        mov     dx,3dah         ; Move rasterport into DX.
		in      al,dx           ; Move rasterportvalue into al.
		test    al,8h           ; Check If Vbl Bit is set.
		jz      WaitVbl         ; If Not, then go back & check again.
		ret
;****************************************************************************
;********************** Scroll the text mode screen up **********************
;****************************************************************************
UpScroll:	cmp	ScrollWait,WaitValue ;
		jae	OkScrollAhead	     ;
		add	ScrollWait,1	     ;
		ret

OkScrollAhead:	mov	ScrollWait,0
		mov	dx,3d4h		;
		mov	al,8		; Enable Interlace Mode
		out	dx,al		;
		mov	dx,3d5h		;
		mov	al,ScrollPtr	;
		out	dx,al		;
		add	ScrollPtr,1	;
		and	ScrollPtr,15	;
		ret
;****************************************************************************
;*********************** Restore the interlace values ***********************
;****************************************************************************
RestoreMode:	mov	dx,3d4h		;
		mov	al,8		;
		out	dx,al		;
		mov	dx,3d5h		;
		mov	al,0		;
		out	dx,al		;
		ret
;****************************************************************************
;*********************** Turn off System Interrupts *************************
;****************************************************************************
CloseSystem:    mov     dx,021h         ; Get Masking Port
		in      al,dx           ; Get Value from port
		mov     SaveINT,al      ; Save it,so it can be restored at exit
		mov     al,10111111b    ; Let keyboard only, be enabled.
		out     dx,al           ; Write the new setting to MaskPort.
		ret                     ;
;****************************************************************************
;*********************** System Interrupts Back on  *************************
;****************************************************************************
OpenSystem:     mov     dx,021h         ; Get Masking Port
		mov     al,SaveINT      ; Get old value setting
		out     dx,al           ; Write the old setting to MaskPort.
		ret                     ;
;****************************************************************************
;************* Here goes all the big buffers and stuff like that ************
;****************************************************************************
		;.FarData
;****************************************************************************
;***************************** Ending Correctly *****************************
;****************************************************************************
		End     Init
		End      
