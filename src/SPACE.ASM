;******************************************
;*              Screen Blanker            *
;*                   v1.0                 *
;*                                        *
;*                Coding By               *
;*           Gîran "Gurra" NylÇn          *
;*                    &                   *
;*         Johan "Hellcat" Eriksson       *
;*                                        *
;******************************************
		.MODEL  huge            ; Large DataSegments
		.STACK  320h            ; SetUp a StackSegment
		Jumps                   ; Setting Long Jumps
		Smart
		.486                    ; Enable All 486 Commands.
		.FarData Morphs         ; DataSegment For Variables
;****************************************************************************
;****************** Datas & Variables For The Morphing Routine **************
;****************************************************************************
MorphStart              dw      0
PlotXcoord              dw      0
PlotYcoord              dw      0
PlotZcoord              dw      0
NumberMorphCoordsLoop   dw      0
Steps                   dd      320
StepCounter             dd      0
XYZcoordsOnScreenTable  dw      500*3 dup (0)   ; 3 = X,Y,Z... 500 = NrOfStars
MorphCoordsAdressTable  dw      NumberOfStars dup (0)
MorphStepTable          db      36*NumberOfStars dup (0)
NewTextCoordsBuffer     dw      3*5*173 dup (0)

		Include TextCord.Asm
		Include RndTxt.Asm
			even

			;      0          2        4         8
			; StepXSign(dw) x2(dw) StepX(dd) TmpX(dd)
			; StepYSign(dw) y2(dw) StepY(dd) TmpY(dd) 
			;     12          14       16       20
			;     24          26       28       32      (36)
			; StepZSign(dw) z2(dw) StepZ(dd) TmpZ(dd)

		.Code Blanker               ; SetUp a CodeSegment
;****************************************************************************
;****************** Datas & Variables For the Space Routine *****************
;****************************************************************************
Start:
NumberOfMorphCoords     equ     173; Tryck=57, En=28, Tangent=88
FontHeight              equ     10                       
FontWidth               equ     8
NumberOfStars           equ     500
Cpu8086                 equ     1
Cpu80286                equ     2
Cpu80386                equ     3
Cpu80486                equ     4
CharBuffer              dw      320*12 dup (0)
Buffer                  dw      0
Bunker                  dw      0
SpeedCounter            dw      0
FrameCounter            dw      0
HiddenPekare            dw      0
CalcedTablePointer      dw      0
CharCounter             dw      0
CharBufferLineCounter   dw      0
TextPointer             dw      0
LineInFont              dw      0
CharBufferPointer       dw      0
SinTableAddress         dw      0
Zspeed                  dw      0       ; Pixels / Frame 
Yspeed                  dw      0       ; Pixels / Frame + 256 
Xspeed                  dw      0       ; Pixels / Frame + 256 
ProjZ                   dw      100     ; Projektions centrum Z-coord
TreHundraTjugo          dw      320
Eight                   dw      8
OldXspeed               dw      0
OldYspeed               dw      0
OldZspeed               dw      0
WaitValue               dw      0
SpaceControl            dw      0
FirstTime               dw      0
TextCoordsAddPointer    dw      0
MaskingRegister         db      0
LastChar                db      1fh
HiddenKey               db      0
HiddenString            db      2eh,13h,12h,20h,17h,14h,1fh     ; credits
Red                     db      0
Green                   db      0
Blue                    db      0
RedSubValue             db      0
GreenSubValue           db      0
BlueSubValue            db      0
KeyPortValue            db      0
			db      0
Text1           db      'HAHAHAHAHAHA!!! Du har ju fîr fan bara en 8086!!$'
Text2           db      'HAHAHAHAHAHA!!! Du har ju fîr fan bara en 286!!!$'
			even
			Include ScrolTxt.Asm
			Include Coords.Asm
			Include Sintab0.Asm
			Include Sintab1.Asm
			Include Sintab2.Asm
			Include Sintab3.Asm
			Include Sintab4.Asm
			Include Sintab5.Asm
			Include Sintab6.Asm
			Include Sintab7.Asm

CalcedCoordTable        dw 500 dup (0)
XtableNeg               dw 4096 dup (0)
Xtable                  dw 4096 dup (0)
YtableNeg               dw 4096 dup (0)
Ytable                  dw 4096 dup (0)
;****************************************************************************
;***************************** Init Routines ********************************
;****************************************************************************
Init:           Assume  Cs:@Code,Ds:@Code
		call    GetCpuType              ;
		call    LoaderRoutines          ;
		mov     ax,Seg Start            ; Set DS to start of code
		mov     Ds,ax                   ;
		mov     ax,0c00h                ; Empty the keyboard buffer
		int     21h                     ;
		;call   MaskingRegisterShutDown ;
		;call    GetTimeForSinTable      ;
		call    OnlyTab0                ; USE TO TEST SINUS TABLE!
Restart:        call    GetPalette              ;
		call    CreateXYtable           ;
		mov     ax,Seg Start            ;
		mov     Ds,ax                   ;
		mov     Es,ax                   ;
		mov     Fs,ax                   ;
		mov     Gs,ax                   ;
		shl     ProjZ,7                 ;
		call    ReadCurrentKeyPortValue ;
;****************************************************************************
;****************************** Main Loop ***********************************
;****************************************************************************
MainLoop:       call    WaitVbl
		;call   ColorizeScreen
		call    ClearSpace
		call    Space
		call    CheckKeyboard
		call    CheckTheTime
		;call   BlankScreen
		jmp     MainLoop

;***************************************************************************
;*********************** Let Us Exit Nice And Quiet ************************
;***************************************************************************
Exit:           ;call   RestoreMaskingRegister  ;
		mov     ax,0c00h                ; Clear the keyboard buffer
		int     21h                     ;
		mov     ax,0003h                ; Set back to the standard
		int     10h                     ; dos gfx mode. (Nr.3)
		mov     ax,4c00h                ; Exit Nice And Quietly
		int     21h                     ; Without Trouble To Dos.
;****************************************************************************
;**************************** Wait Vbl Routine ******************************
;****************************************************************************
WaitVbl:        mov     dx,3dah         ; Move rasterport into DX.
		in      al,dx           ; Move rasterportvalue into al.
		test    al,8h           ; Check If Vbl Bit is set.
		jz      WaitVbl         ; If Not, then go back & check again.
		ret
;****************************************************************************
;****************************** Read Port $060 ******************************
;****************************************************************************
ReadCurrentKeyPortValue:
		mov     dx,60h          ; Read the port $60 which tells you
		in      al,dx           ; witch key was last pressed and store
		mov     KeyPortValue,al ; the value in "KeyPortValue".
		ret
;***************************************************************************
;***************** Check And Exit If A Wrong Key Is Pressed ****************
;***************************************************************************
CheckKeyboard:  push    ds              ;
		mov     ax,Seg Start    ;
		mov     Ds,ax           ;
		mov     ax,0c00h        ; Clear the keyboard buffer
		int     21h             ;
		mov     dx,60h          ;
		in      al,dx           ;
		cmp     al,80h          ;
		ja      SkipIt          ;
		cmp     al,KeyPortValue ; 
		jne     AkeyWasPressed  ;
SkipIt:         pop     Ds              ;
		ret

AkeyWasPressed: mov     bx,Seg HiddenString     ;
		mov     Es,bx                   ;
		mov     si,Offset HiddenString  ; Read the next hidden key
		add     si,HiddenPekare         ; from table
		mov     ah,es:[si]              ;

		cmp     al,ah                   ; If a hidden key wasn't
		jne     Exit                    ; pressed, then exit

		cmp     ah,LastChar             ;
		je      HiddenPart              ; A hidden key was pressed but,
		add     HiddenPekare,1          ; not the last one, so lets go
		call    ReadCurrentKeyPortValue ; on as usual.
		pop     Ds                      ;
		ret                             ;
