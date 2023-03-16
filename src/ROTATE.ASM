;*************************************
;* Ohej vad det snurrar............. *
;*************************************
                .MODEL  huge            ; Large DataSegments
                .STACK  512h            ; SetUp a StackSegment
		Smart
                Jumps                   ; Setting Long Jumps
                .486                    ; Enable All 486 Commands.
                .Data                   ; SetUp a DataSegment

; X1 = Xcoord*Sin(v) + Zcoord*Cos(v)	; Rotation runt
; Z1 = Xcoord*Cos(v) - Zcoord*Sin(v)	; Y-Axeln
;					;
; Y2 = Ycoord*Sin(v) + Z1*Cos(v)	; Rotation runt
; Z2 = Ycoord*Cos(v) - Z1*Sin(v)	; X-Axeln
;					;
; X3 = X1*Sin(v) + Y2*Cos(v)		; Rotation runt
; Y3 = X1*Cos(v) - Y2*Sin(v)		; Z-Axeln

;------------------------ System variabler -------------------
Xcoord          dw      150
Ycoord          dw      150
Zcoord          dw      150


X1		dw	0
Y1		dw	0
Z1		dw	0
X2		dw	0
Y2		dw	0
Z2		dw	0
X3		dw	0
Y3		dw	0
Z3		dw 	0
		

Vinkel          dw      00

Xpixel          dw      00
Ypixel          dw      00

xl              dw 0
yl              dw 0
xl2             dw 0
yl2             dw 0
color           db 0
WaitValue       equ     30              ;
DataStart       dw      0               ;
SaveINT         db      0,0             ;                
ScrollPtr       db      0               ;
ScrollWait      db      0               ;
                .Code                   ; SetUp a CodeSegment
;----------------------- Init Routines --------------------
Init:           Assume  Cs:@Code,Ds:@Data,Es:@Data,SS:@Stack
                mov     ax,Seg DataStart; Get address to where all the variables
                mov     ds,ax           ; are going to be stored.

                mov     ax,0013h
                int     10h

                call    CloseSystem     ; Disable ComPorts, HardDrive etc.
                call    SetPalette
;----------------------- huvud ----------------------------
MainLoop:       call    WaitVbl         ; Wait For Vertical Blanking
                call    Rotate          ;

                mov     dx,60h          ; Get Keyboard Port Value
                in      al,dx           ; Read Value from port into AL
                cmp     al,57           ; Check If AL contains the code for ESC
                jne     MainLoop        ; If not, then go back to MainLoop
                jmp     Exit            ; Exit 

;------------------------- inte linjedragnings rutinen ----------------
Rotate:         mov     ax,Seg Sintab		;
                mov     es,ax			; Get Adress To SinusTabel
                mov     si,Offset SinTab	;
                add     Vinkel,2		;
                add     si,vinkel		;
                cmp     vinkel,628*2		;
                jbe     NotReset      		;
                mov     vinkel,0		;

NotReset:	;Yrot
		mov	ax,es:[si]+628/4*2  ; Zcoord*cos(v)
		imul	Zcoord		    ;		  
		mov	bx,dx		    ;
		mov	ax,es:[si]	    ; Xcoord*sin(v)
		imul	Xcoord		    ;
		add	dx,bx		    ;
		mov     X1,dx		    ; X1=Xcoord*sin(v) + Zcoord*cos(v)
		mov	ax,es:[si]	    ; Zcoord*sin(v)
		imul	Zcoord		    ;
		mov   	bx,dx		    ;
		mov	ax,es:[si]+628/4*2  ; Xcoord*cos(v)
		imul	Xcoord		    ;
		sub	dx,bx		    ; Z1=Xcoord*cos(v) - Zcoord*sin(v)
		mov	Z1,dx		    ;

		;Xrot
		mov	ax,es:[si]+628/4*2  ; Z1*Cos(v)
		imul	z1		    ;
		mov	bx,dx		    ;
		mov	ax,es:[si]	    ; Ycoord*Sin(v)
		imul	Ycoord		    ;
		add	dx,bx		    ;
		mov	Y2,dx		    ; Y2=Ycoord*Sin(v) + Z1*Cos(v)
		mov	ax,es:[si]	    ; Z1*Sin(v)
		imul	z1		    ;
		mov	bx,dx		    ;
		mov	ax,es:[si]+628/4*2  ; Ycoord*Cos(v)
		imul	Ycoord		    ;
		sub	dx,bx		    ;
		mov	Z2,dx		    ; Z2=Ycoord*Cos(v) - Z1*Sin(v)

		;Zrot
		mov     ax,es:[si]+628/4*2  ; Y2*cos(v)
                imul    Y2                  ;
                mov     bx,dx               ;
                mov     ax,es:[si]          ; X1*sin(v)
                imul    X1                  ;
                add     dx,bx               ; 
		mov     X3,dx               ; X3=X1*sin(v) + Y2*cos(v)
                mov     ax,es:[si]          ; Y2*sin(v)
                imul    Y2                  ;
                mov     bx,dx               ;
                mov     ax,es:[si]+628/4*2  ; X1*cos(v)
                imul    X1                  ;
                sub     dx,bx               ; 
                mov     Y3,dx		    ; Y3=X1*cos(v) - Y2*sin(v)

                mov     ax,0a000h		; Here goes the pixel setting
                mov     es,ax			; routine...
		mov	ax,320			;
		mul	Y3			;
                add	ax,X3			;
                mov     di,ax			;
                add     di,(320*100)+160	; Add origo!
		mov	ax,Z2			;
		add	ax,100			; Add Z-Offset (eliminate NegZ)
                mov     es:[di],al		; Plot Pixel!
                ret

