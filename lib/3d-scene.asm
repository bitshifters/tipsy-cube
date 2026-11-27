; ============================================================================
; 3D Scene.
; ============================================================================

.equ OBJ_MAX_VERTS, 8
.equ OBJ_MAX_FACES, 6
.equ OBJ_MAX_VISIBLE_FACES, 3       ; True for cube.
.equ OBJ_VERTS_PER_FACE, 4
.equ OBJ_MAX_EDGES_PER_FACE, OBJ_VERTS_PER_FACE

.equ LERP_3D_SCENE, 1

; The camera viewport is assumed to be [-1,+1] across its widest axis.
; Therefore we multiply all projected coordinates by the screen width/2
; in order to map the viewport onto the entire screen.

.equ VIEWPORT_SCALE,    (Screen_Width /2) * PRECISION_MULTIPLIER
.equ VIEWPORT_CENTRE_X, (Screen_Width /2) * PRECISION_MULTIPLIER
.equ VIEWPORT_CENTRE_Y, (Screen_Height/2) * PRECISION_MULTIPLIER

; ============================================================================
; Scene data.
; ============================================================================

; For simplicity, we assume that the camera has a FOV of 90 degrees, so the
; distance to the view plane is 'd' is the same as the viewport scale. All
; coordinates (x,y) lying on the view plane +d from the camera map 1:1 with
; screen coordinates.
;
;   h = viewport_scale / d.
;
; However as much of our maths in the scene is calculated as [8.16] maximum
; precision, having a camera distance of 160 only leaves 96 untis of depth
; to place objects within z=[0, 96] before potential problems occur.
;
; To solve this we use a smaller camera distance. d=80, giving h=160/80=2.
; This means that all vertex coordinates will be multiplied up by 2 when
; transformed to screen coordinates. E.g. the point (32,32,0) will map
; to (64,64) on the screen.
;
; This now gives us z=[0,176] to play with before any overflow errors are
; likely to occur. If this does happen, then we can further reduce the
; coordinate space and use d=40, h=4, etc.


camera_pos:
    VECTOR3 0.0, 0.0, -80.0

; Note camera is fixed to view down +z axis.
; TODO: Camera rotation/direction/look at?

object_pos:
    VECTOR3 0.0, 0.0, 16.0

object_rot:
    VECTOR3 0.0, 0.0, 0.0

object_transform:
    MATRIX33_IDENTITY

temp_matrix_1:
    MATRIX33_IDENTITY

temp_matrix_2:
    MATRIX33_IDENTITY

temp_vector_1:
    VECTOR3_ZERO

temp_vector_2:
    VECTOR3_ZERO

.if LERP_3D_SCENE
lerp_value:
    .long 0
.endif

; ============================================================================
; ============================================================================