;****************************************************************************
;*************************** 3D Space!! Routine *****************************
;****************************************************************************
Space:          mov     ax,Seg Coords           ;
		mov     Ds,ax                   ;
		mov     si,SinTableAddress
		add     si,SpeedCounter
		mov     CalcedTablePointer,0

		cmp     SpaceControl,0
		je      GoOnAsUsual
		cmp     SpaceControl,1
		je      SlowDownSpaceValue
		cmp     SpaceControl,2
		je      SpeedUpSpaceValue

GoOnAsUsual:    add     FrameCounter,1
		cmp     FrameCounter,4
		jne     NoNewSpeedValue
		mov     FrameCounter,0

		cmp     Word Ptr [si]+3*2,100
		jne     NoReset
		mov     SpeedCounter,0
		mov     si,SinTableAddress
NoReset:        add     SpeedCounter,3*2        ; words!

NoNewSpeedValue:mov     cx,[si]                 ;
		mov     AddZs,cx                ;
		mov     cx,[si]+2               ;
		mov     AddYs,cx                ;
		mov     cx,[si]+4               ;
		mov     AddXs,cx                ;

		mov     si,Offset Coords        ; si = Coords
		mov     bx,Offset Xtable        ; bx = Xtable
		mov     bp,Offset Ytable        ; bp = Ytable
		mov     ax,0a000h               ; es:di = Eva Braun
		mov     Es,ax                   ;
		mov     di,0                    ;

		mov     cx,NumberOfStars        ;
CalcDots:       
		db      81h,04h                 ; add   [si],Zspeed 
AddZs           dw      0                       ; 
		and     Word Ptr[si],0ffh       ;
		db      81h,44h,02h             ; add   [si]+2,Xspeed
AddXs           dw      0                       ;
		and     Word Ptr [si]+2,1ffh    ;
		sub     Word Ptr [si]+2,256     ;
		db      81h,44h,04h             ; add   [si]+4,Yspeed
AddYs           dw      0                       ;
		and     Word Ptr [si]+4,1ffh    ;
		sub     Word Ptr [si]+4,256     ;

		xor     dx,dx
		mov     ax,ProjZ
		add     Word Ptr [si],100
		div     Word Ptr [si]
		sub     Word Ptr [si],100
		mov     Buffer,ax

		mul     Word Ptr [si]+2
		sar     ax,7

		add     bx,ax                   ; X
		add     bx,ax                   ;
		mov     ax,[bx]                 ;
		add     ax,0                    ;
		jz      NoPixel                 ;

		mov     Bunker,ax
		mov     ax,Buffer
		mul     Word Ptr [si]+4
		sar     ax,7

		add     bp,ax                   ; Y
		add     bp,ax                   ;
		mov     dx,Ds:[bp]              ;
		add     dx,0                    ;
		jz      NoPixel                 ;

		mov     ax,Bunker                                               
		add     ax,dx                   ; X + Y
		mov     dx,[si]                 ; HÑmtar Z
		mov     di,ax                   ;
		mov     Es:[di],dl              ; Set Pixel!

		mov     di,Offset CalcedCoordTable
		add     di,CalcedTablePointer   ;
		add     CalcedTablePointer,2    ;
		mov     Ds:[di],ax              ; Save Coord (to be erased)

NoPixel:        mov     bp,Offset Ytable
		mov     bx,Offset Xtable
		add     si,6
		dec     cx                      ;
		jnz     CalcDots                ;
		mov     di,Offset CalcedCoordTable
		add     di,CalcedTablePointer   ;
		add     CalcedTablePointer,2    ;
		mov     Word Ptr Ds:[di],0ffffh ; Save EndOfTable Value
		ret

SlowDownSpaceValue:
		push    Es
		mov     cx,Seg Start            ;
		mov     Es,cx                   ;
		cmp     Es:FirstTime,1          ;
		jne     SlowDownSkip            ;
		mov     cx,[si]                 ; Read The Current SpeedValues
		mov     Es:Zspeed,cx            ; Z
		mov     Es:OldZspeed,cx         ;
		mov     cx,[si]+2               ;
		mov     Es:Yspeed,cx            ; Y
		mov     Es:OldYspeed,cx         ;
		mov     cx,[si]+4               ;
		mov     Es:Xspeed,cx            ; X
		mov     Es:OldXspeed,cx         ;
		mov     Es:FirstTime,0          ; Reset FirstTime Value
SlowDownSkip:   mov     si,Offset Zspeed        ;
		pop     Es                      ;
		jmp     NoNewSpeedValue         ;       

SpeedUpSpaceValue:mov   si,Offset Zspeed
		jmp     NoNewSpeedValue
;****************************************************************************
;****************** Copy The Double Buffer To The Screen ********************
;****************************************************************************
ClearSpace:     mov     ax,0a000h
		mov     es,ax
		mov     ax,Seg CalcedCoordTable
		mov     ds,ax
		mov     si,Offset CalcedCoordTable

		mov     ax,0
		mov     cx,NumberOfStars
ClsLoop:        mov     di,ds:[si]
		stosb                   ; es:di
		add     si,2
		dec     cx
		jnz     ClsLoop
		ret
;****************************************************************************
;************************* Check If It's Time To Morph **********************
;****************************************************************************
CheckTheTime:   pusha
		mov     ah,2ch          ; Get current second
		int     21h             ;
		;and    dh,1111b        ; 0-15 seconds.... To Be Removed!!!
		cmp     dh,0            ; Check If It Has Passed One Minute
		jne     ExitTimeCheck   ;
		call    SlowTheSpaceDown;
		call    StartMorph      ;
		call    SpeedTheSpaceUp ;
ExitTimeCheck:  popa
		ret
;****************************************************************************
;************************ Slow Down The Space Ride **************************
;****************************************************************************
SlowTheSpaceDown:
		mov     ax,Seg Start    ;
		mov     ds,ax           ;
		mov     FirstTime,1     ; Set To Read Speed Values..
		mov     WaitValue,8     ;
		mov     SpaceControl,1  ; Slow Down!
SlowDownLoop:   call    WaitVbl         ;
		call    ClearSpace      ;
		call    Space           ;
		call    CheckKeyboard   ;
		mov     ax,Seg Start    ;
		mov     ds,ax           ;
		dec     WaitValue       ;
		jnz     SlowDownLoop    ;
		mov     WaitValue,8     ;

		cmp     Xspeed,256      ;
		je      XisDone         ;
		cmp     Xspeed,256      ;
		ja      SubX            ;
		add     Xspeed,1        ;
		jmp     XisDone         ;
SubX:           sub     Xspeed,1        ;

XisDone:        cmp     Yspeed,256      ;
		je      YisDone         ;
		cmp     Yspeed,256      ;
		ja      SubY            ;
		add     Yspeed,1        ;
		jmp     YisDone         ;
SubY:           sub     Yspeed,1        ;

YisDone:        cmp     Zspeed,0        ;
		je      ZisDone         ;
		cmp     Zspeed,0        ;
		jl      SubZ            ;
		sub     Zspeed,1        ;
		jmp     ZisDone         ;
SubZ:           add     Zspeed,1        ;

ZisDone:        cmp     Xspeed,256      ;
		jne     SlowDownLoop    ;
		cmp     Yspeed,256      ;
		jne     SlowDownLoop    ;
		cmp     Zspeed,0        ;
		jne     SlowDownLoop    ;
		call    WaitVbl         ;
		call    ClearSpace      ;
		call    Space           ;
		mov     SpaceControl,0  ; Go Back to Normal Space Traveling
		ret
;****************************************************************************
;************************ Speed Up The Space Ride ***************************
;****************************************************************************
SpeedTheSpaceUp:mov     ax,Seg Start    ;
		mov     ds,ax           ;
		mov     WaitValue,10    ;
		mov     SpaceControl,2  ; Speed Up!
