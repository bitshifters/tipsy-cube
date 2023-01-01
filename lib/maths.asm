; ============================================================================
; Maths routines.
; ============================================================================

.equ PRECISION_BITS, 16
.equ MULTIPLICATION_SHIFT, PRECISION_BITS/2
.equ PRECISION_MULTIPLIER, 1<<PRECISION_BITS

.equ MATHS_CONST_0, 0
.equ MATHS_CONST_QUARTER, 1<<(PRECISION_BITS-2)
.equ MATHS_CONST_HALF, 1<<(PRECISION_BITS-1)
.equ MATHS_CONST_1, (1<<PRECISION_BITS)

; General notes.
;  Typically assume that all fixed-point values are [s15.16]
;  So 1 sign bit, 15 bits of integer [0-32767] and 16 factional bits [~0.00002]
;
;  In practice values are assumed to be more like [s7.8] for multiplication
;  and division accuracy. So 1 sign bit, 7 bits of integer [0-127] and 8
;  fractional bits [~0.004].
;
; When multiplying we shift >> 8 to avoid overflow, so:
;     (a * b) = (a >> 8) * (b >> 8)
;
; When dividing we shift the numerator << 8 and the divisor >> 8, so:
;     (a / b) = (a << 8) / (b >> 8)
; Or if using a reciprocal table in [0.16]:
;     (a / b) = a * (1 / b) = ((a >> 8) * reciprocal(b)) >> 8
;
maths_init:
    str lr, [sp, #-4]!
    .if _MAKE_SINUS_TABLE
    bl MakeSinus
    .endif
    .if _USE_RECIPROCAL_TABLE
    bl MakeReciprocal
    .endif
    .if _INCLUDE_SPAN_GEN
    bl gen_code
    .endif
    ldr pc, [sp], #4

.if _DEBUG
; R0=fp value.
debug_write_fp:
    stmfd sp!, {r1, r2}
	adr r1, debug_string
	mov r2, #16
	swi OS_ConvertHex8
	adr r0, debug_string
	swi OS_WriteO
    mov r0, #32
    swi OS_WriteC
    ldmfd sp!, {r1, r2}
    mov pc, lr
.endif

.macro FLOAT_TO_FP value
    .long 1<<PRECISION_BITS * (\value)
.endm

; ============================================================================

.include "lib/sine.asm"
.include "lib/vector.asm"
.include "lib/matrix.asm"
.include "lib/divide.asm"
.include "lib/polygon.asm"
.if _INCLUDE_SQRT
.include "lib/sqrt.asm"
.endif
.if _INCLUDE_SPAN_GEN
.include "lib/span_gen.asm"
.endif

; ============================================================================
