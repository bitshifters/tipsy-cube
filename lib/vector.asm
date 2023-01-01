; ============================================================================
; Vector routines.
; ============================================================================

.equ VECTOR3_SIZE, 3*4

.macro VECTOR3 x, y, z
    FLOAT_TO_FP \x
    FLOAT_TO_FP \y
    FLOAT_TO_FP \z
.endm

.macro VECTOR3_ZERO
    VECTOR3 0.0, 0.0, 0.0
.endm

; TODO: make_vector?

.if 0   ; UNUSED
; Vector add.
; Parameters:
;  R0=ptr to vector C.
;  R1=ptr to vector A.
;  R2=ptr to vector B.
; Trashes: R3-R8
;
; Computes C = A + B
;
; A = [ a1 ]   B = [ b1 ]  C = [ a1 + b1 ]
;     [ a2 ]       [ b2 ]      [ a2 + b2 ]
;     [ a3 ]       [ b3 ]      [ a3 + b2 ]
;
vector_add:
    ldmia r1, {r3-r5}
    ldmia r2, {r6-r8}
    
    add r3, r3, r6
    add r4, r4, r7
    add r5, r5, r8

    stmia r0, {r3-r5}
    mov pc, lr


; Vector subtract.
; Parameters:
;  R0=ptr to vector C.
;  R1=ptr to vector A.
;  R2=ptr to vector B.
; Trashes: R3-R8
;
; Computes C = A + B
;
; A = [ a1 ]   B = [ b1 ]  C = [ a1 - b1 ]
;     [ a2 ]       [ b2 ]      [ a2 - b2 ]
;     [ a3 ]       [ b3 ]      [ a3 - b2 ]
;
vector_sub:
    ldmia r1, {r3-r5}
    ldmia r2, {r6-r8}
    
    sub r3, r3, r6
    sub r4, r4, r7
    sub r5, r5, r8

    stmia r0, {r3-r5}
    mov pc, lr
.endif

; Dot product.
; Parameters:
;  R1=ptr to vector A.
;  R2=ptr to vector B.
; Returns:
;  R0=dot product of A and B.
; Trashes: R3-R8
;
; Computes R0 = A . B where:
;
; A = [ a1 ]   B = [ b1 ]
;     [ a2 ]       [ b2 ]
;     [ a3 ]       [ b3 ]
;
; A.B = a1 * b1 + a2 * b2 + a3 * b3
; A.B = |A||B|.cos T
;
vector_dot_product:
    ldmia r1, {r3-r5}                   ; [s15.16]
vector_dot_product_load_B:
    ldmia r2, {r6-r8}                   ; [s15.16]

vector_dot_product_no_load:
    mov r3, r3, asr #MULTIPLICATION_SHIFT    ; [s15.8]
    mov r4, r4, asr #MULTIPLICATION_SHIFT    ; [s15.8]
    mov r5, r5, asr #MULTIPLICATION_SHIFT    ; [s15.8]
    mov r6, r6, asr #MULTIPLICATION_SHIFT    ; [s15.8]
    mov r7, r7, asr #MULTIPLICATION_SHIFT    ; [s15.8]
    mov r8, r8, asr #MULTIPLICATION_SHIFT    ; [s15.8]

    mul r0, r3, r6                      ; r0 = a1 * b1  [s30.16] potential overflow
    mla r0, r4, r7, r0                  ;   += a2 * b2  [s30.16] potential overflow
    mla r0, r5, r8, r0                  ;   += a3 * b3  [s30.16] potential overflow

    mov pc, lr