SpeedUpLoop:    call    WaitVbl         ;
		call    ClearSpace      ;
		call    Space           ;
		call    CheckKeyboard   ;
		mov     ax,Seg Start    ;
		mov     ds,ax           ;
		dec     WaitValue       ;
		jnz     SpeedUpLoop     ;
		mov     WaitValue,10    ;

		mov     ax,OldXspeed    ;
		cmp     Xspeed,ax       ; 256 - 256
		je      XisDone2        ;
		cmp     Xspeed,ax       ; 256 - 250
		ja      SubX2           ;
		add     Xspeed,1        ;
		jmp     XisDone2        ;
SubX2:          sub     Xspeed,1        ;

XisDone2:       mov     ax,OldYspeed    ;
		cmp     Yspeed,ax       ;
		je      YisDone2        ;
		cmp     Yspeed,ax       ;
		ja      SubY2           ;
		add     Yspeed,1        ;
		jmp     YisDone2        ;
SubY2:          sub     Yspeed,1        ;

YisDone2:       mov     ax,OldZspeed    ;
		cmp     Zspeed,ax       ;
		je      ZisDone2        ;
		cmp     Zspeed,ax       ;
		jl      SubZ2           ;
		sub     Zspeed,1        ;
		jmp     ZisDone2        ;
SubZ2:          add     Zspeed,1        ;

ZisDone2:       mov     ax,OldXspeed    ;
		cmp     Xspeed,ax       ;
		jne     SpeedUpLoop     ;
		mov     ax,OldYspeed    ;
		cmp     Yspeed,ax       ;
		jne     SpeedUpLoop     ;
		mov     ax,OldZspeed    ;
		cmp     Zspeed,ax       ;
		jne     SpeedUpLoop     ;
		call    WaitVbl         ;
		call    ClearSpace      ;
		call    Space           ;
		mov     SpaceControl,0  ; Go back to normal Space traveling
		ret
;****************************************************************************
;************************** Init Morph Routines *****************************
;****************************************************************************
;**************** Here goes all of the morphing routines.... ****************
;****************************************************************************
StartMorph:     call    MakeNewTextCoords       ;
		call    MakeMorphCoords         ;
		mov     ebp,fs:Steps            ; Number Of Times To Morph
		shr     ebp,1                   ;
		mov     fs:StepCounter,ebp      ;
		call    MakeMorphTable          ;
		call    ClearVideoMemory        ;
MorphLoop1:     call    WaitVbl                 ;
		call    ClearMorphCoords        ; 
		call    Morph                   ; Morph from stars to text
		call    CheckKeyboard           ;
		cmp     fs:StepCounter,0        ;
		je      PrintText               ;
		jmp     MorphLoop1              ;

PrintText:      call    WaitVbl
		call    ClearMorphCoords
		call    TypePressAKey
		mov     cx,200          ; Waiting Value
WaitVertical:   call    CheckKeyboard   ;
		mov     dx,3dah         ; Move rasterport into DX.
		in      al,dx           ; Move rasterportvalue into al.
		test    al,8h           ; Check If Vbl Bit is set.
		jz      WaitVertical    ; If Not, then go back & check again.
		loop    WaitVertical    ;

		mov     ebp,fs:Steps            ; Number Of Times To Morph
		shr     ebp,1                   ;
		mov     fs:StepCounter,ebp      ;
		call    MakeMorphBackTable      ;
		call    ClearVideoMemory        ;
MorphLoop2:     call    WaitVbl                 ;
		call    ClearMorphCoords        ; 
		call    Morph                   ; Morph from stars to text
		call    CheckKeyboard           ;
		cmp     fs:StepCounter,0        ;
		je      ExitBackMorph           ;
		jmp     MorphLoop2              ;
ExitBackMorph:  call    WaitVbl                 ;
		call    ClearMorphCoords        ; 
		call    Morph                   ; Morph from stars to text
		call    CheckKeyboard           ;
ExitSubRoutine: ret
;****************************************************************************
;**************************** Morphing Routine ******************************
;****************************************************************************
Morph:          mov     ax,Seg MorphStart       ;
		mov     ds,ax                   ;
		cmp     fs:StepCounter,0        ; Check If Morphing is Done.
		je      ExitSubRoutine          ;
		dec     fs:StepCounter          ;

		mov     dx,0a000h               ; 
		mov     es,dx                   ; 
		mov     bp,Offset MorphCoordsAdressTable ; Destination
		mov     si,Offset MorphStepTable         ; Source
		mov     eax,0                   ;
		mov     ebx,0                   ;
		mov     cx,fs:NumberMorphCoordsLoop
		mov     edx,0                   ;

MorphLoop:      mov     ebx,[si]+4              ; Get StepX
		add     [si]+8,ebx              ; TmpX=TmpX+StepX
		add     [si]+8,ebx              ; TmpX=TmpX+StepX
		mov     ebx,[si]+8              ; Get TmpX
		shr     ebx,15                  ; /8000
		mov     ax,[si]+2               ; Get x2
		cmp     word ptr [si],0         ; Check If StepX was Positive
		jne     XNegative               ; (x1-x2)
		add     ax,bx                   ; x2+(TmpX/8000)
		mov     fs:PlotXcoord,ax        ;
		jmp     MorphY                  ;

XNegative:      sub     ax,bx                   ; x2-(TmpX/8000)
		mov     fs:PlotXcoord,ax        ;

MorphY:         mov     ebx,[si]+16             ; Get StepY
		add     [si]+20,ebx             ; TmpY=TmpY+StepY
		add     [si]+20,ebx             ; TmpY=TmpY+StepY
		mov     ebx,[si]+20             ; Get TmpY
		shr     ebx,15                  ; /8000
		mov     ax,[si]+14              ; Get y2
		cmp     word ptr [si]+12,0      ; Check If StepY was Positive
		jne     YNegative               ; (y1-y2)
		add     ax,bx                   ; y2+(TmpY/8000)
		mov     fs:PlotYcoord,ax        ;
		jmp     MorphZ                  ;

YNegative:      sub     ax,bx                   ; y2-(TmpY/8000)
		mov     fs:PlotYcoord,ax        ;

MorphZ:         mov     ebx,[si]+28             ; Get StepZ
		add     [si]+32,ebx             ; TmpZ=TmpZ+StepZ
		add     [si]+32,ebx             ; TmpZ=TmpZ+StepZ
		mov     ebx,[si]+32             ; Get TmpZ
		shr     ebx,15                  ; /8000
		mov     ax,[si]+26              ; Get z2
		cmp     word ptr [si]+24,0      ; Check If StepZ was Positive
		jne     ZNegative               ; (z1-z2)
		add     ax,bx                   ; z2+(TmpZ/8000)
		mov     fs:PlotZcoord,ax        ;
		jmp     AddMorphPointers        ;

ZNegative:      sub     ax,bx                   ; z2-(TmpZ/8000)
		mov     fs:PlotZcoord,ax        ;

AddMorphPointers:
		mov     bx,fs:PlotXcoord        ;
		mov     di,fs:PlotYcoord        ;
		mov     dx,fs:PlotYcoord        ;
		shl     dx,6                    ; *64
		shl     di,8                    ; *256
		add     di,dx                   ; add y-coord
		add     di,bx                   ; add x-coord
		mov     bx,fs:PlotZcoord        ; Get PixelColor
		mov     byte ptr es:[di],bl     ; Write Pixel!!!!!!!!
		mov     ds:[bp],di              ; Save the cordinate's adress

		add     si,36                   ; Add MorphStepTable Pointer 
		add     bp,2                    ; Add MorphCoordsAdressTable
		dec     cx                      ;
		jnz     MorphLoop               ;
		ret
