; =============================================================================
; AMSTRAD CPC MEMORY DEFINITIONS
; =============================================================================
; Buffer locations and constants for the Rachel CPC client

; =============================================================================
; PROGRAM LAYOUT
; =============================================================================

PROG_START      equ $4000           ; Standard CPC application start

; =============================================================================
; CPC FIRMWARE VECTORS
; =============================================================================

TXT_OUTPUT      equ $BB5A           ; Print character at cursor
TXT_SET_CURSOR  equ $BB75           ; Set cursor position (H=col, L=row)
TXT_GET_CURSOR  equ $BB78           ; Get cursor position
TXT_CLEAR_WIN   equ $BB6C           ; Clear text window
TXT_SET_PEN     equ $BB90           ; Set text pen colour
TXT_SET_PAPER   equ $BB96           ; Set text paper colour
KM_READ_KEY     equ $BB1B           ; Wait for key and read
KM_READ_CHAR    equ $BB09           ; Non-blocking key check
KM_WAIT_KEY     equ $BB18           ; Wait for key with cursor

; =============================================================================
; VARIABLE AREA (at end of code, tracked via labels)
; =============================================================================

; These will be placed at VAR_BASE (defined in main.asm after code)
; Connection state
CONN_DISCONNECTED   equ 0
CONN_CONNECTING     equ 1
CONN_HANDSHAKE      equ 2
CONN_WAITING        equ 3
CONN_PLAYING        equ 4

; =============================================================================
; BUFFER LOCATIONS (in high memory, below screen)
; =============================================================================
; CPC screen is at &C000-&FFFF, we use &7E00-&7FFF for buffers

BUFFER_BASE     equ $7E00

; Serial/Network buffers (128 bytes)
RX_BUFFER       equ BUFFER_BASE         ; 64-byte receive buffer
TX_BUFFER       equ BUFFER_BASE + 64    ; 64-byte transmit buffer

; Game buffers (256 bytes starting at $7F00)
GAME_BUFFERS    equ $7F00
MY_HAND         equ GAME_BUFFERS        ; 32 bytes max hand
PLAYER_COUNTS   equ GAME_BUFFERS + 32   ; 8 bytes, one per player
PLAYER_NAMES    equ GAME_BUFFERS + 40   ; 128 bytes (8 x 16)
IP_INPUT_BUF    equ GAME_BUFFERS + 168  ; 32 bytes for host:port input

; =============================================================================
; RUBP PROTOCOL CONSTANTS
; =============================================================================

; Message size
MSG_SIZE        equ 64

; Magic bytes "RACH"
MAGIC_0         equ 'R'
MAGIC_1         equ 'A'
MAGIC_2         equ 'C'
MAGIC_3         equ 'H'

; Protocol version
PROTOCOL_VER    equ $01

; Message types
MSG_HELLO       equ $01
MSG_WELCOME     equ $02
MSG_GAME_START  equ $10
MSG_GAME_STATE  equ $11
MSG_PLAY_CARD   equ $20
MSG_DRAW_CARD   equ $21
MSG_PLAYER_OUT  equ $30
MSG_GAME_OVER   equ $31
MSG_ERROR       equ $FF

; Header offsets (0-15)
HDR_MAGIC       equ 0               ; 4 bytes
HDR_VERSION     equ 4               ; 1 byte
HDR_TYPE        equ 5               ; 1 byte
HDR_FLAGS       equ 6               ; 1 byte
HDR_RESERVED    equ 7               ; 1 byte
HDR_SEQ         equ 8               ; 2 bytes (big-endian)
HDR_PLAYER_ID   equ 10              ; 2 bytes (big-endian)
HDR_GAME_ID     equ 12              ; 2 bytes (big-endian)
HDR_CHECKSUM    equ 14              ; 2 bytes (big-endian)
HDR_SIZE        equ 16

; Payload offsets (16-63)
PAYLOAD_START   equ 16
PAYLOAD_SIZE    equ 48

; Card encoding
; Bits 0-3: Rank (2-14, where 14=Ace)
; Bits 4-5: Suit (0=Hearts, 1=Diamonds, 2=Clubs, 3=Spades)
; Bit 6: Face up (1) or face down (0)
; Bit 7: Selected flag

SUIT_HEARTS     equ 0
SUIT_DIAMONDS   equ 1
SUIT_CLUBS      equ 2
SUIT_SPADES     equ 3

; =============================================================================
; SCREEN LAYOUT CONSTANTS
; =============================================================================

SCREEN_WIDTH    equ 40
SCREEN_HEIGHT   equ 25              ; CPC has 25 rows in Mode 1

; Row assignments
ROW_TITLE       equ 0
ROW_BORDER1     equ 1
ROW_PLAYERS     equ 2               ; 2 rows for player list
ROW_BORDER2     equ 4
ROW_DISCARD     equ 5               ; 5 rows for discard area
ROW_BORDER3     equ 10
ROW_HAND_LABEL  equ 11
ROW_HAND        equ 12              ; 6 rows for hand display
ROW_BORDER4     equ 18
ROW_CONTROLS    equ 19
ROW_BORDER5     equ 20
ROW_STATUS      equ 21              ; 2 rows for status/input
