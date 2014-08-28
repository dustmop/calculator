;;;;;;;;;;;;;;; ROM Header.


.segment "INESHDR"
  .byte "NES", $1a
  .byte 1
  .byte 1
  .byte $00
  .byte $00


;;;;;;;;;;;;;;; Included files and functions to link in.


.include "system_constants.asm"
.include "system_memory_map.asm"

.import ConvertDecimal


;;;;;;;;;;;;;;; Zeropage variables.


.segment "ZEROPAGE" : zeropage
  .org 0

main_loop_ready: .byte 0

; Controller state.
buttons: .byte 0
last_buttons: .byte 0
pressed_buttons: .byte 0

; The two input numbers, and their sum.
number_1: .byte 0
number_2: .byte 0
sum: .byte 0

; The numbers and sum as displayable tiles.
number_1_display: .byte 0, 0, 0
number_2_display: .byte 0, 0, 0
sum_display:      .byte 0, 0, 0

; Amount to change a number by.
delta_value: .byte 0

; The cursor's position and current animation step.
cursor_y: .byte 0
cursor_x: .byte 0
cursor_animate: .byte 0

; Constants for where the cursor is allowed to exist.
CURSOR_MAX_X = 3
CURSOR_MAX_Y = 2


;;;;;;;;;;;;;; Graphical data to load into the ppu.


.segment "CODE"

.org $8000

palette:
  .byte $0f,$30,$16,$07, $0f,$30,$00,$00, $0f,$0f,$0f,$0f, $0f,$0f,$0f,$0f
  .byte $0f,$30,$30,$30, $0f,$0f,$0f,$0f, $0f,$0f,$0f,$0f, $0f,$0f,$0f,$0f

graphics:
  .incbin "graphics.dat"


;;;;;;;;;;;;;; Macros.


;LoadControllerInitialize
; Get ready to read controllers.
.macro LoadControllerInitialize
  lda #1
  sta input_port_1
  lda #0
  sta input_port_1
.endmacro

;LoadControllerButtons
; Read 8 button states and store them in the given variable.
.macro LoadControllerButtons port, button_storage
  .local Loop
  ldx #8
Loop:
  lda port
  lsr A
  rol button_storage
  dex
  bne Loop
.endmacro

;LoadPalette
; Load 8 palettes into the ppu.
.macro LoadPalette palette_data
  .local Loop
  lda ppu_status
  lda #$3f
  sta ppu_pointer
  lda #0
  sta ppu_pointer
  ldx #0
Loop:
  lda palette_data,x
  sta ppu_data_port
  inx
  cpx #$20
  bne Loop
.endmacro

;LoadVramInitialize
; Set the ppu address to the start of the first nametable.
.macro LoadVramInitialize
  lda #$20
  ldx #$00
  sta ppu_pointer
  stx ppu_pointer
.endmacro

;LoadVramGraphics
; Fill an entire graphics page (1024 bytes) at the current ppu address.
.macro LoadVramGraphics graphics_data
.repeat 4, i
:
  lda graphics_data+($100 * i),x
  sta ppu_data_port
  inx
  bne :-
.endrepeat
.endmacro

;UpdateGraphicTiles
; Set the 3 tiles in the buffer at the given tile location.
.macro UpdateGraphicTiles y_tile, x_tile, tile_buffer
  .local offset
  offset = y_tile * 32 + x_tile
  lda ppu_status
  lda #($20 + offset / 256)
  sta ppu_pointer
  lda #(offset .mod 256)
  sta ppu_pointer
.repeat 3, i
  lda tile_buffer+i
  sta ppu_data_port
.endrepeat
.endmacro


;;;;;;;;;;;;;; Initialization code and main loop.


RESET:
  sei
  cld
  ldx #$40
  stx apu_frame_counter
  ldx #$ff
  txs
  inx;#$00
  stx ppu_reg1
  stx ppu_reg2
  stx $4010
  stx $4015

  jsr VblankWait