;****************************************************************************
;******************* Clear the Morph Coords On Screen ***********************
;****************************************************************************
ClearMorphCoords:
		mov     dx,0a000h               ; 
		mov     es,dx                   ; 
		mov     dx,Seg MorphStart       ;
		mov     ds,dx                   ;
		mov     bp,Offset MorphCoordsAdressTable
		mov     cx,fs:NumberMorphCoordsLoop ; Number Of Coords To Clear

ClearMorphLoop: mov     bx,ds:[bp]              ; Read adress from table
		mov     byte ptr es:[bx],0      ; Clear byte at adress
		add     bp,2                    ;
		dec     cx                      ;
		jnz     ClearMorphLoop          ;
		ret
;****************************************************************************
;********************** Add a Random Value To TextCoords ********************
;****************************************************************************
MakeNewTextCoords:
		mov     ax,Seg TextCoordsAddPointer     ;Ds:TextCoordsAddPointer
		mov     ds,ax                           ;
		mov     ax,Seg TextCoordsAdd            ;
		mov     es,ax                           ; Es:Bx TextCoordsAdd
		mov     bx,Offset TextCoordsAdd         ; => Source
		add     bx,ds:TextCoordsAddPointer      ;
		add     word ptr ds:TextCoordsAddPointer,4;
		cmp     word ptr ds:TextCoordsAddPointer,4*98;
		jnae    DontResetAddPointer
		mov     word ptr ds:TextCoordsAddPointer,0;
DontResetAddPointer:
		mov     ax,Seg TextCoords               ;
		mov     fs,ax                           ; Fs:Si TextCoords
		mov     si,Offset TextCoords            ; => Source
		mov     ax,Seg NewTextCoordsBuffer      ;
		mov     gs,ax                           ; Gs:Di NewTextCoordsBuffer
		mov     di,Offset NewTextCoordsBuffer   ; => Destination
		mov     cx,NumberOfMorphCoords*5        ;
TheMoveLoop:    mov     ax,Fs:[si]                      ; Read From TextCoords
		add     ax,Es:[bx]                      ; X-Add  (MidX=113)
		mov     Gs:[di],ax                      ; Write To NewTextCo...
		mov     ax,Fs:[si]+2                    ; Read From TextCoords
		add     ax,Es:[bx]+2                    ; Y-Add  (MidY=98)
		mov     Gs:[di]+2,ax                    ; Write To NewTextCo...
		mov     ax,Fs:[si]+4                    ; Read From TextCoords
		mov     Gs:[di]+4,ax                    ; Write To NewTextCo...
		add     si,6                            ;
		add     di,6                            ;
		loop    TheMoveLoop                     ;
		ret
;****************************************************************************
;******************* Calculate Stars On The Screen Into Coords **************
;****************************************************************************
TypePressAKey:  ;mov    ax,Seg TextCoords       ;
		mov     ax,Seg NewTextCoordsBuffer
		mov     ds,ax                   ;
		;mov    si,Offset TextCoords    ;
		mov     si,Offset NewTextCoordsBuffer
		mov     ax,0a000h               ;
		mov     es,ax

		mov     cx,NumberOfMorphCoords  ;
TypeTextLoop:   mov     di,[si]+2               ; Y
		mov     ax,[si]+2               ; Y
		shl     di,6                    ; *320
		shl     ax,8                    ;
		add     di,ax                   ; +y
		add     di,[si]                 ; +x
		mov     ax,[si]+4               ; Get Zvalue
		mov     es:[di],al              ; Write Pixel
		add     si,6                    ;
		dec     cx                      ;
		jnz     TypeTextLoop            ;
		ret
;****************************************************************************
;***************** Calculate Stars On The Screen Into Coords ****************
;****************************************************************************
MakeMorphCoords:mov     ax,Seg XYZcoordsOnScreenTable   ; Get Start Of Code
		mov     ds,ax                           ;
		mov     si,Offset XYZcoordsOnScreenTable; Ds:Si XYcoordsOnScreen
		mov     ax,Seg CalcedCoordTable         ; Es:Di CalcedCoordTable
		mov     es,ax                           ;
		mov     di,Offset CalcedCoordTable      ; From Es:Di To Ds:Si
		mov     ax,Seg NumberMorphCoordsLoop    ;
		mov     fs,ax                           ;
		mov     ax,0a000h                       ;
		mov     gs,ax                           ;
		mov     cx,NumberOfStars                ;
		mov     ebx,320                         ; Value To Divide With
		mov     fs:NumberMorphCoordsLoop,0      ;
MakeMorphCoordsLoop:
		mov     edx,0                   ; Clear EDX
		cmp     word ptr es:[di],0ffffh ; Check If It Is End Of Table
		je      EndOfMorphCoords        ;
		mov     ax,es:[di]      ; Read Address into AX
		mov     bp,ax           ; Read Address into BP
		div     bx              ; Address/320
		mov     [si],dx         ; Save Xcoord
		mov     [si]+2,ax       ; Save Ycoord
		mov     dx,0            ; Clear DX
		mov     dl,gs:[bp]      ; Read Pixel Value
		mov     [si]+4,dx       ; Save Zcoord
		add     si,6            ; Add XYZcoordsOnScreenTable Pointer
		add     di,2            ; Add CalcedCoordTable Pointer
		add     fs:NumberMorphCoordsLoop,1 ;Count Number Of Stars On Screen
		dec     cx              ;
		jnz     MakeMorphCoordsLoop
		mov     fs:NumberMorphCoordsLoop,NumberOfStars
		ret
EndOfMorphCoords:cmp    fs:NumberMorphCoordsLoop,NumberOfMorphCoords
		jb      TooFewStarsOnTheScreen ; 409-173 (Press A Key)
		ret

TooFewStarsOnTheScreen:
		mov     cx,NumberOfMorphCoords  ;
		sub     cx,fs:NumberMorphCoordsLoop; 173-100
		mov     ax,Seg CalcedCoordTable ;
		mov     es,ax                   ;
		mov     di,Offset CalcedCoordTable
		mov     ebx,320                 ; Value To Divide With

OhnoLoop:       mov     edx,0           ; Clear EDX
		mov     ax,es:[di]      ;
		div     bx              ;
		mov     [si],dx         ; Save Xcoord
		mov     [si]+2,ax       ; Save Ycoord
		mov     word ptr [si]+4,0;Save Zcoord
		add     si,6            ; Add XYZcoordsOnScreenTable Pointer
		add     di,2            ; Add CalcedCoordTable Pointer
		dec     cx              ;
		jnz     OhnoLoop        ;
		mov     fs:NumberMorphCoordsLoop,NumberOfMorphCoords
		ret
;****************************************************************************
;******************* Calculate The Morph Step Values ************************
;****************************************************************************
MakeMorphTable: mov     ax,Seg MorphStart
		mov     ds,ax
		mov     si,Offset XYZcoordsOnScreenTable        ; Source
		;mov    di,Offset TextCoords                    ; Source
		mov     di,Offset NewTextCoordsBuffer           ; Source
		mov     bp,Offset MorphStepTable                ; Destination

		mov     cx,fs:NumberMorphCoordsLoop ; Number Of Coords To Morph
StepLoop:       mov     edx,0           ;
		mov     ebx,0           ;
		mov     eax,0           ;
		mov     ax,[di]         ; x1 (TextCoords)
		mov     bx,[si]         ; x2 (Coords)
		cmp     ax,bx           ; ax-bx
		jl      NegativeX       ;
		mov     word ptr ds:[bp],0; Save StepXSign (positive=0)
		mov     ds:[bp]+2,bx    ; Save x2
		sub     ax,bx           ; Dx=x1-x2
		shl     eax,15          ; *32768
		div     fs:Steps        ; /Steps
		mov     ds:[bp]+4,eax   ; Save X-Step Value (Double Word)
		mov     ds:[bp]+8,eax   ; Save X-Step Value In TmpX
		jmp     YMorphCoord