init_3d_scene:
    str lr, [sp, #-4]!

    adr r2, object_transform
    bl matrix_make_identity

    ldr pc, [sp], #4

; ============================================================================
; ============================================================================

update_3d_scene:
    str lr, [sp, #-4]!

    .if _ENABLE_ROCKET
    mov r0, #0
    bl rocket_sync_get_val
    str r1, object_pos+0

    mov r0, #1
    bl rocket_sync_get_val
    str r1, object_pos+4

    mov r0, #2
    bl rocket_sync_get_val
    str r1, object_pos+8

    .if LERP_3D_SCENE
    mov r0, #8
    bl rocket_sync_get_val
    str r1, lerp_value
    .endif
    .endif

    .if 1
    ; Create rotation matrix as object transform.
    adr r2, temp_matrix_1
    ldr r0, object_rot + 0
    bl matrix_make_rotate_x

    adr r2, object_transform
    ldr r0, object_rot + 4
    bl matrix_make_rotate_y

    adr r0, temp_matrix_1
    adr r1, object_transform
    adr r2, temp_matrix_2
    bl matrix_multiply

    adr r2, temp_matrix_1
    ldr r0, object_rot + 8
    bl matrix_make_rotate_z

    adr r0, temp_matrix_2
    adr r1, temp_matrix_1
    adr r2, object_transform
    bl matrix_multiply
    .else
    ; Updating the rotation matrix in this way resulting in minification.
    ; Presume repeated precision loss during mutiply causing this.
    ; Would need the rotation only matrix multiplication routine here.
    adr r0, object_transform
    adr r1, delta_transform
    adr r2, temp_matrix
    bl matrix_multiply

    adr r0, object_transform
    adr r2, temp_matrix
    ldmia r2!, {r3-r11}
    stmia r0!, {r3-r11}
    .endif

    ; Hard coded object lerp.
    .if LERP_3D_SCENE
    bl lerp_3d_objects
    .endif

    adr r11, object_pos

    ; Transform vertices in scene.
    adr r0, object_transform
    adr r1, object_verts
    adr r2, transformed_verts
    ldr r10, object_num_verts
    .1:
    ; R0=ptr to matrix, R1=vector A, R2=vector B
    bl matrix_multiply_vector
    ; TODO: Array version of this function.

    ; Add object position here to move into world space!
    ldmia r2, {r3-r5}
    ldmia r11, {r6-r8}
    add r3, r3, r6
    add r4, r4, r7
    add r5, r5, r8
    stmia r2!, {r3-r5}
    
    add r1, r1, #VECTOR3_SIZE
    subs r10, r10, #1
    bne .1

    ; Transform normals.
    adr r0, object_transform
    adr r1, object_face_normals
    adr r2, transformed_normals
    ldr r10, object_num_faces
    .2:
    ; R0=ptr to matrix, R1=vector A, R2=vector B
    bl matrix_multiply_vector
    ; TODO: Array version of this function.
    add r1, r1, #VECTOR3_SIZE
    add r2, r2, #VECTOR3_SIZE
    subs r10, r10, #1
    bne .2

    ; Update any scene vars, camera, object position etc. (Rocket?)
    .if _ENABLE_ROCKET
    mov r0, #3                      ; track #3
    bl rocket_sync_get_val
    .else
    mov r1, #0                      ; ROTATION_X
    .endif
    ldr r0, object_rot+0
    add r0, r0, r1
    bic r0, r0, #0xff000000         ; brads
    str r0, object_rot+0

    .if _ENABLE_ROCKET
    mov r0, #4                      ; track #4
    bl rocket_sync_get_val
    .else
    mov r1, #MATHS_CONST_QUARTER    ; ROTATION_Y
    .endif
    ldr r0, object_rot+4
    add r0, r0, r1
    bic r0, r0, #0xff000000         ; brads
    str r0, object_rot+4

    .if _ENABLE_ROCKET
    mov r0, #5                      ; track #5
    bl rocket_sync_get_val
    .else
    mov r1, #MATHS_CONST_QUARTER    ; ROTATION_Z
    .endif
    ldr r0, object_rot+8
    add r0, r0, r1
    bic r0, r0, #0xff000000         ; brads
    str r0, object_rot+8

    ldr pc, [sp], #4

; ============================================================================
; ============================================================================

draw_3d_scene:
    str lr, [sp, #-4]!

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

    ; Plot vertices as pixels.
    .if 0
    ldr r12, screen_addr
    adr r3, projected_verts
    ldr r9, object_num_verts
    .2:
    ldmia r3!, {r0, r1}

    ; TODO: Clipping.

    mov r4, #0x07               ; colour.
    bl plot_pixel
    subs r9, r9, #1
    bne .2
    .endif

    ; Plot faces as lines.
    .if 0
    ldr r12, screen_addr
    adr r11, object_face_indices
    adr r10, projected_verts
    adr r6, transformed_normals
    ldr r9, object_num_faces
    .2:
    ldrb r5, [r11, #0]          ; vertex0 of polygon.

    adr r1, transformed_verts
    add r1, r1, r5, lsl #3
    add r1, r1, r5, lsl #2      ; transformed_verts + index*12
    mov r2, r6                  ; face_normal

    bl backface_cull_test       ; (vertex0 - camera_pos).face_normal

    cmp r0, #0
    bpl .3                      ; normal facing away from the view direction.

    mov r4, #0x07               ; colour.

    ldrb r5, [r11, #0]          ; vertex0 of polygon.
    add r7, r10, r5, lsl #3     ; projected_verts + index*8
    ldmia r7, {r0, r1}          ; x_start, y_start

    ldrb r5, [r11, #1]
    add r7, r10, r5, lsl #3     ; projected_verts + index*8
    ldmia r7, {r2, r3}          ; x_end, y_end

    bl drawline

    ldrb r5, [r11, #1]
    add r7, r10, r5, lsl #3     ; projected_verts + index*8
    ldmia r7, {r0, r1}          ; x_start, y_start

    ldrb r5, [r11, #2]
    add r7, r10, r5, lsl #3     ; projected_verts + index*8
    ldmia r7, {r2, r3}          ; x_end, y_end

    bl drawline

    ldrb r5, [r11, #2]
    add r7, r10, r5, lsl #3     ; projected_verts + index*8
    ldmia r7, {r0, r1}          ; x_start, y_start

    ldrb r5, [r11, #3]
    add r7, r10, r5, lsl #3     ; projected_verts + index*8
    ldmia r7, {r2, r3}          ; x_end, y_end

    bl drawline

    ldrb r5, [r11, #3]
    add r7, r10, r5, lsl #3     ; projected_verts + index*8
    ldmia r7, {r0, r1}          ; x_start, y_start

    ldrb r5, [r11, #0]
    add r7, r10, r5, lsl #3     ; projected_verts + index*8
    ldmia r7, {r2, r3}          ; x_end, y_end

    bl drawline

    .3:
    add r6, r6, #VECTOR3_SIZE
    add r11, r11, #4
    subs r9, r9, #1
    bne .2
    .endif

    ; Plot faces as polys.
    .if 1
    ldr r12, screen_addr
    adr r11, object_face_indices
    adr r10, projected_verts
    adr r6, transformed_normals
    ldr r9, object_num_faces
    mov r4, #0x01               ; colour.
    .2:
    ldrb r5, [r11, #0]          ; vertex0 of polygon.
    
    adr r1, transformed_verts
    add r1, r1, r5, lsl #3
    add r1, r1, r5, lsl #2      ; transformed_verts + index*12
    mov r2, r6                  ; face_normal

    bl backface_cull_test       ; (vertex0 - camera_pos).face_normal

    cmp r0, #0                  
    bpl .3                      ; normal facing away from the view direction.

    ; Simple directional lighting from -z.
    ldr r4, [r6, #8]            ; face_normal.z
    cmp r4, #0
    rsbmi r4, r4, #0            ; make positive. [0.16]
                                ; otherwise it should be v small.
    mov r4, r4, lsr #12         ; [0.4]
    cmp r4, #0x10
    movge r4, #0x0f             ; clamp to [0-15]

    mov r2, r10                 ; projected vertex array.
    ldr r3, [r11]               ; quad indices
    stmfd sp!, {r6, r9-r12}
    bl polygon_plot_quad
    ldmfd sp!, {r6, r9-r12}

    .3:
    add r6, r6, #VECTOR3_SIZE
    add r11, r11, #4
    subs r9, r9, #1
    bne .2
    .endif

    ldr pc, [sp], #4

; Backfacing culling test.
; Parameters:
;  R1=ptr to vertex in world space
;  R2=ptr to face normal vector
; Return:
;  R0=dot product of (v0-cp).n
; Trashes: r3-r8
backface_cull_test:
    stmfd sp!, {r6, lr}

    ldmia r1, {r3-r5}
    ldr r6, camera_pos+0
    ldr r7, camera_pos+4
    ldr r8, camera_pos+8
    sub r3, r3, r6
    sub r4, r4, r7
    sub r5, r5, r8          ; vertex - camera_pos

    ; vector A already in (r3, r4, r5)
    ; vector B = face normal
    bl vector_dot_product_load_B
    ldmfd sp!, {r6, pc}


; Project world position to screen coordinates.
;
; R2=ptr to position in world space vector
; Returns:
;  R0=screen x
;  R1=screen y
; Trashes: R3-R10
project_to_screen:
    str lr, [sp, #-4]!

    ldmia r2, {r3-r5}           ; (x,y,z)
    ldr r6, camera_pos
    ldr r7, camera_pos+4
    ldr r8, camera_pos+8

    ; eye_pos = world_pos - camera_pos
    sub r3, r3, r6
    sub r4, r4, r7
    sub r5, r5, r8

    ; vp_centre_x + vp_scale * (x-cx) / (z-cz)
    mov r0, r3                  ; (x-cx)
    mov r1, r5                  ; (z-cz)
    bl divide                   ; (x-cx)/(z-cz)
                                ; [0.16]
    mov r7, #VIEWPORT_SCALE>>12 ; [16.4]
    mul r6, r0, r7              ; [12.20]
    mov r6, r6, asr #4          ; [12.16]
    mov r8, #VIEWPORT_CENTRE_X  ; [16.16]
    add r6, r6, r8

    ; Flip Y axis as we want +ve Y to point up the screen!
    ; vp_centre_y - vp_scale * (y-cy) / (z-cz)
    mov r0, r4                  ; (y-cy)
    mov r1, r5                  ; (z-cz)
    bl divide                   ; (y-cy)/(z-cz)
                                ; [0.16]
    mov r7, #VIEWPORT_SCALE>>12 ; [16.4]
    mul r1, r0, r7              ; [12.20]
    mov r1, r1, asr #4          ; [12.16]
    mov r8, #VIEWPORT_CENTRE_Y  ; [16.16]
    sub r1, r8, r1              ; [16.16]

    mov r0, r6
    ldr pc, [sp], #4


.if LERP_3D_SCENE
; Simple linear interpolation of objects.
; Current fixed between cube and column object.
; NB. Only lerps vertex positions.
;     Doesn't lerp face normals!
;
lerp_3d_objects:
    str lr, [sp, #-4]!
    adr r1, cube_verts
    adr r2, column_verts
    adr r0, object_verts
    ldr r10, object_num_verts
    ldr r9, lerp_value          ; [1.16]
.1:
    bl vector_lerp
    add r0, r0, #VECTOR3_SIZE
    add r1, r1, #VECTOR3_SIZE
    add r2, r2, #VECTOR3_SIZE
    ; TODO: Decide whether vector functions just advance ptrs.
    subs r10, r10, #1
    bne .1
    ldr pc, [sp], #4
.endif

; ============================================================================
; Object data: CUBE
;
;         4         5        y
;          +------+          ^  z
;         /      /|          |/
;        /      / |          +--> x
;     0 +------+ 1|
;       | 7 +  |  + 6
;       |      | /
;       |      |/
;       +------+
;      3        2
; ============================================================================

object_num_verts:
    .long 8

object_verts:
    VECTOR3 -32.0,  32.0, -32.0
    VECTOR3  32.0,  32.0, -32.0
    VECTOR3  32.0, -32.0, -32.0
    VECTOR3 -32.0, -32.0, -32.0
    VECTOR3 -32.0,  32.0,  32.0
    VECTOR3  32.0,  32.0,  32.0
    VECTOR3  32.0, -32.0,  32.0
    VECTOR3 -32.0, -32.0,  32.0

.if LERP_3D_SCENE
cube_verts:     ; CUBE
    VECTOR3 -32.0,  32.0, -32.0
    VECTOR3  32.0,  32.0, -32.0
    VECTOR3  32.0, -32.0, -32.0
    VECTOR3 -32.0, -32.0, -32.0
    VECTOR3 -32.0,  32.0,  32.0
    VECTOR3  32.0,  32.0,  32.0
    VECTOR3  32.0, -32.0,  32.0
    VECTOR3 -32.0, -32.0,  32.0

column_verts:   ; COLUMN
    VECTOR3 -16.0,  64.0, -16.0
    VECTOR3  16.0,  64.0, -16.0
    VECTOR3  16.0, -64.0, -16.0
    VECTOR3 -16.0, -64.0, -16.0
    VECTOR3 -16.0,  64.0,  16.0
    VECTOR3  16.0,  64.0,  16.0
    VECTOR3  16.0, -64.0,  16.0
    VECTOR3 -16.0, -64.0,  16.0
.endif

object_num_faces:
    .long 6

; Winding order is clockwise (from outside)
object_face_indices:
    .byte 0, 1, 2, 3
    .byte 1, 5, 6, 2
    .byte 5, 4, 7, 6
    .byte 4, 0, 3, 7
    .byte 0, 4, 5, 1
    .byte 2, 3, 7, 6

object_face_normals:
    VECTOR3  0.0,  0.0, -1.0
    VECTOR3  1.0,  0.0,  0.0
    VECTOR3  0.0,  0.0,  1.0
    VECTOR3 -1.0,  0.0,  0.0
    VECTOR3  0.0,  1.0,  0.0
    VECTOR3  0.0  -1.0,  0.0
 
 ;TODO: Object face colours or vertex colours etc.

; ============================================================================
; Scene data.
; ============================================================================

transformed_verts:
    .skip OBJ_MAX_VERTS * VECTOR3_SIZE

transformed_normals:
    .skip OBJ_MAX_FACES * VECTOR3_SIZE

; TODO: Decide on how to store these, maybe packed or separate array?
projected_verts:
    .skip OBJ_MAX_VERTS * 2 * 4

polygon_buffer:
    .skip OBJ_VERTS_PER_FACE * 2 * 4

; ============================================================================

.if 0 ; PYRAMID - but would have to make the face normals correct...
    VECTOR3 -16.0,  32.0, -16.0
    VECTOR3  16.0,  32.0, -16.0
    VECTOR3  64.0, -32.0, -64.0
    VECTOR3 -64.0, -32.0, -64.0
    VECTOR3 -16.0,  32.0,  16.0
    VECTOR3  16.0,  32.0,  16.0
    VECTOR3  64.0, -32.0,  64.0
    VECTOR3 -64.0, -32.0,  64.0
.endif