.scope ClearMemory
  ldx #$00
Loop:
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  lda #$ff
  sta $0200, x
  inx
  bne Loop
.endscope

  jsr VblankWait

MainScene:
.scope MainInitialize
  LoadPalette palette
  LoadVramInitialize
  LoadVramGraphics graphics
  LoadVramGraphics graphics
.endscope

  ; Initialize numbers.
  lda #0
  sta number_1
  sta number_2
  sta sum
  ; Initialize cursor.
  lda #0
  sta cursor_y
  lda #0
  sta cursor_x

  jsr DrawCursorSprite

  ; Wait until vblank to enable graphics and enter the main loop.
  jsr VblankWait
  jsr EnableGraphics
  lda #0
  sta main_loop_ready

MainLoop:
  lda main_loop_ready
  beq MainLoop

  lda #0
  sta main_loop_ready

  ; Advance the animation count for the cursor.
.scope AnimationAdvance
  inc cursor_animate
  lda cursor_animate
  cmp #80
  bne Done
  lda #0
  sta cursor_animate
Done:
.endscope

  ; Controler processing.
  LoadControllerInitialize
  LoadControllerButtons input_port_1, buttons
  ; Find buttons that weren't pressed, but got pressed this frame.
  lda last_buttons
  eor #$ff
  and buttons
  sta pressed_buttons
  ; Got pressed buttons.
  lda buttons
  sta last_buttons

  ; Up moves the cursor up.
.scope HandleControllerUp
  lda pressed_buttons
  and #CONTROLLER_BUTTON_UP
  beq Done
  dec cursor_y
  bpl Done
  lda #(CURSOR_MAX_Y - 1)
  sta cursor_y
Done:
.endscope

  ; Down moves the cursor down.
.scope HandleControllerDown
  lda pressed_buttons
  and #CONTROLLER_BUTTON_DOWN
  beq Done
  inc cursor_y
  lda cursor_y
  cmp #CURSOR_MAX_Y
  bne Done
  lda #0
  sta cursor_y
Done:
.endscope

  ; Left moves the cursor left.
.scope HandleControllerLeft
  lda pressed_buttons
  and #CONTROLLER_BUTTON_LEFT
  beq Done
  dec cursor_x
  bpl Done
  lda #(CURSOR_MAX_X - 1)
  sta cursor_x
Done:
.endscope

  ; Right moves the cursor right.
.scope HandleControllerRight
  lda pressed_buttons
  and #CONTROLLER_BUTTON_RIGHT
  beq Done
  inc cursor_x
  lda cursor_x
  cmp #CURSOR_MAX_X
  bne Done
  lda #0
  sta cursor_x
Done:
.endscope

  jsr DrawCursorSprite

  ; Amount to increase or decrease the currently selected number.
  lda #0
  sta delta_value

  ; A increase the current digit.
.scope HandleControllerA
  lda pressed_buttons
  and #CONTROLLER_BUTTON_A
  beq Done
  lda cursor_x
  beq HundredsPlace
  cmp #1
  beq TensPlace
OnesPlace:
  lda #1
  sta delta_value
  jmp Done
TensPlace:
  lda #10
  sta delta_value
  jmp Done
HundredsPlace:
  lda #100
  sta delta_value
Done:
.endscope

  ; B decreases the current digit.
.scope HandleControllerB
  lda pressed_buttons
  and #CONTROLLER_BUTTON_B
  beq Done
  lda cursor_x
  beq HundredsPlace
  cmp #1
  beq TensPlace
OnesPlace:
  lda #(256 - 1)
  sta delta_value
  jmp Done
TensPlace:
  lda #(256 - 10)
  sta delta_value
  jmp Done
HundredsPlace:
  lda #(256 - 100)
  sta delta_value
Done:
.endscope

  ; If necessary, modify the currently selected number.
