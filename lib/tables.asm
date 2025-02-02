; ============================================================================
; Library module tables (include at end).
; ============================================================================

.p2align 6

; ============================================================================
; Data tables.
; ============================================================================

sinus_table:
	.incbin "build/sine_8192.bin"

; ============================================================================

.if _INCLUDE_SQRT
sqrt_table:
	.incbin "build/sqrt_1024.bin"

rsqrt_table:
	.incbin "build/rsqrt_1024.bin"
.endif

; ============================================================================
