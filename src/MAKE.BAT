del space.exe >nul
del space.obj >nul 
Tasm Space.Asm /m9
Tlink Space.Obj
Space.Exe
