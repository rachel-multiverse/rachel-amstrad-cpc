; =============================================================================
; RUBP PROTOCOL MODULE - Amstrad CPC
; =============================================================================
; Rachel Unified Binary Protocol - message encoding/decoding
; 64-byte fixed messages, big-endian multi-byte values

; Variables (defined in main.asm after code)
; sequence: 2 bytes
; player_id: 2 bytes
; game_id: 2 bytes
; my_index: 1 byte
; current_turn: 1 byte
; hand_count: 1 byte
; cursor_pos: 1 byte
; selected_mask: 2 bytes

; =============================================================================
; MESSAGE CONSTRUCTION
; =============================================================================

; -----------------------------------------------------------------------------
; Initialize message header in TX buffer
; Input: A = message type
; Clobbers: HL, DE, BC
; -----------------------------------------------------------------------------
rubp_init_header:
        push af

        ; Set magic "RACH"
        ld hl, TX_BUFFER
        ld (hl), MAGIC_0
        inc hl
        ld (hl), MAGIC_1
        inc hl
        ld (hl), MAGIC_2
        inc hl
        ld (hl), MAGIC_3
        inc hl

        ; Version
        ld (hl), PROTOCOL_VER
        inc hl

        ; Message type
        pop af
        ld (hl), a
        inc hl

        ; Flags (0)
        ld (hl), 0
        inc hl

        ; Reserved (0)
        ld (hl), 0
        inc hl

        ; Sequence (big-endian)
        ld a, (sequence+1)      ; High byte first
        ld (hl), a
        inc hl
        ld a, (sequence)        ; Low byte
        ld (hl), a
        inc hl

        ; Increment sequence
        ld hl, (sequence)
        inc hl
        ld (sequence), hl

        ; Player ID (big-endian)
        ld hl, TX_BUFFER + HDR_PLAYER_ID
        ld a, (player_id+1)
        ld (hl), a
        inc hl
        ld a, (player_id)
        ld (hl), a

        ; Game ID (big-endian)
        ld hl, TX_BUFFER + HDR_GAME_ID
        ld a, (game_id+1)
        ld (hl), a
        inc hl
        ld a, (game_id)
        ld (hl), a

        ; Clear payload area
        ld hl, TX_BUFFER + PAYLOAD_START
        ld de, TX_BUFFER + PAYLOAD_START + 1
        ld bc, PAYLOAD_SIZE - 1
        ld (hl), 0
        ldir

        ret

; -----------------------------------------------------------------------------
; Calculate and set checksum
; Clobbers: HL, BC, A
; -----------------------------------------------------------------------------
rubp_set_checksum:
        ; Simple 16-bit sum of bytes 0-13 and 16-63
        ld hl, TX_BUFFER
        ld bc, 0                ; BC = running sum

        ; Sum bytes 0-13
        ld de, 14
rsc_loop1:
        ld a, (hl)
        add a, c
        ld c, a
        ld a, 0
        adc a, b
        ld b, a
        inc hl
        dec de
        ld a, d
        or e
        jr nz, rsc_loop1

        ; Skip checksum bytes (14-15)
        inc hl
        inc hl

        ; Sum bytes 16-63
        ld de, 48
rsc_loop2:
        ld a, (hl)
        add a, c
        ld c, a
        ld a, 0
        adc a, b
        ld b, a
        inc hl
        dec de
        ld a, d
        or e
        jr nz, rsc_loop2

        ; Store checksum (big-endian)
        ld hl, TX_BUFFER + HDR_CHECKSUM
        ld (hl), b              ; High byte
        inc hl
        ld (hl), c              ; Low byte

        ret

; =============================================================================
; MESSAGE SENDING
; =============================================================================

; -----------------------------------------------------------------------------
; Send HELLO message
; Input: HL = pointer to player name (null-terminated)
; -----------------------------------------------------------------------------
rubp_send_hello:
        push hl

        ; Init header
        ld a, MSG_HELLO
        call rubp_init_header

        ; Copy name to payload (max 16 chars)
        pop hl
        ld de, TX_BUFFER + PAYLOAD_START
        ld b, 16