NegativeX:      xchg    ax,bx           ; Swap ax & bx
		mov     word ptr ds:[bp],1; Save StepXSign (Negative=1)
		mov     ds:[bp]+2,ax    ; Save x2
		sub     ax,bx           ; Dx=x1-x2
		shl     eax,15          ; *32768
		div     fs:Steps        ; /Steps
		mov     ds:[bp]+4,eax   ; Save X-Step Value (Double Word)
		mov     ds:[bp]+8,eax   ; Save X-Step Value In TmpX

YMorphCoord:    mov     edx,0           ;
		mov     ebx,0           ;
		mov     eax,0           ;
		mov     ax,[di]+2       ; y1 (TextCoords)
		mov     bx,[si]+2       ; y2 (Coords)
		cmp     ax,bx           ;
		jb      NegativeY       ;
		mov     word ptr ds:[bp]+12,0; Save StepYSign (Positive=0)
		mov     ds:[bp]+14,bx   ; Save y2
		sub     ax,bx           ; Dy=y1-y2
		shl     eax,15          ; *32768
		div     fs:Steps        ; /Steps
		mov     ds:[bp]+16,eax  ; Save Y-Step Value (Double Word)
		mov     ds:[bp]+20,eax  ; Save Y-Step Value In TmpY
		jmp     ZMorphCoord     ;

NegativeY:      xchg    ax,bx           ; Swap ax & bx
		mov     word ptr ds:[bp]+12,1; Save StepYSign (Negative=1)
		mov     ds:[bp]+14,ax   ; Save y2
		sub     ax,bx           ; Dy=y1-y2
		shl     eax,15          ; *32768
		div     fs:Steps        ; /Steps
		mov     ds:[bp]+16,eax  ; Save Y-Step Value (Double Word)
		mov     ds:[bp]+20,eax  ; Save Y-Step Value In TmpY

ZMorphCoord:    mov     edx,0           ;
		mov     ebx,0           ;
		mov     eax,0           ;
		mov     ax,[di]+4       ; z1 (TextCoords)
		mov     bx,[si]+4       ; z2 (Coords)
		cmp     ax,bx           ;
		jb      NegativeZ       ;
		mov     word ptr ds:[bp]+24,0; Save StepZSign (Positive=0)
		mov     ds:[bp]+26,bx   ; Save z2
		sub     ax,bx           ; Dz=z1-z2
		shl     eax,15          ; *32768
		div     fs:Steps        ; /Steps
		mov     ds:[bp]+28,eax  ; Save Z-Step Value (Double Word)
		mov     ds:[bp]+32,eax  ; Save Z-Step Value In TmpZ
		jmp     AddPointers     ;

NegativeZ:      xchg    ax,bx           ; Swap ax & bx
		mov     word ptr ds:[bp]+24,1; Save StepZSign (Negative=1)
		mov     ds:[bp]+26,ax   ; Save z2
		sub     ax,bx           ; Dz=z1-z2
		shl     eax,15          ; *32768
		div     fs:Steps        ; /Steps
		mov     ds:[bp]+28,eax  ; Save Z-Step Value (Double Word)
		mov     ds:[bp]+32,eax  ; Save Z-Step Value In TmpZ

AddPointers:    add     si,6            ; Add XYZcoordsOnScreenTable pointer
		add     di,6            ; Add TextCoords pointer
		add     bp,36           ; Add StepTable pointer
		loop    StepLoop        ; 
		ret
;****************************************************************************
;******************* Calculate The Morph Step Values ************************
;****************************************************************************
MakeMorphBackTable:mov  ax,Seg MorphStart
		mov     ds,ax
		;mov    si,Offset TextCoords    
		mov     si,Offset NewTextCoordsBuffer
		mov     di,Offset XYZcoordsOnScreenTable
		mov     bp,Offset MorphStepTable

		mov     cx,fs:NumberMorphCoordsLoop ; Number Of Coords To Morph
StepLoopBack:   mov     edx,0           ;
		mov     ebx,0           ;
		mov     eax,0           ;
		mov     ax,[di]         ; x1 (Coords)
		mov     bx,[si]         ; x2 (TextCoords)
		cmp     ax,bx           ; ax-bx
		jl      NegativeXBack   ;
		mov     word ptr ds:[bp],0; Save StepXSign (positive=0)
		mov     ds:[bp]+2,bx    ; Save x2
		sub     ax,bx           ; Dx=x1-x2
		shl     eax,15          ; *32768
		div     fs:Steps        ; /Steps
		mov     ds:[bp]+4,eax   ; Save X-Step Value (Double Word)
		mov     ds:[bp]+8,eax   ; Save X-Step Value In TmpX
		jmp     YMorphCoordBack

NegativeXBack:  xchg    ax,bx           ; Swap ax & bx
		mov     word ptr ds:[bp],1; Save StepXSign (Negative=1)
		mov     ds:[bp]+2,ax    ; Save x2
		sub     ax,bx           ; Dx=x1-x2
		shl     eax,15          ; *32768
		div     fs:Steps        ; /Steps
		mov     ds:[bp]+4,eax   ; Save X-Step Value (Double Word)
		mov     ds:[bp]+8,eax   ; Save X-Step Value In TmpX

YMorphCoordBack:mov     edx,0           ;
		mov     ebx,0           ;
		mov     eax,0           ;
		mov     ax,[di]+2       ; y1 (Coords)
		mov     bx,[si]+2       ; y2 (TextCoords)
		cmp     ax,bx           ;
		jb      NegativeYBack   ;
		mov     word ptr ds:[bp]+12,0; Save StepYSign (Positive=0)
		mov     ds:[bp]+14,bx   ; Save y2
		sub     ax,bx           ; Dy=y1-y2
		shl     eax,15          ; *32768
		div     fs:Steps        ; /Steps
		mov     ds:[bp]+16,eax  ; Save Y-Step Value (Double Word)
		mov     ds:[bp]+20,eax  ; Save Y-Step Value In TmpY
		jmp     ZMorphCoordBack ;

NegativeYBack:  xchg    ax,bx           ; Swap ax & bx
		mov     word ptr ds:[bp]+12,1; Save StepYSign (Negative=1)
		mov     ds:[bp]+14,ax   ; Save y2
		sub     ax,bx           ; Dy=y1-y2
		shl     eax,15          ; *32768
		div     fs:Steps        ; /Steps
		mov     ds:[bp]+16,eax  ; Save Y-Step Value (Double Word)
		mov     ds:[bp]+20,eax  ; Save Y-Step Value In TmpY

ZMorphCoordBack:mov     edx,0           ;
		mov     ebx,0           ;
		mov     eax,0           ;
		mov     ax,[di]+4       ; z1 (Coords)
		mov     bx,[si]+4       ; z2 (TextCoords)
		cmp     ax,bx           ;
		jb      NegativeZBack   ;
		mov     word ptr ds:[bp]+24,0; Save StepZSign (Positive=0)
		mov     ds:[bp]+26,bx   ; Save z2
		sub     ax,bx           ; Dz=z1-z2
		shl     eax,15          ; *32768
		div     fs:Steps        ; /Steps
		mov     ds:[bp]+28,eax  ; Save Z-Step Value (Double Word)
		mov     ds:[bp]+32,eax  ; Save Z-Step Value In TmpZ
		jmp     AddPointersBack ;

NegativeZBack:  xchg    ax,bx           ; Swap ax & bx
		mov     word ptr ds:[bp]+24,1; Save StepZSign (Negative=1)
		mov     ds:[bp]+26,ax   ; Save z2
		sub     ax,bx           ; Dz=z1-z2
		shl     eax,15          ; *32768
		div     fs:Steps        ; /Steps
		mov     ds:[bp]+28,eax  ; Save Z-Step Value (Double Word)
		mov     ds:[bp]+32,eax  ; Save Z-Step Value In TmpZ

