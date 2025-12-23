; =============================================================================
; GAME MODULE - Amstrad CPC
; =============================================================================
; Game display and state rendering

; =============================================================================
; GAME SCREEN DRAWING
; =============================================================================

; -----------------------------------------------------------------------------
; Draw the complete game screen
; -----------------------------------------------------------------------------
draw_game_screen:
        call display_init

        ; Title row
        ld b, 1                 ; Row 1 (CPC uses 1-based)
        ld c, 14                ; Center column
        call set_cursor
        ld hl, txt_title
        call print_string

        ; Draw borders
        ld b, 2
        call draw_border

        ld b, 5
        call draw_border

        ld b, 11
        call draw_border

        ld b, 19
        call draw_border

        ld b, 21
        call draw_border

        ; Hand label
        ld b, 12
        ld c, 2
        call set_cursor
        ld hl, txt_your_hand
        call print_string

        ; Controls
        ld b, 20
        ld c, 2
        call set_cursor
        ld hl, txt_controls
        call print_string

        ret

txt_title:
        defb "RACHEL V1.0", 0

txt_your_hand:
        defb "YOUR HAND:", 0

txt_controls:
        defb "O/P=MOVE  SPACE=SELECT  ENTER=PLAY  D=DRAW", 0

; -----------------------------------------------------------------------------
; Full game redraw (all dynamic elements)
; -----------------------------------------------------------------------------
redraw_game:
        call draw_players
        call draw_discard
        call draw_hand
        call draw_turn_indicator
        ret

; =============================================================================
; PLAYER LIST
; =============================================================================

; -----------------------------------------------------------------------------
; Draw player list (row 3-4)
; Shows: P1:nn  P2:nn  P3:nn  P4:nn (4 per row)
; -----------------------------------------------------------------------------
draw_players:
        ; Row 3 - players 0-3
        ld b, 3
        ld c, 1
        call set_cursor

        ld a, 0
dp_loop1:
        push af
        call draw_one_player
        pop af
        inc a
        cp 4
        jr c, dp_loop1

        ; Row 4 - players 4-7
        ld b, 4
        ld c, 1
        call set_cursor

        ld a, 4
dp_loop2:
        push af
        call draw_one_player
        pop af
        inc a
        cp 8
        jr c, dp_loop2

        ret

; -----------------------------------------------------------------------------
; Draw one player entry
; Input: A = player index
; -----------------------------------------------------------------------------
draw_one_player:
        push af

        ; Print "Pn:"
        ld a, 'P'
        call print_char
        pop af
        push af
        add a, '1'              ; 1-based for display
        call print_char
        ld a, ':'
        call print_char

        ; Get card count
        pop af
        ld hl, PLAYER_COUNTS
        add a, l
        ld l, a
        ld a, 0
        adc a, h
        ld h, a
        ld a, (hl)

        ; Print count (2 digits)
        call print_number_2d

        ; Space padding
        ld a, ' '
        call print_char
        ld a, ' '
        call print_char

        ret

; -----------------------------------------------------------------------------
; Print 2-digit number (0-99)
; Input: A = number
; -----------------------------------------------------------------------------
print_number_2d:
        ld b, 0                 ; Tens counter
pn2d_tens:
        cp 10
        jr c, pn2d_print
        sub 10
        inc b
        jr pn2d_tens

pn2d_print:
        push af
        ld a, b
        add a, '0'
        call print_char
        pop af
        add a, '0'
        call print_char
        ret

; =============================================================================
; DISCARD PILE
; =============================================================================

; -----------------------------------------------------------------------------
; Draw discard pile area (rows 6-10)
; -----------------------------------------------------------------------------
draw_discard:
        ; Center position
        ld b, 7
        ld c, 15
        call set_cursor

        ld hl, txt_discard
        call print_string

        ; Show top card
        ld b, 8
        ld c, 17
        call set_cursor

        ld a, (discard_top)
        or a
        jr z, dd_empty
        call print_card
        jr dd_suit

dd_empty:
        ld hl, txt_empty
        call print_string
        ret

dd_suit:
        ; Show nominated suit if any
        ld a, (nominated_suit)
        cp $FF
        ret z                   ; No nomination

        ld b, 9
        ld c, 15
        call set_cursor
        ld hl, txt_suit_is
        call print_string

        ld a, (nominated_suit)
        call print_suit_name
        ret

txt_discard:
        defb "DISCARD:", 0

txt_empty:
        defb "[EMPTY]", 0