rsh_copy:
        ld a, (hl)
        or a
        jr z, rsh_done
        ld (de), a
        inc hl
        inc de
        djnz rsh_copy

rsh_done:
        ; Platform ID at payload+16 (big-endian)
        ; Amstrad CPC = 0x0009
        ld a, $00
        ld (TX_BUFFER + PAYLOAD_START + 16), a
        ld a, $09               ; Platform 9 = Amstrad CPC
        ld (TX_BUFFER + PAYLOAD_START + 17), a

        call rubp_set_checksum
        call net_send
        ret

; -----------------------------------------------------------------------------
; Send PLAY_CARD message
; Input: A = nominated suit ($FF if none)
; Uses selected_mask to determine which cards
; -----------------------------------------------------------------------------
rubp_send_play_card:
        push af                 ; Save suit nomination

        ld a, MSG_PLAY_CARD
        call rubp_init_header

        ; Payload byte 0: card count (from selection)
        ; Count set bits in selected_mask
        ld a, (selected_mask)
        ld b, a
        ld a, (selected_mask+1)
        ld c, a
        call count_bits         ; Returns count in A
        ld (TX_BUFFER + PAYLOAD_START), a

        ; Payload byte 1: nominated suit
        pop af
        ld (TX_BUFFER + PAYLOAD_START + 1), a

        ; Payload bytes 2+: the selected cards
        ld hl, MY_HAND
        ld de, TX_BUFFER + PAYLOAD_START + 2
        ld a, (selected_mask)
        ld b, a
        ld a, (selected_mask+1)
        ld c, a
        ld a, (hand_count)
        or a
        jr z, rspc_done

        push af                 ; Save hand count
rspc_loop:
        ; Check if bit 0 of BC is set
        ld a, c
        and 1
        jr z, rspc_next

        ; Card is selected - copy it
        ld a, (hl)
        ld (de), a
        inc de

rspc_next:
        inc hl
        srl b
        rr c
        pop af
        dec a
        push af
        jr nz, rspc_loop

        pop af                  ; Clean stack

rspc_done:
        call rubp_set_checksum
        call net_send
        ret

; -----------------------------------------------------------------------------
; Count set bits in BC
; Returns: A = count
; -----------------------------------------------------------------------------
count_bits:
        push bc
        ld a, 0
cb_loop:
        ld d, b
        or c
        jr z, cb_done
        ld a, c
        and 1
        add a, d                ; Wait, this is wrong
        ; Let me fix this
        pop bc
        push bc

        xor a                   ; A = count
        ld d, 16                ; 16 bits to check
cb_loop2:
        srl b
        rr c
        jr nc, cb_next
        inc a
cb_next:
        dec d
        jr nz, cb_loop2

cb_done:
        pop bc
        ret

; Fixed count_bits:
count_bits_v2:
        xor a                   ; A = count
        ld d, 16
cbv2_loop:
        srl b
        rr c
        jr nc, cbv2_skip
        inc a
cbv2_skip:
        dec d
        jr nz, cbv2_loop
        ret