AddPointersBack:add     si,6            ; Add TextCoords pointer
		add     di,6            ; Add XYZcoordsOnScreenTable pointer
		add     bp,36           ; Add StepTable pointer
		loop    StepLoopBack    ; 
		ret
;****************************************************************************
;******************** Here Goes The Hidden Part *****************************
;****************************************************************************
HiddenPart:     mov     HiddenPekare,0  ;
		call    WaitVbl         ;
		call    ClearVideoMemory;
		call    ClearDblBuffer  ;
WaitOnRelease:  mov     dx,60h          ; Wait until the last char typed is
		in      al,dx           ; released.
		cmp     al,LastChar     ;
		je      WaitOnRelease   ;
		call    InitHiddenPic   ;

HiddenMainLoop: call    WaitVbl          ;
		call    CopyDoubleBuffer ;
		call    UpScroll         ;

		mov     dx,60h           ;
		in      al,dx            ;
		cmp     al,9fh           ;
		je      HiddenMainLoop   ; Exit with any key exept S
		cmp     al,1fh           ;
		jne     ExitHiddenPart   ;

		mov     ax,0003h         ; Move Function 3 into ax
		int     33h              ; Call MouseButtonStatus Interrupt
		cmp     bl,02h           ;
		je      ExitHiddenPart   ;
		cmp     bl,01h           ; Check if bit 0 was set.
		jne     HiddenMainLoop   ; If not, then go back to Mainloop

;****************************************************************************
;*********************** Exit The Hidden Part *******************************
;****************************************************************************
ExitHiddenPart: mov     CharCounter,0           ;
		mov     CharBufferLineCounter,0 ;
		mov     CharBufferPointer,0     ; Clear all Variables etc which
		mov     TextPointer,0           ;

		call    ClearVideoMemory        ;
		call    GetPalette              ;

		mov     ax,Seg CharBuffer       ;
		mov     es,ax                   ;
		mov     di,Offset CharBuffer    ; Clear The CharBuffer
		mov     cx,320*11/4             ;
		mov     eax,0                   ;
		rep     stosd                   ;

		mov     ax,0c00h                ; Clear the keyboard buffer
		int     21h                     ;
		;pop    ax                      ;
		call    ReadCurrentKeyPortValue ; on as usual.
		jmp     MainLoop                ;

;****************************************************************************
;************************** Clear Video Memory ******************************
;****************************************************************************
ClearVideoMemory:
		mov     di,0            ;
		mov     ax,0a000h       ;
		mov     es,ax           ;
		mov     ax,0            ;
		mov     cx,320*50       ;
		rep     stosd           ;
		ret                     ;
;****************************************************************************
;************************** Clear Double Buffer *****************************
;****************************************************************************
ClearDblBuffer: mov     di,0
		mov     ax,Seg DblBuffer
		mov     es,ax
		mov     ax,0
		mov     cx,320*50
		rep     stosd
		ret
;****************************************************************************
;**************************** Init Pic Routine ******************************
;****************************************************************************
InitPic:        mov     ah,00h          ; Set videomode function
		mov     al,13h          ; Set to Mcga
		int     10h             ;

		mov     dx,3c8h         ;
		mov     al,0h           ; Palette Nr   3c8
		out     dx,al           ;
		mov     ax,0            ;
		mov     dx,3c9h         ; FÑrgdata     3c9
		mov     cx,256          ;
PaletteLoop:    mov     al,fs:[si]      ;
		out     dx,al           ;
		mov     al,fs:[si]+1    ;
		out     dx,al           ;
		mov     al,fs:[si]+2    ;
		out     dx,al           ;
		add     si,3            ;
		loop    PaletteLoop     ;
		ret
;****************************************************************************
;**************************** UpScroll Routine ******************************
;****************************************************************************
UpScroll:       mov     ax,Seg CharCounter      ;
		mov     ds,ax                   ;
		cmp     CharCounter,FontHeight  ; If 1 Char has been moved out
		je      NewCharLine             ; of the charbuffer, then goto
		add     CharCounter,1           ; NewCharLine and fill CharBuffer

		push    ds                      ;
		mov     ax,Seg DblBuffer        ;
		mov     ds,ax                   ; Move the whole screen one
		mov     si,320                  ; pixel up
		mov     es,ax                   ;
		mov     di,0                    ;
		mov     cx,199*320/2            ;
		rep     movsw                   ; Not movsd, because I want it
		pop     ds                      ; on 2 frames on the 486sx 25MHz

		mov     dx,0                    ;
		mov     ax,320                  ; 
		mul     CharBufferLineCounter   ; 
		add     CharBufferLineCounter,1 ;
		mov     si,ax                   ;
		mov     di,(320*199)            ; 

		push    ds                      ;
		mov     ax,Seg CharBuffer       ; 
		mov     ds,ax                   ; 
		mov     ax,Seg DblBuffer        ; Move 1 Line From CharBuffer
		mov     es,ax                   ; To the bottom of the screen
		mov     cx,320/4                ;
		rep     movsd                   ;
		pop     ds                      ;
		ret                             ;

NewCharLine:    mov     ax,Seg CharBuffer       ;
		mov     es,ax                   ;
		mov     di,Offset CharBuffer    ; Clear The CharBuffer
		mov     cx,320*12/4             ;
		mov     eax,0                   ;
		rep     stosd                   ;

		mov     dx,Seg FontData         ;
		mov     es,dx                   ;
		mov     di,Offset FontData      ;
		mov     CharCounter,0           ;
		mov     CharBufferLineCounter,0 ;
		mov     CharBufferPointer,0     ; Clear all Variables etc which
CharBufferLoop: mov     LineInFont,778          ; are used in the forthcomming
		mov     eax,0                   ; routine.
		mov     ebx,0                   ;
		mov     ecx,0                   ;
		mov     edx,0                   ;
	
		mov     si,Offset ScrollText    ;
		add     si,TextPointer          ; Read in the next char from
		add     TextPointer,1           ; the scrolltext and check if
		cmp     byte ptr [si],0         ; it is EndOfLine or EndOfScroll
		je      UpScroll                ; 0 = End Of Line
		cmp     byte ptr [si],1         ; 1 = End Of ScrollText
		je      ExitHiddenPart          ;
		cmp     byte ptr [si],8fh       ; Check if char was è
		je      GetCharAddressè         ;
		cmp     byte ptr [si],8eh       ; Check if char was é
		je      GetCharAddressé         ;
		cmp     byte ptr [si],99h       ; Check if char was ô
		je      GetCharAddressô         ;

		mov     al,[si]                 ;
		sub     al,32                   ;
		cmp     al,27h                  ; Get char's address in the font
		jbe     GetCharAddress          ;
		sub     al,28h                  ;
		mov     LineInFont,(10*320)+778 ;
GetCharAddress: mul     Eight                   ;
		add     ax,LineInFont           ;
		mov     di,ax                   ;

NextCharBuff:   mov     si,Offset CharBuffer    ;
		add     si,CharBufferPointer    ; Get Next Address In CharBuffer
		add     CharBufferPointer,8     ;
		sub     di,1

		mov     ch,10                   ;
MoveCharLoop:   mov     cl,8                    ; ds:si = CharBuffer
MovCharLineLoop:mov     ax,es:[di]              ; es:di = FontData
		mov     [si],ax                 ;
		add     si,1                    ; Move The Char From The Font
		add     di,1                    ; To CharBuffer
		dec     cl                      ;
		jnz     MovCharLineLoop         ;
		add     di,320-8                ;
		add     si,320-8                ;
		dec     ch                      ;
		jnz     MoveCharLoop            ;

		jmp     CharBufferLoop          ; Go Back and check the next one

