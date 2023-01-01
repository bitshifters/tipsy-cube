.equ OS_WriteC, 0
.equ OS_WriteO, 2
.equ OS_WriteN, 0x46
.equ OS_NewLine, 3
.equ OS_Byte, 6
.equ XOS_Byte, OS_Byte | (1 << 17)
.equ OS_Word, 7
.equ XOS_Word, OS_Word | (1 << 17)
.equ OS_File, 8
.equ OS_Exit, 0x11
.equ OS_BreakPt, 0x17
.equ OS_Mouse, 0x1c
.equ OS_ChangeDynamicArea, 0x2a
.equ OS_GenerateError, 0x2b
.equ OS_ReadEscapeState, 0x2c
.equ OS_ReadVduVariables, 0x31
.equ OS_ReadMonotonicTime, 0x42
.equ OS_Plot, 0x45
.equ OS_ReadDynamicArea, 0x5c
.equ OS_ConvertHex2, 0xd1
.equ OS_ConvertHex4, 0xd2
.equ OS_ConvertHex8, 0xd4
.equ OS_ConvertCardinal1, 0xd5	
.equ OS_ConvertCardinal4, 0xd8
.equ OS_WriteI, 0x100

.equ OSByte_EventEnable, 14
.equ OSByte_EventDisable, 13
.equ OSByte_Vsync, 19
.equ OSByte_WriteVDUBank, 112
.equ OSByte_WriteDisplayBank, 113
.equ OSByte_KeyboardScan, 121
.equ OSByte_ReadKey, 129

.equ OSWord_WritePalette, 12

.equ IKey_LeftClick, 0xf6
.equ IKey_RightClick, 0xf4
.equ IKey_Space, 0x9d
.equ IKey_Return, 0xB6
.equ IKey_Escape, 0x8f
.equ IKey_S, 0xae
.equ IKey_D, 0xcd
.equ IKey_R, 0xcc
.equ IKey_Escape, 0x8f
.equ IKey_ArrowUp, 198
.equ IKey_ArrowDown, 214
.equ IKey_ArrowLeft, 230
.equ IKey_ArrowRight, 134
.equ IKey_Return, 0xB6

.equ RMKey_ArrowUp, 0x59
.equ RMKey_ArrowDown, 0x63
.equ RMKey_Return, 0x47
.equ RMKey_Space, 0x5f
.equ RMKey_LeftClick, 0x70
.equ RMKey_RightClick, 0x72
.equ RMKey_A, 0x3c

.equ DynArea_Screen, 2

.equ VD_ScreenStart, 148 

.equ OS_Claim, 0x1f
.equ OS_Release, 0x20
.equ OS_AddToVector, 0x47

.equ ErrorV, 0x01
.equ EventV, 0x10
.equ Event_VSync, 4

.equ QTM_Load, 0x47E40
.equ QTM_Start, 0x47E41
.equ QTM_Stop, 0x47E42
.equ QTM_Pause, 0x47E43
.equ QTM_Clear, 0x47E44
.equ QTM_Pos, 0x47E46
.equ QTM_Volume, 0x47E48
.equ QTM_SetSampleSpeed, 0x47E49
.equ QTM_Stereo, 0x47E4D
.equ QTM_VUBarControl, 0x47E50
.equ QTM_ReadVULevels, 0x47E51
.equ QTM_SoundControl, 0x47E58
.equ QTM_MusicOptions, 0x47E5E
.equ QTM_MusicInterrupt, 0x47E5F

.equ MusicInterrupt_SongEnded, 0

.equ RasterMan_Install, 0x47e80
.equ RasterMan_Release, 0x47e81
.equ RasterMan_Wait, 0x47e82
.equ RasterMan_SetTables, 0x47e83
.equ RasterMan_Version, 0x47e84
.equ RasterMan_ReadScanline, 0x47e85
.equ RasterMan_SetVIDCRegister, 0x47e86
.equ RasterMan_SetMEMCRegister, 0x47e87
.equ RasterMan_QTMParamAddr, 0x47e88
.equ RasterMan_ScanKeyboard, 0x47e89
.equ RasterMan_ClearKeyBuffer, 0x47e8a
.equ RasterMan_ReadScanAddr, 0x47e8b
.equ RasterMan_Configure, 0x47e8c

.equ VIDC_Col0, 0x00000000
.equ VIDC_Col1, 0x04000000              ; index << 26
.equ VIDC_Col2, 0x08000000
.equ VIDC_Col3, 0x0c000000
.equ VIDC_Col4, 0x10000000
.equ VIDC_Col5, 0x14000000
.equ VIDC_Col6, 0x18000000
.equ VIDC_Col7, 0x1c000000
.equ VIDC_Col8, 0x20000000
.equ VIDC_Col9, 0x24000000
.equ VIDC_Col10, 0x28000000
.equ VIDC_Col11, 0x2c000000
.equ VIDC_Col12, 0x30000000
.equ VIDC_Col13, 0x34000000
.equ VIDC_Col14, 0x38000000
.equ VIDC_Col15, 0x3c000000
.equ VIDC_Border, 0x40000000

.equ VIDC_Write, 0x03400000
.equ VIDC_HBorderStart, 0x88000000      ; (M-1)/2 pixels << 14 [odd]
.equ VIDC_HDisplayStart, 0x8C000000     ; (M-7)/2 MODE 9 pixels << 14 [x7]
.equ VIDC_HDisplayEnd, 0x90000000       ; (M-7)/2 MODE 9 pixels << 14 [x7]
.equ VIDC_HBorderEnd, 0x94000000        ; (M-1)/2 pixels << 14 [odd]
.equ VIDC_VBorderStart, 0xA8000000      ; N-1 rasters << 14
.equ VIDC_VDisplayStart, 0xAC000000     ; N-1 rasters << 14
.equ VIDC_VDisplayEnd, 0xB0000000       ; N-1 rasters << 14
.equ VIDC_VBorderEnd, 0xB4000000        ; N-1 rasters << 14

.equ MODE9_HCentrePixels, 291
.equ MODE9_VCentreRasters, 166