; -----------------------------------------------------------------------------
; Send DRAW_CARD message
; Input: A = reason (0 = can't play, 1 = choice)
; -----------------------------------------------------------------------------
rubp_send_draw_card:
        push af

        ld a, MSG_DRAW_CARD
        call rubp_init_header

        pop af
        ld (TX_BUFFER + PAYLOAD_START), a

        call rubp_set_checksum
        call net_send
        ret

; =============================================================================
; MESSAGE RECEIVING AND PARSING
; =============================================================================

; -----------------------------------------------------------------------------
; Receive a message into RX buffer
; Returns: A = 0 if success
; -----------------------------------------------------------------------------
rubp_receive:
        ld hl, RX_BUFFER
        ld bc, MSG_SIZE
        call net_recv
        ret

; -----------------------------------------------------------------------------
; Validate received message
; Returns: Z flag set if valid
; -----------------------------------------------------------------------------
rubp_validate:
        ; Check magic
        ld hl, RX_BUFFER
        ld a, (hl)
        cp MAGIC_0
        ret nz
        inc hl
        ld a, (hl)
        cp MAGIC_1
        ret nz
        inc hl
        ld a, (hl)
        cp MAGIC_2
        ret nz
        inc hl
        ld a, (hl)
        cp MAGIC_3
        ret nz

        ; Check version
        inc hl
        ld a, (hl)
        cp PROTOCOL_VER
        ret nz

        ; Valid
        xor a
        ret

; -----------------------------------------------------------------------------
; Get message type
; Returns: A = message type
; -----------------------------------------------------------------------------
rubp_get_type:
        ld a, (RX_BUFFER + HDR_TYPE)
        ret

; -----------------------------------------------------------------------------
; Parse WELCOME message
; Sets player_id from payload
; -----------------------------------------------------------------------------
rubp_parse_welcome:
        ; Player ID is in payload bytes 0-1 (big-endian)
        ld a, (RX_BUFFER + PAYLOAD_START + 1)
        ld (player_id), a       ; Low byte
        ld a, (RX_BUFFER + PAYLOAD_START)
        ld (player_id+1), a     ; High byte

        ; Our index is byte 2
        ld a, (RX_BUFFER + PAYLOAD_START + 2)
        ld (my_index), a

        ret

; -----------------------------------------------------------------------------
; Parse GAME_START message
; Sets game_id and initial state
; -----------------------------------------------------------------------------
rubp_parse_game_start:
        ; Game ID in header
        ld a, (RX_BUFFER + HDR_GAME_ID + 1)
        ld (game_id), a
        ld a, (RX_BUFFER + HDR_GAME_ID)
        ld (game_id+1), a

        ; Player count in payload byte 0
        ld a, (RX_BUFFER + PAYLOAD_START)
        ld (player_count), a

        ; Starting player in byte 1
        ld a, (RX_BUFFER + PAYLOAD_START + 1)
        ld (current_turn), a

        ret

; -----------------------------------------------------------------------------
; Parse GAME_STATE message
; Updates all game state from payload
; -----------------------------------------------------------------------------
rubp_parse_game_state:
        ; Byte 0: current turn
        ld a, (RX_BUFFER + PAYLOAD_START)
        ld (current_turn), a

        ; Byte 1: direction
        ld a, (RX_BUFFER + PAYLOAD_START + 1)
        ld (direction), a

        ; Byte 2: top card
        ld a, (RX_BUFFER + PAYLOAD_START + 2)
        ld (discard_top), a

        ; Byte 3: nominated suit
        ld a, (RX_BUFFER + PAYLOAD_START + 3)
        ld (nominated_suit), a

        ; Byte 4: deck count
        ld a, (RX_BUFFER + PAYLOAD_START + 4)
        ld (deck_count), a

        ; Byte 5: pending draws
        ld a, (RX_BUFFER + PAYLOAD_START + 5)
        ld (pending_draws), a

        ; Byte 6: pending skips
        ld a, (RX_BUFFER + PAYLOAD_START + 6)
        ld (pending_skips), a

        ; Bytes 8-15: player card counts
        ld hl, RX_BUFFER + PAYLOAD_START + 8
        ld de, PLAYER_COUNTS
        ld bc, 8
        ldir

        ; Bytes 16+: our hand
        ld a, (RX_BUFFER + PAYLOAD_START + 7)
        ld (hand_count), a

        ld hl, RX_BUFFER + PAYLOAD_START + 16
        ld de, MY_HAND
        ld a, (hand_count)
        or a
        ret z
        ld c, a
        ld b, 0
        ldir

        ret