;------------------------- inte alls linjedragnings rutinen ----------------
ClearScreen:	mov	dx,0a000h
		mov	es,dx
		mov	di,0
		mov	cx,320*200/4
		mov	ax,0
		rep	stosd
		ret
;------------------------- linjedragnings rutinen ----------------
DoLine  Proc    near    ;xl,yl,xl2,yl2
                mov     ax,0A000h
                mov     es,ax

                mov     bx,xl
                mov     ax,yl
                mov     cx,xl2
                mov     si,yl2
                cmp     ax,si
                jbe     NO_SWAP         ; always draw downwards
                xchg    bx,cx
                xchg    ax,si
NO_SWAP:
                sub     si,ax           ;yd (pos)
                sub     cx,bx           ;xd (+/-)
                cld                     ;set up direction flag
                jns     H_ABS
                neg     cx              ;make x positive
                std
H_ABS:
                mov     di,320
                mul     di
                mov     di,ax
                add     di,bx           ;di:adr
                or      si,si
                jnz     NOT_H
                                        ;horizontal line
                cld
                mov     al,color
                inc     cx
                rep     stosb
                jmp     Line_EXIT
NOT_H:
                or      cx,cx
                jnz     NOT_V
                                        ;vertical line
                cld
                mov     al,color
                mov     cx,si
                inc     cx
                mov     bx,320-1
VLINE_LOOP:
                stosb
                add     di,bx
                dec     cx
                jnz     VLINE_LOOP
                jmp     Line_EXIT
NOT_V:
                cmp     cx,si           ;which is greater distance?
                lahf                    ;then store flags
                ja      H_IND
                xchg    cx,si           ;swap for redundant calcs
H_IND:
                mov     dx,si           ;inc2 (adjustment when decision var rolls over)
                sub     dx,cx
                shl     dx,1
                shl     si,1            ;inc1 (step for decision var)
                mov     bx,si           ;decision var, tells when we need to go secondary direction
                sub     bx,cx
                inc     cx
                push    bp              ;need another register to hold often-used constant
                mov     bp,320
                mov     al,color
                sahf                    ;restore flags
                jb      DIAG_V
                                        ;mostly-horizontal diagonal line
                or      bx,bx           ;set flags initially, set at end of loop for other iterations
LH:
                stosb                   ;plot and move x, doesn't affect flags
                jns     SH              ;decision var rollover in bx?
                add     bx,si
                dec     cx
                jnz     LH              ;doesn't affect flags
                jmp     XX
SH:
                add     di,bp
                add     bx,dx
                loop    LH              ;doesn't affect flags
                jmp     XX
DIAG_V:
                                        ;mostly-vertical diagonal line
                or      bx,bx           ;set flags initially, set at end of loop for other iterations
LV:
                mov     es:[di],al      ;plot, doesn't affect flags
                jns     SV              ;decision var rollover in bx?
                add     di,bp           ;update y coord
                add     bx,si
                dec     cx
                jnz     LV              ;doesn't affect flags
                jmp     XX
SV:
                scasb                   ;sure this is superfluous but it's a quick way to inc/dec x coord!

                add     di,bp           ;update y coord
                add     bx,dx
                dec     cx
                jnz     LV              ;doesn't affect flags
XX:
                pop     bp
Line_EXIT:      ret
DoLine          endp
;----------------------------- set palette ----------------
SetPalette      proc 
                mov     dx,03c8h
                mov     al,0
                out     dx,al
		mov	dx,3c9h
		mov	al,0
		out	dx,al
		out	dx,al
		out	dx,al

		mov	al,64                
                mov cx,256/4
