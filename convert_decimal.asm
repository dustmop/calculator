.segment "ZEROPAGE" : zeropage

remainder_mod8: .byte 0


.segment "CODE"

.export ConvertDecimal


;ConvertDecimal
; Given a number in A, convert it to three decimal digits, in Y, X, A.
;  .reg:a @in  The number to convert.
;  .reg:a @out The ones digit, 0-9.
;  .reg:x @out The tens digit, 0-9.
;  .reg:y @out The hundreds digit, 0-2.
.proc ConvertDecimal
  ldy #$00
HundredsPlace:
  ; Unrolled loop to get the number in A less than 100.
  cmp #100
  bcc LessThanOneHundred
  sbc #100
  iny
  cmp #100
  bcc LessThanOneHundred
  sbc #100
  iny
LessThanOneHundred:
  ; Number in A is less than 100, let us call this value N.
  ; Save N to X, then divide by 8 and store the remainder.
  tax
  and #$07
  sta remainder_mod8
  ; Load N from X, divide it by 8 to get a partial quotient, and save it in X.
  txa
  lsr a
  lsr a
  lsr a
  tax
  ; Multiply by 2, negate that result.
  asl a
  eor #$ff
  ; Set the carry flag to get the two's complement.
  sec
  adc remainder_mod8
  bpl Done
CorrectPartial:
  ; Almost done, A + X * 10 = N, but A is negative. Unrolled loop to fix this.
  dex
  adc #$0a
  bpl Done
  dex
  adc #$0a
  bpl Done
  dex
  adc #$0a
Done:
  ; Done. A + X * 10 = N. A + X * 10 + Y * 100 = original input.
  rts
.endproc