GetCharAddressè:mov     di,(320*10)+778+(8*21)  ; Address To Char 'è'
		jmp     NextCharBuff            ;

GetCharAddressé:mov     di,(320*10)+778+(8*19)  ; Address To Char 'é'
		jmp     NextCharBuff            ;

GetCharAddressô:mov     di,(320*10)+778+(8*20)  ; Address To Char 'ô'
		jmp     NextCharBuff            ;
;****************************************************************************
;******************** Copy the double buffer to the screen ******************
;****************************************************************************
CopyDoubleBuffer:mov    ax,Seg DblBuffer
		mov     ds,ax
		mov     ax,0a000h
		mov     es,ax
		mov     si,0
		mov     di,0
		mov     cx,320*200/4
		rep     movsd
		ret
;****************************************************************************
;*********************** Init Pic & Set Palette Routine *********************
;****************************************************************************
InitHiddenPic:  mov     ah,00h          ; Set videomode function
		mov     al,13h          ; Set to Mcga
		int     10h             ;

		mov     dx,3c8h         ; 
		mov     al,0h           ;
		out     dx,al           ;

		push    ds
		mov     si,Offset FontData; Get Picture Offset
		mov     ax,Seg FontData ; Get StartAddress Of Picture
		mov     Ds,ax           ; Set StartAddress Into DataSegment

		add     si,0ah          ; Skit Rix Header
		mov     dx,3c9h         ;
		mov     cx,300h         ; antal loopar
SetHiddenPalette:mov    al,[si]         ;
		out     dx,al           ;
		inc     si              ;
		loop    SetHiddenPalette;
		pop     ds
		ret
;****************************************************************************
;****************************** Colorize Screen *****************************
;****************************************************************************
ColorizeScreen: mov     dx,3c8h         ;
		mov     al,0            ; 
		out     dx,al           ;
		mov     dx,3c9h         ;
		mov     al,56           ;
		out     dx,al           ;
		out     dx,al           ;
		out     dx,al           ;
		ret
;****************************************************************************
;******************************* Blank Screen *******************************
;****************************************************************************
BlankScreen:    mov     dx,3c8h         ;
		mov     al,0            ;
		out     dx,al           ;
		mov     dx,3c9h         ;
		mov     al,00           ;
		out     dx,al           ;
		out     dx,al           ;
		out     dx,al           ;
		ret
;****************************************************************************
;****************************** Create XY Table *****************************
;****************************************************************************
CreateXYtable:
		mov     ax,Seg Xtable
		mov     es,ax
		mov     di,Offset Xtable
		mov     bx,Offset XtableNeg+8190
		mov     cl,160
		mov     ax,160
		mov     dx,159
CreateLoopX:    mov     es:[di],ax
		mov     es:[bx],dx
		inc     ax
		dec     dx
		add     di,2
		sub     bx,2
		dec     cl
		jnz     CreateLoopX

		mov     ax,Seg Ytable
		mov     es,ax
		mov     di,Offset Ytable
		mov     bx,Offset YtableNeg+8190
		mov     cl,100
		mov     ax,100*320
		mov     dx,99*320
CreateLoopY:    mov     es:[di],ax
		mov     es:[bx],dx
		add     ax,320
		sub     dx,320
		add     di,2
		sub     bx,2
		dec     cl
		jnz     CreateLoopY
		ret

;****************************************************************************
;****************** Setup SINTAB0 ONLY!!!!!!!!!!!!!!!! **********************
;****************************************************************************
ONLYTAB0:
		mov     bx,Seg SinTableAddress
		mov     ds,bx
		je      SetSinTable0            ;


;****************************************************************************
;****************** Get Clock-Time as RND for sintable **********************
;****************************************************************************
GetTimeForSinTable:
		mov     bx,Seg SinTableAddress
		mov     ds,bx
		mov     ah,2ch                  ; Get current second
		int     21h                     ;
		and     dh,111b                 ; Get 0-7 seconds ONLY!
		cmp     dh,0                    ;
		je      SetSinTable0            ;
		cmp     dh,1                    ;
		je      SetSinTable1            ;
		cmp     dh,2                    ;
		je      SetSinTable2            ;
		cmp     dh,3                    ;
		je      SetSinTable3            ;
		cmp     dh,4                    ;
		je      SetSinTable4            ;
		cmp     dh,5                    ;
		je      SetSinTable5            ;
		cmp     dh,6                    ;
		je      SetSinTable6            ;
		cmp     dh,7                    ;
		je      SetSinTable7            ;
SetSinTable0:   mov     SinTableAddress,Offset SinTable0
		ret
SetSinTable1:   mov     SinTableAddress,Offset SinTable1
		ret
SetSinTable2:   mov     SinTableAddress,Offset SinTable2
		ret
SetSinTable3:   mov     SinTableAddress,Offset SinTable3
		ret
SetSinTable4:   mov     SinTableAddress,Offset SinTable4
		ret
SetSinTable5:   mov     SinTableAddress,Offset SinTable5
		ret
SetSinTable6:   mov     SinTableAddress,Offset SinTable6
		ret
SetSinTable7:   mov     SinTableAddress,Offset SinTable7
		ret
;****************************************************************************
;***************** Get SpacePalette Depending on which day it is ************
;****************************************************************************
GetPalette:
		mov     bx,Seg Start
		mov     ds,bx
		mov     ah,2ah
		int     21h
		and     ax,7
		cmp     al,0
		je      SundayPalette
		cmp     al,1
		je      MondayPalette
		cmp     al,2
		je      TuesdayPalette
		cmp     al,3
		je      WednesdayPalette
		cmp     al,4
		je      ThursdayPalette
		cmp     al,5
		je      FridayPalette
		cmp     al,6
		je      SatterdayPalette

SundayPalette:  
		mov     ax,Seg Palette5         ;
		mov     fs,ax                   ;
		mov     si,Offset Palette5      ;
		call    InitPic                 ;
		ret
MondayPalette:          
		mov     ax,Seg Palette1         ;
		mov     fs,ax                   ;
		mov     si,Offset Palette1      ;
		call    InitPic                 ;
		ret
TuesdayPalette:            
		mov     ax,Seg Palette2         ;
		mov     fs,ax                   ;
		mov     si,Offset Palette2      ;
		call    InitPic                 ;
		ret
WednesdayPalette:          
		mov     ax,Seg Palette3         ;
		mov     fs,ax                   ;
		mov     si,Offset Palette3      ;
		call    InitPic                 ;
		ret
ThursdayPalette:           
		mov     ax,Seg Palette4         ;
		mov     fs,ax                   ;
		mov     si,Offset Palette4      ;
		call    InitPic                 ;
		ret
FridayPalette:             
		mov     ax,Seg Palette5         ;
		mov     fs,ax                   ;
		mov     si,Offset Palette5      ;
		call    InitPic                 ;
		ret
SatterdayPalette:
		mov     ax,Seg Palette2         ;
		mov     fs,ax                   ;
		mov     si,Offset Palette2      ;
		call    InitPic                 ;
		ret
;****************************************************************************
;************* Turn off interrupts like Parallell, Com1 & Com2 **************
;****************************************************************************
MaskingRegisterShutDown:
		mov     ax,Seg MaskingRegister          ;
		mov     ds,ax                           ;
		mov     dx,021h                         ;
		in      al,dx                           ;
		mov     MaskingRegister,al              ; Save Old Settings

		mov     al,00000011b                    ;
		out     dx,al                           ; Enable Only Keyboard
		ret                                     ; & SystemTimer
;****************************************************************************
;************* Turn on interrupts like Paralell, Com1 & Com2 ****************
;****************************************************************************
RestoreMaskingRegister:
		mov     ax,Seg MaskingRegister          ;
		mov     ds,ax                           ;
		mov     dx,021h                         ;
		mov     al,MaskingRegister              ;
		out     dx,al                           ; Restore Old Settings
		ret                                     ;