lp:             dec al
                out dx,al
                out dx,al
                out dx,al

                out dx,al
                out dx,al
                out dx,al

                out dx,al
                out dx,al
                out dx,al

                out dx,al
                out dx,al
                out dx,al
                loop lp
                
                ret
SetPalette      endp
;--------------------------- exit proc --------------------
Exit:           call    OpenSystem      ;
                mov     ax,0c00h        ; Clear Keyboard function
                int     21h             ; Clear It!

                mov     ax,0003h        ; Set back to the standard
                int     10h             ; dos gfx mode. (Nr.3)

                mov     ax,4c00h        ; Exit Nice And Quietly
                int     21h             ; Without Any Trouble To Dos.
;-------------------------- wait vbl ----------------------
WaitVbl         proc    Near
                mov     dx,3dah         ; Move rasterport into DX.
                in      al,dx           ; Move rasterportvalue into al.
                test    al,8h           ; Check If Vbl Bit is set.
                jz      WaitVbl         ; If Not, then go back & check again.
                ret
WaitVbl         endp
;---------------------- St„ng av system interrupt -------------
CloseSystem     proc    Near    
                mov     dx,021h         ; Get Masking Port
                in      al,dx           ; Get Value from port
                mov     SaveINT,al      ; Save it,so it can be restored at exit
                mov     al,10111111b    ; Let keyboard only, be enabled.
                out     dx,al           ; Write the new setting to MaskPort.
                ret 
CloseSYstem     endp
;---------------------- †terstarta system interrupt -----------
OpenSystem      proc    Near 
                mov     dx,021h         ; Get Masking Port
                mov     al,SaveINT      ; Get old value setting
                out     dx,al           ; Write the old setting to MaskPort.
                ret                     ;
OpenSystem      endp
;--------------------------------------------------------------
colorize:       mov dx,3c8h
                xor al,al
                out dx,al
                inc dx
                mov al,63
                out dx,al
                out dx,al
                out dx,al       
                ret

blank:          mov dx,3c8h
                xor al,al
                out dx,al
                inc dx
                mov al,0
                out dx,al
                out dx,al
                out dx,al       
                ret


