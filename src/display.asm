; =============================================================================
; AMSTRAD CPC DISPLAY MODULE
; =============================================================================
; Screen routines using CPC firmware calls

; =============================================================================
; INITIALIZATION
; =============================================================================

; -----------------------------------------------------------------------------
; Initialize display
; Sets Mode 1 (40x25, 4 colours), clears screen
; -----------------------------------------------------------------------------
display_init:
        ; Set Mode 1 (medium resolution, 40 columns)
        ld a, 1
        call $BC0E              ; SCR_SET_MODE

        ; Clear screen
        call TXT_CLEAR_WIN

        ; Set pen colour to white
        ld a, 1                 ; Pen 1 = bright white
        call TXT_SET_PEN

        ; Set paper to blue
        ld a, 1                 ; Ink 1 for paper (will be blue)
        xor a                   ; Paper 0 = black background
        call TXT_SET_PAPER

        ret

; =============================================================================
; CURSOR AND BASIC OUTPUT
; =============================================================================

; -----------------------------------------------------------------------------
; Set cursor position
; Input: B = row (1-25), C = column (1-40)
; Note: CPC firmware uses 1-based coordinates
; -----------------------------------------------------------------------------
set_cursor:
        ld h, c                 ; H = column
        ld l, b                 ; L = row
        call TXT_SET_CURSOR
        ret

; -----------------------------------------------------------------------------
; Print single character
; Input: A = character
; -----------------------------------------------------------------------------
print_char:
        call TXT_OUTPUT
        ret

; -----------------------------------------------------------------------------
; Print null-terminated string
; Input: HL = pointer to string
; -----------------------------------------------------------------------------
print_string:
ps_loop:
        ld a, (hl)
        or a
        ret z
        call TXT_OUTPUT
        inc hl
        jr ps_loop

; -----------------------------------------------------------------------------
; Print decimal number (0-255)
; Input: A = number to print
; -----------------------------------------------------------------------------
print_number:
        ld c, 0                 ; Leading zero flag

        ; Hundreds
        ld b, 100
        call pn_digit

        ; Tens
        ld b, 10
        call pn_digit

        ; Units (always print)
        add a, '0'
        call TXT_OUTPUT
        ret

pn_digit:
        ld d, 0
pn_count:
        cp b
        jr c, pn_print
        sub b
        inc d
        jr pn_count

pn_print:
        push af
        ld a, d
        or c                    ; Check if we've printed anything
        jr z, pn_skip           ; Skip leading zeros
        ld c, 1                 ; Set flag
        ld a, d
        add a, '0'
        call TXT_OUTPUT
pn_skip:
        pop af
        ret

; =============================================================================
; SCREEN LAYOUT
; =============================================================================

; -----------------------------------------------------------------------------
; Clear a screen row
; Input: B = row (1-25)
; -----------------------------------------------------------------------------
clear_row:
        ld c, 1                 ; Column 1
        call set_cursor
        ld b, 40
cr_loop:
        ld a, ' '
        call TXT_OUTPUT
        djnz cr_loop
        ret

; -----------------------------------------------------------------------------
; Draw horizontal border line
; Input: B = row (1-25)
; -----------------------------------------------------------------------------
draw_border:
        ld c, 1
        call set_cursor
        ld b, 40
db_loop:
        ld a, '-'
        call TXT_OUTPUT
        djnz db_loop
        ret

; =============================================================================
; UDG FOR CARD SUITS (using CPC character definitions)
; =============================================================================

; CPC allows redefining characters 240-255
; We'll use standard ASCII approximations for suits:
; Hearts = 'H' or CHR$(3)
; Diamonds = 'D' or CHR$(4)
; Clubs = 'C' or CHR$(5)
; Spades = 'S' or CHR$(6)

; For simplicity, use letters:
CHAR_HEART      equ 'H'
CHAR_DIAMOND    equ 'D'
CHAR_CLUB       equ 'C'
CHAR_SPADE      equ 'S'

; -----------------------------------------------------------------------------
; Print suit character
; Input: A = suit (0-3)
; -----------------------------------------------------------------------------
print_suit:
        and 3
        ld hl, suit_chars
        add a, l
        ld l, a
        ld a, 0
        adc a, h
        ld h, a
        ld a, (hl)
        call TXT_OUTPUT
        ret

suit_chars:
        defb CHAR_HEART, CHAR_DIAMOND, CHAR_CLUB, CHAR_SPADE

; -----------------------------------------------------------------------------
; Print rank (2-10, J, Q, K, A)
; Input: A = rank (2-14)
; -----------------------------------------------------------------------------
print_rank:
        cp 10
        jr c, pr_number         ; 2-9

        cp 10
        jr z, pr_ten
        cp 11
        jr z, pr_jack
        cp 12
        jr z, pr_queen
        cp 13
        jr z, pr_king
        ; Must be 14 (Ace)
        ld a, 'A'
        jr pr_out

pr_ten:
        ld a, '1'
        call TXT_OUTPUT
        ld a, '0'
        jr pr_out

pr_number:
        add a, '0'
pr_out:
        call TXT_OUTPUT
        ret

pr_jack:
        ld a, 'J'
        jr pr_out
pr_queen:
        ld a, 'Q'
        jr pr_out
pr_king:
        ld a, 'K'
        jr pr_out

; -----------------------------------------------------------------------------
; Print a card (rank + suit)
; Input: A = card encoding
; Format: RS where R=rank (2-14), S=suit (0-3)
; -----------------------------------------------------------------------------
print_card:
        push af
        and $0F                 ; Get rank
        call print_rank
        pop af
        srl a
        srl a
        srl a
        srl a
        and $03                 ; Get suit
        call print_suit
        ld a, ' '               ; Space after card
        call TXT_OUTPUT
        ret
