; =============================================================================
; M4 BOARD NETWORK DRIVER
; =============================================================================
; TCP socket API for the M4 Board Amstrad CPC network expansion
;
; The M4 Board provides a REST-like API accessed via RST 7 calls
; See: https://www.spinpoint.org/m4/tcp.html

; M4 Board RST codes
M4_RST          equ $38             ; RST 7

; M4 TCP Function codes (passed in A)
M4_TCP_OPEN     equ $01             ; Open TCP connection
M4_TCP_CLOSE    equ $02             ; Close connection
M4_TCP_SEND     equ $03             ; Send data
M4_TCP_RECV     equ $04             ; Receive data
M4_TCP_STATUS   equ $05             ; Get connection status

; Socket handle storage
socket_handle:  defb 0

; =============================================================================
; NETWORK DRIVER INTERFACE
; =============================================================================

; -----------------------------------------------------------------------------
; Initialize network hardware
; Returns: A = 0 if OK
; -----------------------------------------------------------------------------
net_init:
        ; M4 Board initializes automatically
        ; Just clear socket handle
        xor a
        ld (socket_handle), a
        ret

; -----------------------------------------------------------------------------
; Connect to host:port
; Input: HL = pointer to "host:port" string
; Returns: A = 0 if connected
; -----------------------------------------------------------------------------
net_connect:
        ; For M4 Board, we need to format as TCP URL
        ; The M4 expects: "tcp://host:port"

        ; Store string pointer
        ld (nc_host_ptr), hl

        ; Call M4 TCP OPEN
        ld a, M4_TCP_OPEN
        ; DE = pointer to host string
        ; BC = pointer to port string (or combined)
        ld de, (nc_host_ptr)

        ; Make RST 7 call
        rst M4_RST

        ; Check result (typically carry = error)
        jr c, nc_error

        ; Store socket handle (returned in A)
        ld (socket_handle), a

        xor a                   ; Success
        ret

nc_error:
        ld a, 1
        ret

nc_host_ptr:    defw 0

; -----------------------------------------------------------------------------
; Send data
; Input: HL = buffer, BC = length
; Returns: A = 0 if OK
; -----------------------------------------------------------------------------
net_send:
        push hl
        push bc

        ; Get socket handle
        ld a, (socket_handle)
        ld e, a

        pop bc                  ; Length
        pop hl                  ; Buffer (source)
        ex de, hl               ; DE = source buffer
        ld h, e                 ; H = socket handle

        ; Call M4 TCP SEND
        ld a, M4_TCP_SEND
        ; H = socket, DE = buffer, BC = length
        rst M4_RST

        jr c, ns_error

        xor a
        ret

ns_error:
        ld a, 1
        ret

; -----------------------------------------------------------------------------
; Receive data
; Input: HL = buffer, BC = length
; Returns: A = 0 if OK, actual bytes in BC
; -----------------------------------------------------------------------------
net_recv:
        push hl
        push bc

        ; Get socket handle
        ld a, (socket_handle)
        ld e, a

        pop bc                  ; Max length
        pop de                  ; Buffer (destination)
        ld h, e                 ; H = socket handle

        ; Wait for data with timeout
        ; (In real implementation, would poll status first)

        ; Call M4 TCP RECV
        ld a, M4_TCP_RECV
        ; H = socket, DE = buffer, BC = max length
        rst M4_RST

        jr c, nr_error

        ; BC now contains actual bytes received
        xor a
        ret

nr_error:
        ld a, 1
        ret

; -----------------------------------------------------------------------------
; Close connection
; -----------------------------------------------------------------------------
net_close:
        ld a, (socket_handle)
        ld h, a

        ld a, M4_TCP_CLOSE
        rst M4_RST

        xor a
        ld (socket_handle), a
        ret

; -----------------------------------------------------------------------------
; Check if data available (non-blocking)
; Returns: A = number of bytes available (0 if none)
; -----------------------------------------------------------------------------
net_available:
        ld a, (socket_handle)
        or a
        ret z                   ; No socket

        ld h, a
        ld a, M4_TCP_STATUS
        rst M4_RST

        ; Status returned in A (bytes available or error)
        jr c, na_error
        ret

na_error:
        xor a
        ret
