# Rachel Amstrad CPC

A render-only client for the Rachel card game, written in Z80 assembly for the Amstrad CPC.

## Hardware Targets

- **M4 Board** - TCP/IP network expansion for Amstrad CPC

## Requirements

- [Pasmo](http://pasmo.speccy.org/) or [PasmoNext](https://github.com/Ckirby101/pasmoNext) cross-assembler
- [WinAPE](http://www.winape.net/) or [CPCEC](http://cpcec.sourceforge.net/) for emulation

## Building

```bash
make        # Build rachel-cpc.bin
make clean  # Remove build artifacts
```

## Output Files

- `build/rachel-cpc.bin` - Amstrad CPC executable (loads at &4000)

## Project Structure

```
src/
├── main.asm        # Entry point, initialization, main loop
├── display.asm     # Screen routines using CPC firmware
├── input.asm       # Keyboard handling via firmware
├── rubp.asm        # 64-byte RUBP protocol
├── game.asm        # Card and game state display
├── connect.asm     # Connection flow
├── buffers.asm     # Memory definitions
└── net/
    └── m4board.asm # M4 Board TCP socket API
```

## Protocol

Uses RUBP (Rachel Unified Binary Protocol) - 64-byte fixed messages over TCP. Same protocol as the ZX Spectrum and C64 clients.

## CPC Firmware Calls

- **TXT_OUTPUT** (&BB5A) - Print character
- **TXT_SET_CURSOR** (&BB75) - Position cursor
- **KM_READ_KEY** (&BB1B) - Wait for key press
- **KM_READ_CHAR** (&BB09) - Non-blocking key check

## Testing

- **WinAPE** - Full-featured Amstrad CPC emulator (Windows)
- **CPCEC** - Cross-platform emulator
- **Real hardware** - Load via M4 Board or disc

## License

MIT
