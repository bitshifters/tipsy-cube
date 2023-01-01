; ============================================================================
; Rubber cube.
; ============================================================================

.equ RUBBER_CUBE_LIGHTING, 1        ; TODO: Use RasterMan to do this per line.
.equ RUBBER_CUBE_DELAY_SHIFT, 16     ; 16=-Y, 15=-Y/2, 0=none
.equ RUBBER_CUBE_SPLIT, 1

; WARNING: Code must change if these do!
.equ RUBBER_CUBE_MAX_FRAMES, 1024
.equ RUBBER_CUBE_FACES_SIZE, 64


init_rubber_cube:
    str lr, [sp, #-4]!
    mov r0, #0
    str r0, rubber_cube_frame

    ; Run the update 256 times to prime the frame list.
    .1:
    bl update_rubber_cube

    ; Update the rubber cube frame.
    ldr r0, rubber_cube_frame
    add r0, r0, #MATHS_CONST_1
    bics r0, r0, #0xfc000000           ; assumes RUBBER_CUBE_MAX_FRAMES=1024
    str r0, rubber_cube_frame
    bne .1

    ldr pc, [sp], #4


update_rubber_cube:
    str lr, [sp, #-4]!

    ; Rotate the object, transform verts & normals, update scene vars.
    bl update_3d_scene

    .if _ENABLE_ROCKET
    mov r0, #6
    bl rocket_sync_get_val
    str r1, rubber_cube_line_delta

    mov r0, #7
    bl rocket_sync_get_val
    str r1, rubber_cube_split_delta
    .endif

    ; Project vertices to screen.
    adr r2, transformed_verts
    ldr r11, object_num_verts
    adr r12, projected_verts
    .1:
    ; R2=ptr to world pos vector
    bl project_to_screen
    ; R0=screen_x, R1=screen_y [16.16]
    mov r0, r0, asr #16         ; [16.0]
    mov r1, r1, asr #16         ; [16.0]
    stmia r12!, {r0, r1}
    add r2, r2, #VECTOR3_SIZE
    subs r11, r11, #1
    bne .1

    ; Track min & max y for object.
    .if _POLYGON_STORE_MIN_MAX_Y
    mov r0, #65536
    str r0, object_min_y
    mov r0, #-65536
    str r0, object_max_y
    .endif

    ; Determine visible faces.
    mov r11, #0                 ; face_index
    ldr r9, object_num_faces    ;
    mov r6, #0                  ; visible faces

    ; R12 = ptr to edge list buffer for frame.
    ldr r0, rubber_cube_frame
    mov r0, r0, lsr #16         ; frame [8.0]
    ldr r12, p_rubber_cube_edge_list
    add r12, r12, r0, lsl #7    ; edge_list + frame * 128
    add r12, r12, r0, lsl #6    ;           + frame * 64  = &edge_list[frame]
    
    ; R10 = ptr to rubber cube frame.
    ldr r10, p_rubber_cube_face_list
    add r10, r10, r0, lsl #6    ; frame_ptr = frame_list + frame * 64
    .if _POLYGON_STORE_MIN_MAX_Y
    add r10, r10, #12           ; needs updating to visible faces.
    .endif

    .2:

    adr r5, object_face_indices
    ldrb r5, [r5, r11, lsl #2]  ; vertex0_index=object_face_indices[face_index][0]

    adr r1, transformed_verts
    add r1, r1, r5, lsl #3
    add r1, r1, r5, lsl #2      ; transformed_verts + vertex0_index*12

    adr r2, transformed_normals
    add r2, r2, r11, lsl #3
    add r2, r2, r11, lsl #2     ; face_normal + face_index*12

    bl backface_cull_test       ; (vertex0 - camera_pos).face_normal

    cmp r0, #0                  
    bpl .3                      ; normal facing away from the view direction.

    .if _POLYGON_STORE_MIN_MAX_Y
    mov r0, #65536
    str r0, polygon_min_y
    mov r0, #-65536
    str r0, polygon_max_y
    .endif

    adr r2, projected_verts     ; projected vertex array.
    adr r5, object_face_indices
    ldr r3, [r5, r11, lsl #2]   ; quad indices = object_face_indices[face_index]

    stmfd sp!, {r6, r9-r11}
    ; Convert polygon indices to an edge list.
    ; R12 = updated ptr to edge list for frame [xs, m, ys, ye]
    bl polygon_quad_to_edge_list    ; Trashes: r0-r1, r4-r10
    mov r0, r11                 ; R11=number of edges.
    ldmfd sp!, {r6, r9-r11}

    ; Write number of edges into rubber frame face list.
    str r0, [r10], #4

    ; Write face colour into rubber frame face list.
    .if RUBBER_CUBE_LIGHTING
    ; Simple directional lighting from -z.
    adr r2, transformed_normals
    add r2, r2, r11, lsl #3
    add r2, r2, r11, lsl #2     ; face_normal + face_index*12
    ldr r0, [r2, #8]            ; face_normal.z
    cmp r0, #0
    rsbmi r0, r0, #0            ; make positive. [0.16]
                                ; otherwise it should be v small.
    mov r0, r0, asr #11         ; [0.5]
    cmp r0, #0x20
    movge r0, #0x1f             ; clamp to [0-15]

    add r2, r11, #1             ; colour index = face index+1
    orr r2, r2, r2, lsl #4
    orr r2, r2, r2, lsl #8      ; convert to colour half word

    orr r0, r0, r2, lsl #16     ; colour half word | face intensity
    .else
    add r0, r11, #1             ; colour index = face index+1

    ; Convert colour index to colour word.
    orr r0, r0, r0, lsl #4
    orr r0, r0, r0, lsl #8
    orr r0, r0, r0, lsl #16
    .endif

    str r0, [r10], #4           ; colour_word

    ; Store polygon min/max y in face list.
    ; Also update object min/max y at the same time.
    .if _POLYGON_STORE_MIN_MAX_Y
    ldr r1, object_min_y
    ldr r0, polygon_min_y
    cmp r0, r1
    strlt r0, object_min_y
    str r0, [r10], #4

    ldr r1, object_max_y
    ldr r0, polygon_max_y
    cmp r0, r1
    strgt r0, object_max_y
    str r0, [r10], #4
    .endif

    add r6, r6, #1              ; visible_faces++

    .3:
    add r11, r11, #1            ; face_index++
    cmp r11, r9
    blt .2

    .if _DEBUG
    cmp r6, #0                  ; no visible faces?
    adreq R0,polyerror          ; and flag an error
    swieq OS_GenerateError      ; when necessary
    .endif

    ; Write number of visible faces for rubber frame.
    ldr r0, rubber_cube_frame
    mov r0, r0, lsr #16         ; frame [8.0]
    ; R10 = ptr to rubber cube frame.
    ldr r10, p_rubber_cube_face_list
    add r10, r10, r0, lsl #6    ; frame_list + frame * 64
    str r6, [r10], #4           ; write number of visible faces.

    .if _POLYGON_STORE_MIN_MAX_Y
    ldr r0, object_min_y
    ldr r1, object_max_y
    stmia r10!, {r0, r1}
    .endif

    ldr pc, [sp], #4

p_rubber_cube_face_list:
    .long rubber_cube_face_list

p_rubber_cube_edge_list:
    .long rubber_cube_edge_list

; R11 = screen address
draw_rubber_cube:
    str lr, [sp, #-4]!

    ; For each scanline Y.
    mov r8, #0
    .1:
    .if RUBBER_CUBE_LIGHTING
    ldr r4, raster_tables + 0   ; vidc_table_1
    add r4, r4, #4      ; use vidc_table_2 if need to double-buffer raster table.
    add r4, r4, r8, lsl #4 
    mov r5, #VIDC_Col0 | 0x000
    str r5, [r4], #4
    str r5, [r4], #4
    str r5, [r4], #4
    .endif

    ; Determine historical frame to use for this line.
    ldr r0, rubber_cube_frame   ; start simple = frame - Y

    .if RUBBER_CUBE_SPLIT
    tst r8, #1
    ldreq r1, rubber_cube_split_delta
    subeq r0, r0, r1
    .endif

    .if _ENABLE_ROCKET
    ldr r1, rubber_cube_line_delta
    mul r1, r8, r1
    sub r0, r0, r1
    .else
    sub r0, r0, r8, lsl #RUBBER_CUBE_DELAY_SHIFT     ; or lsl #15 to use Y/2
    .endif

    bic r0, r0, #0xfc000000
    mov r0, r0, lsr #16         ; frame [8.0]

    ; Locate ptr to edges for this frame.
    ldr r12, p_rubber_cube_edge_list
    add r12, r12, r0, lsl #7    ; edge_list + frame * 128
    add r12, r12, r0, lsl #6    ;           + frame * 64  = &edge_list[frame]

    ; Locate ptr to frame data.
    ldr r7, p_rubber_cube_face_list
    add r7, r7, r0, lsl #6      ; frame_ptr = frame_list + frame * 64
    ldr r0, [r7], #4            ; visible faces

    .if _POLYGON_STORE_MIN_MAX_Y
    ; Track min/max y for object to early out before the face loop.
    ldmia r7!, {r1, r2}
    cmp r8, r1                  ; y < min
    blt .5                      ; skip scanline.
    cmp r8, r2                  ; y > max
    bge .5                      ; skip scanline.
    .endif

    ; For each visible face in the frame [r0]
    .2:
    ; Get number of edges and face colour word.
    ldmia r7!, {r2, r9}

    ; Use min & max y for the face to early out if not on this scanline.
    .if _POLYGON_STORE_MIN_MAX_Y
    ldmia r7!, {r4, r5}
    cmp r8, r4                  ; y < polygon_min_y?
    addlt r12, r12, r2, lsl #4  ; edge_list+=16*number edges
    blt .6                      ; skip face.
    cmp r8, r5                  ; y > polygon_max_y?
    addge r12, r12, r2, lsl #4  ; edge_list+=16*number edges
    bge .6                      ; skip face.
    .endif

    sub r2, r2, #1              ; number edges remaining.
    mov r1, #0x8000             ; track (xs,xe) span.

    ; For each edge in the visible face.
    .3:
    ; Get edge vars.
    ldmia r12!, {r3-r6}         ; [xs, ys, ye, m]

    ;   Determine edges such that ys <= Y <= ye
    cmp r8, r4
    blt .4
    cmp r8, r5
    bge .4

    ; Compute edge intersection with scanline: x = xs + m * (y - ys)
    sub r4, r8, r4              ; y - ys                 [8.0]
    mla r3, r6, r4, r3          ; x = xs + (y - ys) * m  [8.0] * [8.16] = [16.16]

    ; Clip span
    cmp r3, #0                  ; off left hand side of screen? (x<0)
    movlt r3, #0                ; clamp left.
    cmp r3, #Screen_Width<<PRECISION_BITS   ; off right hand side?
    ldrgt r3, polygon_clip_right_side       ; clamp right

    ; Keep track of span (xs, xe)
    movs r1, r1, lsl #1         ; shift counting bit into carry.
    mov r1, r1, lsl #15         ; shift x value to upper 16 bits.
    orr r1, r1, r3, lsr #16     ; mask integer portion into lower bits.

    ; Early out if we have had two edge matches.
    addcs r12, r12, r2, lsl #4  ; edge_list+=16*remaining edges
    bcs .7

    ; Next edge.
    .4:
    subs r2, r2, #1             ; remaining edges
    bpl .3

    cmp r1, #0x8000             ; no matching edges?
    beq .6                      ; skip plot.

    .7:
    ; Plot span for face.

    ; Unpack [x1, x2] into separate registers.
    mov r2, r1, lsr #16         ; xs
    mov r1, r1, lsl #16
    mov r1, r1, lsr #16         ; xe

    cmp r1, r2                  ; if xe < xs?
    eorlt r1, r1, r2            ;
    eorlt r2, r1, r2            ;
    eorlt r1, r1, r2            ; swap x1, x2

    sub r1, r1, #1              ; omit last pixel for polygon plot.
    subs r4, r1, r2             ; length of span
    bmi .6                      ; skip if no pixels.

	mov r3, r2, lsr #3          ; xs DIV 8
    ; Can compute r10 from screen_addr+r8 if we have to load it.
	add r10, r11, r3, lsl #2    ; ptr to start word

    and r3, r2, #7              ; x start offset [0-7] pixel
    add r3, r3, r4, lsl #3      ; + span length * 8
    adr lr, .6                  ; link address.
	ldr r6, gen_code_pointers_p
    ; Uses: r1, r3, r6, r9, r10, r11.

    .if RUBBER_CUBE_LIGHTING
    ; Intensity.
    mov r2, r9, lsr #28         ; face index.
    adr r5, face_1_ramp-128
    add r5, r5, r2, lsl #7      ; face_0_ramp + face index * 128

    and r2, r9, #0x1f           ; intensity.
    ldr r5, [r5, r2, lsl #2]    ; face_[index]_ramp[intensity]

    ldr r4, raster_tables + 0   ; vidc_table_1
    add r4, r4, r0, lsl #2      ; visible faces * 4
    str r5, [r4, r8, lsl #4]    ; for this scanine only.      

    ; Extract colour word.
    mov r9, r9, lsr #16         ; half word.
    orr r9, r9, r9, lsl #16     ; full word.
    .endif

    .if _SPAN_GEN_MULTI_WORD
    ; r2, r4, r5, r9 as colour words when using multi-word span plot.
    mov r2, r9
    mov r4, r9
    mov r5, r9
    .endif

    ; Preserve: r0 (num faces), r7 (face list), r12 (edge list), r8 (y)
    ldr pc, [r6, r3, lsl #2]    ; jump to plot function.

    .6:

    ; Next face.
    subs r0, r0, #1
    bne .2

    .5:
    ; Next scanline Y.
    add r11, r11, #Screen_Stride
    add r8, r8, #1
    cmp r8, #Screen_Height
    blt .1

    ; Update the rubber cube frame.
    ldr r0, rubber_cube_frame
    add r0, r0, #MATHS_CONST_1
    bic r0, r0, #0xfc000000           ; assumes RUBBER_CUBE_MAX_FRAMES=1024
    str r0, rubber_cube_frame

    ldr pc, [sp], #4


rubber_cube_frame:
    .long 0

rubber_cube_line:
    .long 0

rubber_cube_line_delta:
    .long 0

rubber_cube_split_delta:
    .long 0

object_min_y:
    .long 0

object_max_y:
    .long 0

.if RUBBER_CUBE_LIGHTING
face_1_ramp:
    .long VIDC_Col1 | 0x000
    .long VIDC_Col1 | 0x000
    .long VIDC_Col1 | 0x000
    .long VIDC_Col1 | 0x000
    .long VIDC_Col1 | 0x001
    .long VIDC_Col1 | 0x001
    .long VIDC_Col1 | 0x002
    .long VIDC_Col1 | 0x002
    .long VIDC_Col1 | 0x003
    .long VIDC_Col1 | 0x003
    .long VIDC_Col1 | 0x004
    .long VIDC_Col1 | 0x004
    .long VIDC_Col1 | 0x005
    .long VIDC_Col1 | 0x005
    .long VIDC_Col1 | 0x006
    .long VIDC_Col1 | 0x006

    .long VIDC_Col1 | 0x007
    .long VIDC_Col1 | 0x008
    .long VIDC_Col1 | 0x009
    .long VIDC_Col1 | 0x00a
    .long VIDC_Col1 | 0x00b
    .long VIDC_Col1 | 0x00c
    .long VIDC_Col1 | 0x00d
    .long VIDC_Col1 | 0x00e
    .long VIDC_Col1 | 0x00f
    .long VIDC_Col1 | 0x11f
    .long VIDC_Col1 | 0x22f
    .long VIDC_Col1 | 0x33f
    .long VIDC_Col1 | 0x44f
    .long VIDC_Col1 | 0x55f
    .long VIDC_Col1 | 0x66f
    .long VIDC_Col1 | 0x77f

face_2_ramp:
    .long VIDC_Col2 | 0x000
    .long VIDC_Col2 | 0x000
    .long VIDC_Col2 | 0x000
    .long VIDC_Col2 | 0x000
    .long VIDC_Col2 | 0x010
    .long VIDC_Col2 | 0x010
    .long VIDC_Col2 | 0x020
    .long VIDC_Col2 | 0x020
    .long VIDC_Col2 | 0x030
    .long VIDC_Col2 | 0x030
    .long VIDC_Col2 | 0x040
    .long VIDC_Col2 | 0x040
    .long VIDC_Col2 | 0x050
    .long VIDC_Col2 | 0x050
    .long VIDC_Col2 | 0x060
    .long VIDC_Col2 | 0x060

    .long VIDC_Col2 | 0x070
    .long VIDC_Col2 | 0x080
    .long VIDC_Col2 | 0x090
    .long VIDC_Col2 | 0x0a0
    .long VIDC_Col2 | 0x0b0
    .long VIDC_Col2 | 0x0c0
    .long VIDC_Col2 | 0x0d0
    .long VIDC_Col2 | 0x0e0
    .long VIDC_Col2 | 0x0f0
    .long VIDC_Col2 | 0x1f1
    .long VIDC_Col2 | 0x2f2
    .long VIDC_Col2 | 0x3f3
    .long VIDC_Col2 | 0x4f4
    .long VIDC_Col2 | 0x5f5
    .long VIDC_Col2 | 0x6f6
    .long VIDC_Col2 | 0x7f7

face_3_ramp:
    .long VIDC_Col3 | 0x000
    .long VIDC_Col3 | 0x000
    .long VIDC_Col3 | 0x000
    .long VIDC_Col3 | 0x000
    .long VIDC_Col3 | 0x011
    .long VIDC_Col3 | 0x011
    .long VIDC_Col3 | 0x022
    .long VIDC_Col3 | 0x022
    .long VIDC_Col3 | 0x033
    .long VIDC_Col3 | 0x033
    .long VIDC_Col3 | 0x044
    .long VIDC_Col3 | 0x044
    .long VIDC_Col3 | 0x055
    .long VIDC_Col3 | 0x055
    .long VIDC_Col3 | 0x066
    .long VIDC_Col3 | 0x066

    .long VIDC_Col3 | 0x077
    .long VIDC_Col3 | 0x088
    .long VIDC_Col3 | 0x099
    .long VIDC_Col3 | 0x0aa
    .long VIDC_Col3 | 0x0bb
    .long VIDC_Col3 | 0x0cc
    .long VIDC_Col3 | 0x0dd
    .long VIDC_Col3 | 0x0ee
    .long VIDC_Col3 | 0x0ff
    .long VIDC_Col3 | 0x1ff
    .long VIDC_Col3 | 0x2ff
    .long VIDC_Col3 | 0x3ff
    .long VIDC_Col3 | 0x4ff
    .long VIDC_Col3 | 0x5ff
    .long VIDC_Col3 | 0x6ff
    .long VIDC_Col3 | 0x7ff

face_4_ramp:
    .long VIDC_Col4 | 0x000
    .long VIDC_Col4 | 0x000
    .long VIDC_Col4 | 0x000
    .long VIDC_Col4 | 0x000
    .long VIDC_Col4 | 0x100
    .long VIDC_Col4 | 0x100
    .long VIDC_Col4 | 0x200
    .long VIDC_Col4 | 0x200
    .long VIDC_Col4 | 0x300
    .long VIDC_Col4 | 0x300
    .long VIDC_Col4 | 0x400
    .long VIDC_Col4 | 0x400
    .long VIDC_Col4 | 0x500
    .long VIDC_Col4 | 0x500
    .long VIDC_Col4 | 0x600
    .long VIDC_Col4 | 0x600

    .long VIDC_Col4 | 0x700
    .long VIDC_Col4 | 0x800
    .long VIDC_Col4 | 0x900
    .long VIDC_Col4 | 0xa00
    .long VIDC_Col4 | 0xb00
    .long VIDC_Col4 | 0xc00
    .long VIDC_Col4 | 0xd00
    .long VIDC_Col4 | 0xe00
    .long VIDC_Col4 | 0xf00
    .long VIDC_Col4 | 0xf11
    .long VIDC_Col4 | 0xf22
    .long VIDC_Col4 | 0xf33
    .long VIDC_Col4 | 0xf44
    .long VIDC_Col4 | 0xf55
    .long VIDC_Col4 | 0xf66
    .long VIDC_Col4 | 0xf77

face_5_ramp:
    .long VIDC_Col5 | 0x000
    .long VIDC_Col5 | 0x000
    .long VIDC_Col5 | 0x000
    .long VIDC_Col5 | 0x000
    .long VIDC_Col5 | 0x101
    .long VIDC_Col5 | 0x101
    .long VIDC_Col5 | 0x202
    .long VIDC_Col5 | 0x202
    .long VIDC_Col5 | 0x303
    .long VIDC_Col5 | 0x303
    .long VIDC_Col5 | 0x404
    .long VIDC_Col5 | 0x404
    .long VIDC_Col5 | 0x505
    .long VIDC_Col5 | 0x505
    .long VIDC_Col5 | 0x606
    .long VIDC_Col5 | 0x606

    .long VIDC_Col5 | 0x707
    .long VIDC_Col5 | 0x808
    .long VIDC_Col5 | 0x909
    .long VIDC_Col5 | 0xa0a
    .long VIDC_Col5 | 0xb0b
    .long VIDC_Col5 | 0xc0c
    .long VIDC_Col5 | 0xd0d
    .long VIDC_Col5 | 0xe0e
    .long VIDC_Col5 | 0xf0f
    .long VIDC_Col5 | 0xf1f
    .long VIDC_Col5 | 0xf2f
    .long VIDC_Col5 | 0xf3f
    .long VIDC_Col5 | 0xf4f
    .long VIDC_Col5 | 0xf5f
    .long VIDC_Col5 | 0xf6f
    .long VIDC_Col5 | 0xf7f

face_6_ramp:
    .long VIDC_Col6 | 0x000
    .long VIDC_Col6 | 0x000
    .long VIDC_Col6 | 0x000
    .long VIDC_Col6 | 0x000
    .long VIDC_Col6 | 0x110
    .long VIDC_Col6 | 0x110
    .long VIDC_Col6 | 0x220
    .long VIDC_Col6 | 0x220
    .long VIDC_Col6 | 0x330
    .long VIDC_Col6 | 0x330
    .long VIDC_Col6 | 0x440
    .long VIDC_Col6 | 0x440
    .long VIDC_Col6 | 0x550
    .long VIDC_Col6 | 0x550
    .long VIDC_Col6 | 0x660
    .long VIDC_Col6 | 0x660

    .long VIDC_Col6 | 0x770
    .long VIDC_Col6 | 0x880
    .long VIDC_Col6 | 0x990
    .long VIDC_Col6 | 0xaa0
    .long VIDC_Col6 | 0xbb0
    .long VIDC_Col6 | 0xcc0
    .long VIDC_Col6 | 0xdd0
    .long VIDC_Col6 | 0xee0
    .long VIDC_Col6 | 0xff0
    .long VIDC_Col6 | 0xff1
    .long VIDC_Col6 | 0xff2
    .long VIDC_Col6 | 0xff3
    .long VIDC_Col6 | 0xff4
    .long VIDC_Col6 | 0xff5
    .long VIDC_Col6 | 0xff6
    .long VIDC_Col6 | 0xff7
.endif