.scope ApplyDelta
  lda delta_value
  beq Done
  lda cursor_y
  beq NumberFirst
  jmp NumberSecond
NumberFirst:
  lda number_1
  clc
  adc delta_value
  sta number_1
  jmp Done
NumberSecond:
  lda number_2
  clc
  adc delta_value
  sta number_2
Done:
.endscope

  ; Start adds numbers.
.scope HandleControllerStart
  lda pressed_buttons
  and #CONTROLLER_BUTTON_START
  beq Done
  lda number_1
  clc
  adc number_2
  sta sum
Done:
.endscope

  ; Convert numbers to displayable tiles.
  lda number_1
  jsr ConvertDecimal
  sty number_1_display+0
  stx number_1_display+1
  sta number_1_display+2

  lda number_2
  jsr ConvertDecimal
  sty number_2_display+0
  stx number_2_display+1
  sta number_2_display+2

  lda sum
  jsr ConvertDecimal
  sty sum_display+0
  stx sum_display+1
  sta sum_display+2

  ; Main loop done.
  jmp MainLoop


;;;;;;;;;;;;;; Subroutines.


;VblankWait
; Wait until vblank happens, do we can update the ppu.
.proc VblankWait
Loop:
  bit ppu_status
  bpl Loop
  rts
.endproc


;EnableGraphics
; Enable rendering graphics.
.proc EnableGraphics
  cli
  lda #(PPU_REG1_VBLANK_NMI | PPU_REG1_SPRITE_AT_1000)
  sta ppu_reg1
  lda #(PPU_REG2_SHOW_SPRITES | PPU_REG2_SHOW_BG | PPU_REG2_NOCLIP_SPRITES | PPU_REG2_NOCLIP_BG)
  sta ppu_reg2
  lda #0
  sta ppu_scroll
  sta ppu_scroll
  rts
.endproc


;DisableGraphics
; Disable rendering graphics.
.proc DisableGraphics
  sei
  lda #0
  sta ppu_reg1
  sta ppu_reg2
  rts
.endproc


;DrawCursorSprite
; Set the cursor position and animation frame.
.proc DrawCursorSprite
  lda cursor_y
  asl A
  asl A
  asl A
  asl A
  clc
  adc #($40 - 1)
  sta $200
.scope Animation
  lda cursor_animate
  cmp #60
  bcc Frame1
  jmp Frame2
Frame1:
  lda #0
  sta $201
  jmp Done
Frame2:
  lda #1
  sta $201
Done:
.endscope
  lda #0
  sta $202
  lda cursor_x
  asl A
  asl A
  asl A
  clc
  adc #$60
  sta $203
  rts
.endproc


;;;;;;;;;;;;;; Interrupt called during vblank.


NMI:
  pha
  txa
  pha
  tya
  pha

  ; DMA transfer
  lda #0
  sta ppu_oam
  lda #2
  sta cpu_dma

  ; Yield to MainLoop.
  lda #1
  sta main_loop_ready

  ; Draw numbers to the nametable.
  UpdateGraphicTiles  8, 12, number_1_display
  UpdateGraphicTiles 10, 12, number_2_display
  UpdateGraphicTiles 12, 12, sum_display

PpuCleanUp:
  lda #(PPU_REG1_VBLANK_NMI | PPU_REG1_SPRITE_AT_1000)
  sta ppu_reg1
  lda #(PPU_REG2_SHOW_SPRITES | PPU_REG2_SHOW_BG | PPU_REG2_NOCLIP_SPRITES | PPU_REG2_NOCLIP_BG)
  sta ppu_reg2
  lda #0
  sta ppu_scroll
  sta ppu_scroll

DoneNmi:
  pla
  tay
  pla
  tax
  pla
  rti


;;;;;;;;;;;;;; Vectors for interrupts.


.segment "VECTORS"
  .word NMI
  .word RESET
  .word 0