txt_suit_is:
        defb "SUIT: ", 0

; -----------------------------------------------------------------------------
; Print suit name
; Input: A = suit (0-3)
; -----------------------------------------------------------------------------
print_suit_name:
        and 3
        ld hl, suit_names
        ld b, a
        inc b
psn_find:
        dec b
        jr z, psn_print
psn_skip:
        ld a, (hl)
        inc hl
        or a
        jr nz, psn_skip
        jr psn_find

psn_print:
        call print_string
        ret

suit_names:
        defb "HEARTS", 0
        defb "DIAMONDS", 0
        defb "CLUBS", 0
        defb "SPADES", 0

; =============================================================================
; HAND DISPLAY
; =============================================================================

; -----------------------------------------------------------------------------
; Draw player's hand (rows 13-17)
; Shows up to 6 cards per row, with cursor and selection
; -----------------------------------------------------------------------------
draw_hand:
        ld a, (hand_count)
        or a
        jr z, dh_empty

        ; Draw cards
        ld b, 13                ; Starting row
        ld c, 2                 ; Starting column
        call set_cursor

        ld de, MY_HAND
        ld a, (hand_count)
        ld (temp1), a           ; Card counter
        xor a
        ld (temp2), a           ; Position counter

dh_loop:
        ; Check if selected
        ld a, (temp2)
        call check_selected
        jr z, dh_not_sel

        ; Selected - show bracket
        ld a, '['
        call print_char
        jr dh_card

dh_not_sel:
        ; Check cursor
        ld a, (temp2)
        ld hl, cursor_pos
        cp (hl)
        jr nz, dh_no_cursor

        ; Cursor - show >
        ld a, '>'
        call print_char
        jr dh_card

dh_no_cursor:
        ld a, ' '
        call print_char

dh_card:
        ; Print card
        ld a, (de)
        call print_card

        ; Close bracket if selected
        ld a, (temp2)
        call check_selected
        jr z, dh_no_close
        ld a, ']'
        call print_char
        jr dh_space
dh_no_close:
        ld a, ' '
        call print_char

dh_space:
        inc de
        ld hl, temp2
        inc (hl)

        ; Check for newline (every 6 cards)
        ld a, (temp2)
        and 7
        cp 6
        jr nz, dh_no_newline

        ; Newline
        push de
        ld a, (temp2)
        srl a
        srl a
        srl a                   ; Divide by 8
        add a, 13               ; Base row
        ld b, a
        ld c, 2
        call set_cursor
        pop de

dh_no_newline:
        ld hl, temp1
        dec (hl)
        jr nz, dh_loop

        ret

dh_empty:
        ld b, 13
        ld c, 2
        call set_cursor
        ld hl, txt_no_cards
        call print_string
        ret

txt_no_cards:
        defb "(NO CARDS)", 0

; -----------------------------------------------------------------------------
; Check if card at position is selected
; Input: A = position (0-15)
; Returns: Z flag clear if selected
; -----------------------------------------------------------------------------
check_selected:
        cp 8
        jr nc, cs_high

        ; Check low byte
        ld b, a
        ld a, (selected_mask)
        jr cs_check

cs_high:
        sub 8
        ld b, a
        ld a, (selected_mask+1)

cs_check:
        ; Shift right B times
cs_shift:
        dec b
        jp m, cs_test
        srl a
        jr cs_shift

cs_test:
        and 1
        ret

; =============================================================================
; TURN INDICATOR
; =============================================================================

; -----------------------------------------------------------------------------
; Draw whose turn it is
; -----------------------------------------------------------------------------
draw_turn_indicator:
        ld b, 22
        ld c, 1
        call set_cursor

        ; Clear line first
        ld b, 38
dti_clear:
        ld a, ' '
        call print_char
        djnz dti_clear

        ld b, 22
        ld c, 1
        call set_cursor

        ; Check if our turn
        ld a, (current_turn)
        ld hl, my_index
        cp (hl)
        jr nz, dti_other

        ld hl, txt_your_turn
        call print_string
        ret

dti_other:
        ld hl, txt_player
        call print_string
        ld a, (current_turn)
        add a, '1'
        call print_char
        ld hl, txt_turn
        call print_string
        ret

txt_your_turn:
        defb ">>> YOUR TURN <<<", 0

txt_player:
        defb "PLAYER ", 0

txt_turn:
        defb "'S TURN", 0

; =============================================================================
; TEMPORARY VARIABLES
; =============================================================================

temp1:  defb 0
temp2:  defb 0