; Vector interpolation.
; Parameters:
;  R0=ptr to vector C.
;  R1=ptr to vector A.
;  R2=ptr to vector B.
;  R9=lerp value [0.0-1.0]      ; [1.16]
; Trashes: R3-R9
;
; Computes C = A + (B - A) * v
;
; A = [ a1 ]   B = [ b1 ]  C = [ a1 + (b1 - a1) * v ]
;     [ a2 ]       [ b2 ]      [ a2 + (b2 - a2) * v ]
;     [ a3 ]       [ b3 ]      [ a3 + (b3 - a3) * v ]
;
vector_lerp:
    ldmia r1, {r3-r5}          ; vertex A
    ldmia r2, {r6-r8}          ; vertex B

    ; Calculate B-A
    sub r6, r6, r3              ; (b1 - a1)
    sub r7, r7, r4              ; (b2 - a2)
    sub r8, r8, r5              ; (b3 - a3)

    mov r6, r6, asr #MULTIPLICATION_SHIFT    ; [s15.8]
    mov r7, r7, asr #MULTIPLICATION_SHIFT    ; [s15.8]
    mov r8, r8, asr #MULTIPLICATION_SHIFT    ; [s15.8]
    mov r9, r9, asr #MULTIPLICATION_SHIFT    ; [1.8]

    mla r3, r6, r9, r3          ; a1 + (b1 - a1) * v
    mla r4, r7, r9, r4          ; a2 + (b2 - a2) * v
    mla r5, r8, r9, r5          ; a3 + (b3 - a3) * v

    stmia r0, {r3-r5}
    mov r9, r9, asl #MULTIPLICATION_SHIFT
    mov pc, lr


.if _INCLUDE_SQRT           ; these functions rely on SQRT.
; Length of vector.
; Parameters:
;  R1=ptr to vector A.
; Returns:
;  R0=length of vector A.
; Trashes: R2-R9
;
; Compute length = sqrt(x*x + y*y + z*z)
vector_length:
    str lr, [sp, #-4]!
    mov r2, r1              ; B=A
    bl vector_dot_product   ; Compute A.A = (x*x + y*y + z*z)
    mov r1, r0
    bl sqrt                 ; trashes R9
    ldr pc, [sp], #4


; Squared length of vector.
; Parameters:
;  R1=ptr to vector A.
; Returns:
;  R0=length of vector A.
; Trashes: R2-R8
;
; Compute sq_length = x*x + y*y + z*z
vector_sq_length:
    str lr, [sp, #-4]!
    mov r2, r1              ; B=A
    bl vector_dot_product   ; Compute A.A = (x*x + y*y + z*z)
    ldr pc, [sp], #4


; 1/length of vector.
; Parameters:
;  R1=ptr to vector A.
; Returns:
;  R0=length of vector A.
; Trashes: R2-R9
;
; Compute 1/length = rsqrt(x*x + y*y + z*z)
vector_recip_length:
    str lr, [sp, #-4]!
    mov r2, r1              ; B=A
    bl vector_dot_product   ; Compute A.A = (x*x + y*y + z*z)
    mov r1, r0
    bl rsqrt                ; trashes R9
    ldr pc, [sp], #4
.endif

.if _DEBUG
; R0=vector ptr.
debug_write_vector:
    stmfd sp!, {r0, r3, lr}
    mov r3, r0
    ldr r0, [r3, #0]
    bl debug_write_fp
    ldr r0, [r3, #4]
    bl debug_write_fp
    ldr r0, [r3, #8]
    bl debug_write_fp
    ldmfd sp!, {r0, r3, pc}
.endif

.if 0               ; Feels like too early optimisation.
; Dot product.
; Parameters:
;  R1=ptr to vector A.
;  R2=ptr to unit vector B.
; Returns:
;  R0=dot product of A and B.
; Trashes: R3-R8
;
; Computes R0 = A . B where B is a unit vector.
;
vector_dot_product_unit:
    ldmia r1, {r3-r5}                   ; [s15.16]
    ldmia r2, {r6-r8}                   ; [s1.16]

    mul r0, r3, r6                      ; r0 = a1 * b1  [s16.32] overflow!
    mla r0, r4, r7, r0                  ;   += a2 * b2  [s16.32] overflow!
    mla r0, r5, r8, r0                  ;   += a3 * b3  [s16.32] overflow!

    mov r0, r0, asr #PRECISION_BITS     ; [s15.24]
    mov pc, lr
.endif