;****************************************************************************
;******************* Here goes all the loading stuff... *********************
;****************************************************************************
		even
FileHandle      dw      0
FileName0       db      'Space.000',0           ; Rix Font For The Hidden Part
FileName1       db      'Space.001',0           ; Palette 1 Colors
FileName2       db      'Space.002',0           ; Palette 2 Colors
FileName3       db      'Space.003',0           ; Palette 3 Colors
FileName4       db      'Space.004',0           ; Palette 4 Colors
FileName5       db      'Space.005',0           ; Palette 5 Colors
		even
LoaderRoutines: mov     ax,Seg FileHandle       ;
		mov     ds,ax                   ;
		mov     es,ax                   ;

		mov     bx,Seg FileName0        ;
		mov     dx,Offset FileName0     ;
		call    OpenFile                ;
		mov     bx,Seg FontData         ; Load The Font Used In The 
		mov     dx,Offset FontData      ; Hidden Part
		call    ReadFile                ;
		call    CloseFile               ;

		mov     bx,Seg FileName1        ;
		mov     dx,Offset FileName1     ;
		call    OpenFile                ; Load The Palette Colors Used
		mov     bx,Seg Palette1         ; In The Space Ride
		mov     dx,Offset Palette1      ;
		call    ReadFile                ;
		call    CloseFile               ;

		mov     bx,Seg FileName2        ;
		mov     dx,Offset FileName2     ;
		call    OpenFile                ; Load The Palette Colors Used
		mov     bx,Seg Palette2         ; In The Space Ride
		mov     dx,Offset Palette2      ;
		call    ReadFile                ;
		call    CloseFile               ;

		mov     bx,Seg FileName3        ;
		mov     dx,Offset FileName3     ;
		call    OpenFile                ; Load The Palette Colors Used
		mov     bx,Seg Palette3         ; In The Space Ride
		mov     dx,Offset Palette3      ;
		call    ReadFile                ;
		call    CloseFile               ;

		mov     bx,Seg FileName4        ;
		mov     dx,Offset FileName4     ;
		call    OpenFile                ; Load The Palette Colors Used
		mov     bx,Seg Palette4         ; In The Space Ride
		mov     dx,Offset Palette4      ;
		call    ReadFile                ;
		call    CloseFile               ;

		mov     bx,Seg FileName5        ;
		mov     dx,Offset FileName5     ;
		call    OpenFile                ; Load The Palette Colors Used
		mov     bx,Seg Palette5         ; In The Space Ride
		mov     dx,Offset Palette5      ;
		call    ReadFile                ;
		call    CloseFile               ;
		ret
;****************************************************************************
;************************** Open File Routine *******************************
;****************************************************************************
OpenFile:       mov     ah,3dh                  ; Open File Function
		mov     al,00                   ; Read File Only
		mov     ds,bx                   ; 
		int     21h                     ; 

		jc      DeBlevFel               ; Jump If Error
		mov     es:FileHandle,ax        ; Save Handle
DeBlevFel:      ret
;****************************************************************************
;************************** Read File Routine *******************************
;****************************************************************************
ReadFile:       mov     ax,3f00h                ; Read File Function
		mov     cx,7178                 ; Size (Number of bytes)
		mov     ds,bx                   ;
		mov     bx,es:FileHandle        ; Get FileHandle
		int     21h                     ;

		je      DeBlevFel               ; Jump If Error
		ret                             ;
;****************************************************************************
;************************** Close File Routine ******************************
;****************************************************************************
CloseFile:      mov     ah,3eh                  ; Close File Function
		mov     bx,es:FileHandle        ;
		int     21h                     ;
		ret                             ;
;******************************************************************************
;******************** Detect what kind of machine it is ***********************
;******************************************************************************
GetCpuType:     MOV     DX,Cpu8086              ;
		PUSH    SP                      ; 
		POP     AX                      ;
		CMP     SP,AX                   ; Om SP<>AX sÜ Ñr det en 8086'a
		JNE     Compare                 ;
		MOV     DX,Cpu80286             ;
		PUSHF                           ;

		POP     AX                      ;
		OR      AX,4000h                ;
		PUSH    AX                      ;
		POPF                            ;
		PUSHF                           ;  Testa om burken Ñr en 286'a
		POP     AX                      ;
		TEST    AX,4000h                ;
		JE      Compare                 ;
		MOV     DX,Cpu80386             ;

		MOV     EBX,ESP                 ;
		AND     ESP,0FFFCh              ;
		PUSHFD                          ;
		POP     EAX                     ;
		MOV     ECX,EAX                 ;
		XOR     EAX,00040000            ;
		PUSH    EAX                     ;
		POPFD                           ; Testa om 386'a
		PUSHFD                          ;
		POP     EAX                     ;
		AND     EAX,00040000            ;
		AND     ECX,00040000            ;
		CMP     EAX,ECX                 ;
		JE      Not486                  ;
		MOV     DX,Cpu80486             ; DÜ mÜste det vara en 486'a!

Not486:         PUSH    ECX                     ;
		POPFD                           ;
		MOV     ESP,EBX                 ;

Compare:        cmp     dx,1                    ;
		je      ItsAn8086               ;
		cmp     dx,2                    ;
		je      ItsAn286                ;
		cmp     dx,3                    ;
		je      ItsAn386                ;
		cmp     dx,4                    ;
		je      ItsAn486                ;
		jmp     Exit                    ;
ItsAn8086:      jmp     TypeYuckyMessage1       ;
ItsAn286:       jmp     TypeYuckyMessage2       ;
ItsAn386:       
ItsAn486:       ret
;****************************************************************************
;**************************  Type Yucky Messages ****************************
;****************************************************************************
TypeYuckyMessage1:mov   ax,Seg Text1            ;
		mov     ds,ax                   ;
		mov     dx,Offset Text1         ;
		mov     ah,09                   ;
		int     21h                     ;
		jmp     ExitThisShit            ;

TypeYuckyMessage2:mov   ax,Seg Text2            ;
		mov     ds,ax                   ;
		mov     dx,Offset Text2         ;
		mov     ah,09                   ;
		int     21h                     ;

ExitThisShit:   mov     ax,4c00h                ;
		int     21h                     ;
;****************************************************************************
;******************************* Buffers etc. *******************************
;****************************************************************************
		.FarData GasLarm
TheFont         Segment Use16           ; Here is the font for the hidden part
FontData        db 7178 dup (0)         ; loaded. It's a 320*20 (used to be a
TheFont         EndS                    ; 320*200) RIX format picture for MCGA

TheDblBuffer    Segment Use16           ; Here is the DoubleBuffer for the 
DblBuffer       db 64000 dup (0)        ; scroll in the hidden part. Well, what
TheDblBuffer    EndS                    ; more??? It's a DoubleBuffer... B-)

ThePalette1     Segment Use16           ; Here is the palette data for the
Palette1        db 768 dup (0)          ; space ride.
ThePalette1     EndS                    ;

ThePalette2     Segment Use16           ; Here is the palette data for the
Palette2        db 768 dup (0)          ; space ride.
ThePalette2     EndS                    ;

ThePalette3     Segment Use16           ; Here is the palette data for the
Palette3        db 768 dup (0)          ; space ride.
ThePalette3     EndS                    ;

ThePalette4     Segment Use16           ; Here is the palette data for the
Palette4        db 768 dup (0)          ; space ride.
ThePalette4     EndS                    ;

ThePalette5     Segment Use16           ; Here is the palette data for the
Palette5        db 768 dup (0)          ; space ride.
ThePalette5     EndS                    ;

;****************************************************************************
;***************************** Ending Correctly *****************************
;****************************************************************************
		End     Init
		End      