sintab dw  0 
      dw  327 
      dw  655 
      dw  982 
      dw  1310 
      dw  1637 
      dw  1964 
      dw  2291 
      dw  2618 
      dw  2945 
      dw  3271 
      dw  3597 
      dw  3922 
      dw  4247 
      dw  4572 
      dw  4896 
      dw  5220 
      dw  5543 
      dw  5866 
      dw  6188 
      dw  6509 
      dw  6830 
      dw  7150 
      dw  7470 
      dw  7788 
      dw  8106 
      dw  8423 
      dw  8740 
      dw  9055 
      dw  9369 
      dw  9683 
      dw  9996 
      dw  10307 
      dw  10618 
      dw  10927 
      dw  11235 
      dw  11543 
      dw  11849 
      dw  12154 
      dw  12457 
      dw  12760 
      dw  13061 
      dw  13361 
      dw  13659 
      dw  13956 
      dw  14252 
      dw  14547 
      dw  14839 
      dw  15131 
      dw  15421 
      dw  15709 
      dw  15996 
      dw  16281 
      dw  16565 
      dw  16846 
      dw  17127 
      dw  17405 
      dw  17682 
      dw  17957 
      dw  18230 
      dw  18501 
      dw  18771 
      dw  19039 
      dw  19304 
      dw  19568 
      dw  19830 
      dw  20090 
      dw  20348 
      dw  20603 
      dw  20857 
      dw  21109 
      dw  21358 
      dw  21606 
      dw  21851 
      dw  22094 
      dw  22335 
      dw  22574 
      dw  22810 
      dw  23044 
      dw  23276 
      dw  23505 
      dw  23733 
      dw  23957 
      dw  24180 
      dw  24400 
      dw  24617 
      dw  24832 
      dw  25045 
      dw  25255 
      dw  25462 
      dw  25667 
      dw  25870 
      dw  26069 
      dw  26267 
      dw  26461 
      dw  26653 
      dw  26842 
      dw  27029 
      dw  27213 
      dw  27394 
      dw  27572 
      dw  27748 
      dw  27921 
      dw  28091 
      dw  28258 
      dw  28423 
      dw  28584 
      dw  28743 
      dw  28899 
      dw  29052 
      dw  29202 
      dw  29349 
      dw  29494 
      dw  29635 
      dw  29773 
      dw  29908 
      dw  30041 
      dw  30170 
      dw  30297 
      dw  30420 
      dw  30540 
      dw  30657 
      dw  30771 
      dw  30882 
      dw  30990 
      dw  31095 
      dw  31197 
      dw  31296 
      dw  31391 
      dw  31484 
      dw  31573 
      dw  31659 
      dw  31742 
      dw  31822 
      dw  31898 
      dw  31972 
      dw  32042 
      dw  32109 
      dw  32172 
      dw  32233 
      dw  32290 
      dw  32344 
      dw  32395 
      dw  32443 
      dw  32487 
      dw  32528 
      dw  32566 
      dw  32601 
      dw  32632 
      dw  32660 
      dw  32685 
      dw  32706 
      dw  32725 
      dw  32740 
      dw  32751 
      dw  32760 
      dw  32765 
      dw  32767 
      dw  32766 
      dw  32761 
      dw  32753 
      dw  32742 
      dw  32727 
      dw  32710 
      dw  32689 
      dw  32664 
      dw  32637 
      dw  32606 
      dw  32572 
      dw  32534 
      dw  32494 
      dw  32450 
      dw  32403 
      dw  32353 
      dw  32299 
      dw  32242 
      dw  32182 
      dw  32119 
      dw  32053 
      dw  31983 
      dw  31910 
      dw  31834 
      dw  31755 
      dw  31672 
      dw  31587 
      dw  31498 
      dw  31406 
      dw  31311 
      dw  31213 
      dw  31112 
      dw  31007 
      dw  30900 
      dw  30789 
      dw  30676 
      dw  30559 
      dw  30439 
      dw  30316 
      dw  30191 
      dw  30062 
      dw  29930 
      dw  29795 
      dw  29657 
      dw  29516 
      dw  29372 
      dw  29226 
      dw  29076 
      dw  28924 
      dw  28768 
      dw  28610 
      dw  28449 
      dw  28285 
      dw  28118 
      dw  27948 
      dw  27776 
      dw  27601 
      dw  27423 
      dw  27242 
      dw  27058 
      dw  26872 
      dw  26683 
      dw  26492 
      dw  26298 
      dw  26101 
      dw  25902 
      dw  25700 
      dw  25495 
      dw  25288 
      dw  25078 
      dw  24866 
      dw  24652 
      dw  24434 
      dw  24215 
      dw  23993 
      dw  23769 
      dw  23542 
      dw  23313 
      dw  23081 
      dw  22848 
      dw  22612 
      dw  22373 
      dw  22133 
      dw  21890 
      dw  21645 
      dw  21398 
      dw  21149 
      dw  20898 
      dw  20644 
      dw  20389 
      dw  20131 
      dw  19872 
      dw  19610 
      dw  19346 
      dw  19081 
      dw  18814 
      dw  18545 
      dw  18273 
      dw  18001 
      dw  17726 
      dw  17449 
      dw  17171 
      dw  16891 
      dw  16610 
      dw  16326 
      dw  16041 
      dw  15755 
      dw  15467 
      dw  15177 
      dw  14886 
      dw  14593 
      dw  14299 
      dw  14004 
      dw  13707 
      dw  13408 
      dw  13109 
      dw  12808 
      dw  12506 
      dw  12202 
      dw  11897 
      dw  11592 
      dw  11284 
      dw  10976 
      dw  10667 
      dw  10357 
      dw  10045 
      dw  9733 
      dw  9420 
      dw  9105 
      dw  8790 
      dw  8474 
      dw  8157 
      dw  7839 
      dw  7521 
      dw  7201 
      dw  6881 
      dw  6561 
      dw  6239 
      dw  5917 
      dw  5595 
      dw  5272 
      dw  4948 
      dw  4624 
      dw  4299 
      dw  3974 
      dw  3649 
      dw  3323 
      dw  2997 
      dw  2670 
      dw  2343 
      dw  2017 
      dw  1689 
      dw  1362 
      dw  1035 
      dw  707 
      dw  379 
      dw  52 
      dw -276 
      dw -604 
      dw -931 
      dw -1259 
      dw -1586 
      dw -1913 
      dw -2240 
      dw -2567 
      dw -2894 
      dw -3220 
      dw -3546 
      dw -3871 
      dw -4196 
      dw -4521 
      dw -4846 
      dw -5169 
      dw -5493 
      dw -5815 
      dw -6138 
      dw -6459 
      dw -6780 
      dw -7100 
      dw -7420 
      dw -7739 
      dw -8057 
      dw -8374 
      dw -8690 
      dw -9006 
      dw -9320 
      dw -9634 
      dw -9947 
      dw -10258 
      dw -10569 
      dw -10879 
      dw -11187 
      dw -11495 
      dw -11801 
      dw -12106 
      dw -12410 
      dw -12713 
      dw -13014 
      dw -13314 
      dw -13613 
      dw -13910 
      dw -14206 
      dw -14501 
      dw -14794 
      dw -15085 
      dw -15376 
      dw -15664 
      dw -15951 
      dw -16237 
      dw -16520 
      dw -16803 
      dw -17083 
      dw -17362 
      dw -17639 
      dw -17914 
      dw -18188 
      dw -18459 
      dw -18729 
      dw -18997 
      dw -19263 
      dw -19527 
      dw -19789 
      dw -20049 
      dw -20308 
      dw -20564 
      dw -20818 
      dw -21070 
      dw -21320 
      dw -21568 
      dw -21813 
      dw -22057 
      dw -22298 
      dw -22537 
      dw -22774 
      dw -23008 
      dw -23240 
      dw -23470 
      dw -23697 
      dw -23923 
      dw -24145 
      dw -24366 
      dw -24584 
      dw -24799 
      dw -25012 
      dw -25222 
      dw -25430 
      dw -25636 
      dw -25838 
      dw -26039 
      dw -26236 
      dw -26431 
      dw -26624 
      dw -26813 
      dw -27000 
      dw -27185 
      dw -27366 
      dw -27545 
      dw -27721 
      dw -27895 
      dw -28065 
      dw -28233 
      dw -28398 
      dw -28560 
      dw -28719 
      dw -28875 
      dw -29029 
      dw -29179 
      dw -29327 
      dw -29472 
      dw -29614 
      dw -29752 
      dw -29888 
      dw -30021 
      dw -30151 
      dw -30278 
      dw -30401 
      dw -30522 
      dw -30640 
      dw -30755 
      dw -30866 
      dw -30975 
      dw -31080 
      dw -31182 
      dw -31281 
      dw -31377 
      dw -31470 
      dw -31560 
      dw -31647 
      dw -31730 
      dw -31810 
      dw -31887 
      dw -31961 
      dw -32032 
      dw -32099 
      dw -32164 
      dw -32225 
      dw -32282 
      dw -32337 
      dw -32388 
      dw -32436 
      dw -32481 
      dw -32523 
      dw -32561 
      dw -32596 
      dw -32628 
      dw -32657 
      dw -32682 
      dw -32704 
      dw -32723 
      dw -32739 
      dw -32751 
      dw -32760 
      dw -32765 
      dw -32768 
      dw -32767 
      dw -32763 
      dw -32755 
      dw -32745 
      dw -32731 
      dw -32714 
      dw -32693 
      dw -32669 
      dw -32642 
      dw -32612 
      dw -32578 
      dw -32542 
      dw -32501 
      dw -32458 
      dw -32412 
      dw -32362 
      dw -32309 
      dw -32252 
      dw -32193 
      dw -32130 
      dw -32064 
      dw -31995 
      dw -31923 
      dw -31847 
      dw -31768 
      dw -31687 
      dw -31601 
      dw -31513 
      dw -31422 
      dw -31327 
      dw -31230 
      dw -31129 
      dw -31025 
      dw -30918 
      dw -30808 
      dw -30695 
      dw -30579 
      dw -30459 
      dw -30337 
      dw -30211 
      dw -30083 
      dw -29952 
      dw -29817 
      dw -29680 
      dw -29540 
      dw -29396 
      dw -29250 
      dw -29101 
      dw -28949 
      dw -28794 
      dw -28636 
      dw -28475 
      dw -28312 
      dw -28145 
      dw -27976 
      dw -27804 
      dw -27629 
      dw -27452 
      dw -27271 
      dw -27088 
      dw -26903 
      dw -26714 
      dw -26523 
      dw -26329 
      dw -26133 
      dw -25934 
      dw -25732 
      dw -25528 
      dw -25321 
      dw -25112 
      dw -24900 
      dw -24686 
      dw -24469 
      dw -24250 
      dw -24029 
      dw -23805 
      dw -23578 
      dw -23350 
      dw -23119 
      dw -22885 
      dw -22650 
      dw -22412 
      dw -22171 
      dw -21929 
      dw -21684 
      dw -21438 
      dw -21189 
      dw -20938 
      dw -20685 
      dw -20430 
      dw -20172 
      dw -19913 
      dw -19652 
      dw -19389 
      dw -19123 
      dw -18856 
      dw -18588 
      dw -18317 
      dw -18044 
      dw -17770 
      dw -17493 
      dw -17216 
      dw -16936 
      dw -16654 
      dw -16371 
      dw -16087 
      dw -15801 
      dw -15513 
      dw -15223 
      dw -14932 
      dw -14640 
      dw -14346 
      dw -14051 
      dw -13754 
      dw -13456 
      dw -13156 
      dw -12856 
      dw -12554 
      dw -12250 
      dw -11946 
      dw -11640 
      dw -11333 
      dw -11025 
      dw -10716 
      dw -10406 
      dw -10095 
      dw -9782 
      dw -9469 
      dw -9155 
      dw -8840 
      dw -8524 
      dw -8207 
      dw -7889 
      dw -7571 
      dw -7252 
      dw -6932 
      dw -6611 
      dw -6290 
      dw -5968 
      dw -5646 
      dw -5323 
      dw -4999 
      dw -4675 
      dw -4350 
      dw -4025 
      dw -3700 
      dw -3374 
      dw -3048 
      dw -2722 
      dw -2395 
      dw -2068 
      dw -1741 
      dw -1414 
      dw -1086 
      dw -759 
      dw -431 
      dw -103 

      dw  0 
      dw  327 
      dw  655 
      dw  982 
      dw  1310 
      dw  1637 
      dw  1964 
      dw  2291 
      dw  2618 
      dw  2945 
      dw  3271 
      dw  3597 
      dw  3922 
      dw  4247 
      dw  4572 
      dw  4896 
      dw  5220 
      dw  5543 
      dw  5866 
      dw  6188 
      dw  6509 
      dw  6830 
      dw  7150 
      dw  7470 
      dw  7788 
      dw  8106 
      dw  8423 
      dw  8740 
      dw  9055 
      dw  9369 
      dw  9683 
      dw  9996 
      dw  10307 
      dw  10618 
      dw  10927 
      dw  11235 
      dw  11543 
      dw  11849 
      dw  12154 
      dw  12457 
      dw  12760 
      dw  13061 
      dw  13361 
      dw  13659 
      dw  13956 
      dw  14252 
      dw  14547 
      dw  14839 
      dw  15131 
      dw  15421 
      dw  15709 
      dw  15996 
      dw  16281 
      dw  16565 
      dw  16846 
      dw  17127 
      dw  17405 
      dw  17682 
      dw  17957 
      dw  18230 
      dw  18501 
      dw  18771 
      dw  19039 
      dw  19304 
      dw  19568 
      dw  19830 
      dw  20090 
      dw  20348 
      dw  20603 
      dw  20857 
      dw  21109 
      dw  21358 
      dw  21606 
      dw  21851 
      dw  22094 
      dw  22335 
      dw  22574 
      dw  22810 
      dw  23044 
      dw  23276 
      dw  23505 
      dw  23733 
      dw  23957 
      dw  24180 
      dw  24400 
      dw  24617 
      dw  24832 
      dw  25045 
      dw  25255 
      dw  25462 
      dw  25667 
      dw  25870 
      dw  26069 
      dw  26267 
      dw  26461 
      dw  26653 
      dw  26842 
      dw  27029 
      dw  27213 
      dw  27394 
      dw  27572 
      dw  27748 
      dw  27921 
      dw  28091 
      dw  28258 
      dw  28423 
      dw  28584 
      dw  28743 
      dw  28899 
      dw  29052 
      dw  29202 
      dw  29349 
      dw  29494 
      dw  29635 
      dw  29773 
      dw  29908 
      dw  30041 
      dw  30170 
      dw  30297 
      dw  30420 
      dw  30540 
      dw  30657 
      dw  30771 
      dw  30882 
      dw  30990 
      dw  31095 
      dw  31197 
      dw  31296 
      dw  31391 
      dw  31484 
      dw  31573 
      dw  31659 
      dw  31742 
      dw  31822 
      dw  31898 
      dw  31972 
      dw  32042 
      dw  32109 
      dw  32172 
      dw  32233 
      dw  32290 
      dw  32344 
      dw  32395 
      dw  32443 
      dw  32487 
      dw  32528 
      dw  32566 
      dw  32601 
      dw  32632 
      dw  32660 
      dw  32685 
      dw  32706 
      dw  32725 
      dw  32740 
      dw  32751 
      dw  32760 
      dw  32765 
      dw  32767 
      dw  32766 
      dw  32761 
      dw  32753 
      dw  32742 
      dw  32727 
      dw  32710 
      dw  32689 
      dw  32664 
      dw  32637 
      dw  32606 
      dw  32572 
      dw  32534 
      dw  32494 
      dw  32450 
      dw  32403 
      dw  32353 
      dw  32299 
      dw  32242 
      dw  32182 
      dw  32119 
      dw  32053 
      dw  31983 
      dw  31910 
      dw  31834 
      dw  31755 
      dw  31672 
      dw  31587 
      dw  31498 
      dw  31406 
      dw  31311 
      dw  31213 
      dw  31112 
      dw  31007 
      dw  30900 
      dw  30789 
      dw  30676 
      dw  30559 
      dw  30439 
      dw  30316 
      dw  30191 
      dw  30062 
      dw  29930 
      dw  29795 
      dw  29657 
      dw  29516 
      dw  29372 
      dw  29226 
      dw  29076 
      dw  28924 
      dw  28768 
      dw  28610 
      dw  28449 
      dw  28285 
      dw  28118 
      dw  27948 
      dw  27776 
      dw  27601 
      dw  27423 
      dw  27242 
      dw  27058 
      dw  26872 
      dw  26683 
      dw  26492 
      dw  26298 
      dw  26101 
      dw  25902 
      dw  25700 
      dw  25495 
      dw  25288 
      dw  25078 
      dw  24866 
      dw  24652 
      dw  24434 
      dw  24215 
      dw  23993 
      dw  23769 
      dw  23542 
      dw  23313 
      dw  23081 
      dw  22848 
      dw  22612 
      dw  22373 
      dw  22133 
      dw  21890 
      dw  21645 
      dw  21398 
      dw  21149 
      dw  20898 
      dw  20644 
      dw  20389 
      dw  20131 
      dw  19872 
      dw  19610 
      dw  19346 
      dw  19081 
      dw  18814 
      dw  18545 
      dw  18273 
      dw  18001 
      dw  17726 
      dw  17449 
      dw  17171 
      dw  16891 
      dw  16610 
      dw  16326 
      dw  16041 
      dw  15755 
      dw  15467 
      dw  15177 
      dw  14886 
      dw  14593 
      dw  14299 
      dw  14004 
      dw  13707 
      dw  13408 
      dw  13109 
      dw  12808 
      dw  12506 
      dw  12202 
      dw  11897 
      dw  11592 
      dw  11284 
      dw  10976 
      dw  10667 
      dw  10357 
      dw  10045 
      dw  9733 
      dw  9420 
      dw  9105 
      dw  8790 
      dw  8474 
      dw  8157 
      dw  7839 
      dw  7521 
      dw  7201 
      dw  6881 
      dw  6561 
      dw  6239 
      dw  5917 
      dw  5595 
      dw  5272 
      dw  4948 
      dw  4624 
      dw  4299 
      dw  3974 
      dw  3649 
      dw  3323 
      dw  2997 
      dw  2670 
      dw  2343 
      dw  2017 
      dw  1689 
      dw  1362 
      dw  1035 
      dw  707 
      dw  379 
      dw  52 
      dw -276 
      dw -604 
      dw -931 
      dw -1259 
      dw -1586 
      dw -1913 
      dw -2240 
      dw -2567 
      dw -2894 
      dw -3220 
      dw -3546 
      dw -3871 
      dw -4196 
      dw -4521 
      dw -4846 
      dw -5169 
      dw -5493 
      dw -5815 
      dw -6138 
      dw -6459 
      dw -6780 
      dw -7100 
      dw -7420 
      dw -7739 
      dw -8057 
      dw -8374 
      dw -8690 
      dw -9006 
      dw -9320 
      dw -9634 
      dw -9947 
      dw -10258 
      dw -10569 
      dw -10879 
      dw -11187 
      dw -11495 
      dw -11801 
      dw -12106 
      dw -12410 
      dw -12713 
      dw -13014 
      dw -13314 
      dw -13613 
      dw -13910 
      dw -14206 
      dw -14501 
      dw -14794 
      dw -15085 
      dw -15376 
      dw -15664 
      dw -15951 
      dw -16237 
      dw -16520 
      dw -16803 
      dw -17083 
      dw -17362 
      dw -17639 
      dw -17914 
      dw -18188 
      dw -18459 
      dw -18729 
      dw -18997 
      dw -19263 
      dw -19527 
      dw -19789 
      dw -20049 
      dw -20308 
      dw -20564 
      dw -20818 
      dw -21070 
      dw -21320 
      dw -21568 
      dw -21813 
      dw -22057 
      dw -22298 
      dw -22537 
      dw -22774 
      dw -23008 
      dw -23240 
      dw -23470 
      dw -23697 
      dw -23923 
      dw -24145 
      dw -24366 
      dw -24584 
      dw -24799 
      dw -25012 
      dw -25222 
      dw -25430 
      dw -25636 
      dw -25838 
      dw -26039 
      dw -26236 
      dw -26431 
      dw -26624 
      dw -26813 
      dw -27000 
      dw -27185 
      dw -27366 
      dw -27545 
      dw -27721 
      dw -27895 
      dw -28065 
      dw -28233 
      dw -28398 
      dw -28560 
      dw -28719 
      dw -28875 
      dw -29029 
      dw -29179 
      dw -29327 
      dw -29472 
      dw -29614 
      dw -29752 
      dw -29888 
      dw -30021 
      dw -30151 
      dw -30278 
      dw -30401 
      dw -30522 
      dw -30640 
      dw -30755 
      dw -30866 
      dw -30975 
      dw -31080 
      dw -31182 
      dw -31281 
      dw -31377 
      dw -31470 
      dw -31560 
      dw -31647 
      dw -31730 
      dw -31810 
      dw -31887 
      dw -31961 
      dw -32032 
      dw -32099 
      dw -32164 
      dw -32225 
      dw -32282 
      dw -32337 
      dw -32388 
      dw -32436 
      dw -32481 
      dw -32523 
      dw -32561 
      dw -32596 
      dw -32628 
      dw -32657 
      dw -32682 
      dw -32704 
      dw -32723 
      dw -32739 
      dw -32751 
      dw -32760 
      dw -32765 
      dw -32768 
      dw -32767 
      dw -32763 
      dw -32755 
      dw -32745 
      dw -32731 
      dw -32714 
      dw -32693 
      dw -32669 
      dw -32642 
      dw -32612 
      dw -32578 
      dw -32542 
      dw -32501 
      dw -32458 
      dw -32412 
      dw -32362 
      dw -32309 
      dw -32252 
      dw -32193 
      dw -32130 
      dw -32064 
      dw -31995 
      dw -31923 
      dw -31847 
      dw -31768 
      dw -31687 
      dw -31601 
      dw -31513 
      dw -31422 
      dw -31327 
      dw -31230 
      dw -31129 
      dw -31025 
      dw -30918 
      dw -30808 
      dw -30695 
      dw -30579 
      dw -30459 
      dw -30337 
      dw -30211 
      dw -30083 
      dw -29952 
      dw -29817 
      dw -29680 
      dw -29540 
      dw -29396 
      dw -29250 
      dw -29101 
      dw -28949 
      dw -28794 
      dw -28636 
      dw -28475 
      dw -28312 
      dw -28145 
      dw -27976 
      dw -27804 
      dw -27629 
      dw -27452 
      dw -27271 
      dw -27088 
      dw -26903 
      dw -26714 
      dw -26523 
      dw -26329 
      dw -26133 
      dw -25934 
      dw -25732 
      dw -25528 
      dw -25321 
      dw -25112 
      dw -24900 
      dw -24686 
      dw -24469 
      dw -24250 
      dw -24029 
      dw -23805 
      dw -23578 
      dw -23350 
      dw -23119 
      dw -22885 
      dw -22650 
      dw -22412 
      dw -22171 
      dw -21929 
      dw -21684 
      dw -21438 
      dw -21189 
      dw -20938 
      dw -20685 
      dw -20430 
      dw -20172 
      dw -19913 
      dw -19652 
      dw -19389 
      dw -19123 
      dw -18856 
      dw -18588 
      dw -18317 
      dw -18044 
      dw -17770 
      dw -17493 
      dw -17216 
      dw -16936 
      dw -16654 
      dw -16371 
      dw -16087 
      dw -15801 
      dw -15513 
      dw -15223 
      dw -14932 
      dw -14640 
      dw -14346 
      dw -14051 
      dw -13754 
      dw -13456 
      dw -13156 
      dw -12856 
      dw -12554 
      dw -12250 
      dw -11946 
      dw -11640 
      dw -11333 
      dw -11025 
      dw -10716 
      dw -10406 
      dw -10095 
      dw -9782 
      dw -9469 
      dw -9155 
      dw -8840 
      dw -8524 
      dw -8207 
      dw -7889 
      dw -7571 
      dw -7252 
      dw -6932 
      dw -6611 
      dw -6290 
      dw -5968 
      dw -5646 
      dw -5323 
      dw -4999 
      dw -4675 
      dw -4350 
      dw -4025 
      dw -3700 
      dw -3374 
      dw -3048 
      dw -2722 
      dw -2395 
      dw -2068 
      dw -1741 
      dw -1414 
      dw -1086 
      dw -759 
      dw -431 
      dw -103 
end
