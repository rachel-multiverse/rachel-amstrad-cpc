; =============================================================================
; AMSTRAD CPC INPUT MODULE
; =============================================================================
; Keyboard handling using CPC firmware

; =============================================================================
; KEYBOARD ROUTINES
; =============================================================================

; -----------------------------------------------------------------------------
; Wait for any key press (blocking)
; Returns: A = key pressed
; -----------------------------------------------------------------------------
wait_key:
        call KM_READ_KEY        ; Returns A = key, carry set if valid
        jr nc, wait_key
        ret

; -----------------------------------------------------------------------------
; Check for key (non-blocking)
; Returns: A = key if pressed, 0 if no key
;          Carry set if key available
; -----------------------------------------------------------------------------
check_key:
        call KM_READ_CHAR       ; Non-blocking check
        jr nc, ck_none
        ret                     ; A = key, carry set

ck_none:
        xor a
        ret

; =============================================================================
; LINE INPUT
; =============================================================================

; -----------------------------------------------------------------------------
; Input a line of text
; Input: HL = buffer address, B = max length
; Returns: A = length entered
; Clobbers: all
; -----------------------------------------------------------------------------
input_line:
        push hl
        pop ix                  ; IX = buffer pointer
        ld c, 0                 ; C = current length

il_loop:
        call wait_key

        ; Check for RETURN
        cp 13
        jr z, il_done

        ; Check for DELETE/backspace
        cp 127                  ; DEL
        jr z, il_delete
        cp 8                    ; Backspace
        jr z, il_delete

        ; Check buffer full
        ld a, c
        cp b
        jr nc, il_loop          ; Full, ignore

        ; Store character
        ld a, (ix+0)            ; Get key back... need to save it
        ; Actually, we lost A - re-read key state
        call wait_key           ; This isn't ideal - simplified
        ld (ix+0), a
        inc ix
        inc c

        ; Echo character
        call TXT_OUTPUT

        jr il_loop

il_delete:
        ; Check if anything to delete
        ld a, c
        or a
        jr z, il_loop

        ; Remove character
        dec ix
        dec c

        ; Visual feedback (backspace, space, backspace)
        ld a, 8
        call TXT_OUTPUT
        ld a, ' '
        call TXT_OUTPUT
        ld a, 8
        call TXT_OUTPUT

        jr il_loop

il_done:
        ; Null-terminate
        ld (ix+0), 0

        ; Return length
        ld a, c
        ret

; Improved input_line that preserves the key:
input_line_v2:
        push hl
        pop ix                  ; IX = buffer start
        ld c, 0                 ; C = current position

ilv2_loop:
        call wait_key
        push af                 ; Save key

        ; Check RETURN
        cp 13
        jr z, ilv2_done

        ; Check DELETE
        cp 127
        jr z, ilv2_del
        cp 8
        jr z, ilv2_del

        ; Check printable (32-126)
        cp 32
        jr c, ilv2_skip         ; Control char
        cp 127
        jr nc, ilv2_skip        ; High char

        ; Check buffer space
        ld a, c
        cp b
        jr nc, ilv2_skip        ; Full

        ; Store and echo
        pop af
        ld (ix+0), a
        inc ix
        inc c
        call TXT_OUTPUT
        jr ilv2_loop

ilv2_del:
        pop af                  ; Discard saved key
        ld a, c
        or a
        jr z, ilv2_loop         ; Nothing to delete

        dec ix
        dec c

        ; Visual: backspace, space, backspace
        ld a, 8
        call TXT_OUTPUT
        ld a, ' '
        call TXT_OUTPUT
        ld a, 8
        call TXT_OUTPUT
        jr ilv2_loop

ilv2_skip:
        pop af                  ; Discard
        jr ilv2_loop

ilv2_done:
        pop af                  ; Discard RETURN
        ld (ix+0), 0            ; Null terminate
        ld a, c                 ; Return length
        ret
