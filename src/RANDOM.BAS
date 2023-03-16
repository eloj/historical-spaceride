OPEN "RndTxt.Asm" FOR OUTPUT AS #1
    
        RANDOMIZE TIMER
        FOR coords = 0 TO 100
                x = INT(RND * 226)
                y = INT(RND * 194)
                PRINT #1, "     dw"; x; ","; y
        NEXT coords

CLOSE #1

