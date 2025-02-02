; ============================================================================
; Division routines.
; ============================================================================

; x = 0.0 to 256.0 [1 to 1<<8]
; There are 1<<16 table entries so x<<(16-8) = x<<8
; Table is 1<<24 / x<<8 = (1/x) << 16

; If want x = 0.0 to 1024.0 [1 to 1<<10]
; There are 1<<16 table entries so x<<(16-10) = x<<6
; Then table is 1<<22 / x<<6 = (1/x) << 16

; If want x = 0.0 to 1024.0 [1 to 1<<10]
; There are 1<<12 table entries so x<<(12-10) = x<<2
; Then table is 1<<(16+2) / x<<2 = (1/x) << 16

; If want x = 0.0 to M [1 to 1<<m]
; There are 1<<t table entries.
; Shift for x, s=(t-m) so x<<(t-m) in the table.
; If maths precision is 1<<p.
; Then table is 1<<(p+s) / x<<s.

; If want x = 0.0 to 1024.0 [m=10]
; But only a small table, say 256 entries, i.e. t=8
; Then shift s=(8-10) = -2. So x>>2 in the table.
; Table is (1<<p+s) / x<<s = 1<<14 / x>>2


.equ Reciprocal_t, 16           ; Table entries = 1<<t
.equ Reciprocal_m, 9            ; Max value = 1<<m
.equ Reciprocal_s, Reciprocal_t-Reciprocal_m    ; Table is (1<<16+s)/(x<<s)

; Divide R0 by R1
; Parameters:
;  R0=numerator  [s15.16]       ; (a<<16)
;  R1=divisor    [s15.16]       ; (b<<16)
; Trashes:
;  R8-R10
divide:
    ; Signed division - any better way to do this?
    eor r10, r0, r1             ; R0 eor R1 indicates sign of result
    cmp r0, #0
    rsbmi r0, r0, #0            ; make positive
    cmp r1, #0
    rsbmi r1, r1, #0            ; make positive  

    .if _USE_RECIPROCAL_TABLE
    mov r1, r1, asr #16-Reciprocal_s    ; [16.6]    (b<<s)

    .if _DEBUG
    cmp r1,#0                   ; Test for division by zero
    adreq r0,divbyzero          ; and flag an error
    swieq OS_GenerateError      ; when necessary
    .endif

    cmp r0, #0                  ; Test if result is zero
    moveq pc, lr

    ldr r9, reciprocal_table_p

    .if _DEBUG
    ; Limited precision.
    cmp r1, #1<<Reciprocal_t    ; Test for numerator too large
    adrge R0,divrange           ; and flag an error
    swige OS_GenerateError      ; when necessary
    .endif

; TODO: These bits should be cleared by shifting left if necessary.
;   bic r1, r1, #0xff0000       ; [10.6]    (b<<6)
    ldr r1, [r9, r1, lsl #2]    ; [0.16]    (1<<16+s)/(b<<s) = (1<<16)/b

    mov r0, r0, asr #16-Reciprocal_s    ; [16.6]    (a<<s)
    mul r9, r0, r1                      ; [10.22]   (a<<s)*(1<<16)/b = (a<<16+s)/b
    mov r9, r9, asr #Reciprocal_s       ; [10.16]   (a<<16)/b = (a/b)<<16
    .else

    ; Limited precision.
    ; TODO: Make configurable - fixed to m=10, i.e. max value=1024.
    mov r1, r1, asr #10         ; [16.6]    (b<<6)
    CMP R1,#0                   ; Test for division by zero
    ADREQ R0,divbyzero          ; and flag an error
    SWIEQ OS_GenerateError      ; when necessary

    mov r0, r0, asl #6          ; [10.22]   (a<<22)
    cmp r0, #0                  ; Test if result is zero
    moveq pc, lr

    ; Taken from Archimedes Operating System, page 28.
    MOV R8, #1
    MOV R9, #0
    CMP R1, #0
    .1:                         ; raiseloop
    BMI .3
    CMP R1,R0
    BHI .2
    MOVS R1,R1,LSL #1
    MOV R8,R8,LSL #1
    B .1  
    .3:                         ; raisedone
    CMP R0,R1
    SUBCS R0,R0,R1
    ADDCS R9,R9,R8              ; Accumulate result
    .2:                         ; nearlydone
    MOV R1,R1,LSR #1
    MOVS R8,R8,LSR #1
    BCC .3
                                ; (a<<22) / (b<<6) = (a/b) << 16
    .endif

    movs r10, r10               ; get sign back
    movpl r0, r9                ; Move positive result into R0*
    rsbmi r0, r9, #0            ; Neative result into R0*
    MOV PC,R14                  ; and return

    ; * Remove the lines marked with asterisks to
    ; return R0 MOD R1 instead of R0 DIV R1

    divbyzero: ;The error block
    .long 18
	.byte "Divide by Zero"
	.p2align 2
	.long 0

    divrange: ;The error block
    .long 18
	.byte "Division out of range"
	.p2align 2
	.long 0

.if _USE_RECIPROCAL_TABLE
; Trashes: r0-r2, r8-r9, r12
MakeReciprocal:
    ldr r12, reciprocal_table_p
    mov r2, #0
    str r2, [r12], #4
 
    mov r2, #1
.4:
    mov r0, #1<<(16+Reciprocal_s)       ; assumes PRECISION_BITS==16
    mov r1, r2

    ; Taken from Archimedes Operating System, page 28.
    MOV R8, #1
    MOV R9, #0
    CMP R1, #0
    .1:                         ; raiseloop
    BMI .3
    CMP R1,R0
    BHI .2
    MOVS R1,R1,LSL #1
    MOV R8,R8,LSL #1
    B .1  
    .3:                         ; raisedone
    CMP R0,R1
    SUBCS R0,R0,R1
    ADDCS R9,R9,R8              ; Accumulate result
    .2:                         ; nearlydone
    MOV R1,R1,LSR #1
    MOVS R8,R8,LSR #1
    BCC .3

    str r9, [r12], #4
    add r2, r2, #1
    cmp r2, #1<<Reciprocal_t
    blt .4

    mov pc, lr
.endif
