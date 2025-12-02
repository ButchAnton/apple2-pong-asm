; Pong for Apple II
; Written for Merlin32
; Copyright 2025 by Butch Anton
; Simple two-player Pong game using text graphics
; Player 1 controls: 'A' (up), 'Z' (down)
; Player 2 controls: 'K' (up), 'M' (down)

; ==============================================================================
; Constants and Hardware Addresses
; ==============================================================================
KBD                     =   $C000                   ; Keyboard data
KBDSTRB                 =   $C010                   ; Keyboard strobe (clear key)
SPKR                    =   $C030                   ; Speaker (click)
TEXT                    =   $C050                   ; Set Text mode
MIXED                   =   $C053                   ; Set Mixed mode (Text + Graphics)
PAGE1                   =   $C054                   ; Set Page 1
HIRES                   =   $C057                   ; Set Hi-Res mode
LORES                   =   $C056                   ; Set Lo-Res mode

; Monitor Routines
HOME                    =   $FC58                   ; Clear screen
GR                      =   $F3E2                   ; Set GR mode, clear screen, set window to 40x40
COLOR                   =   $F864                   ; Set GR color (color in A)
PLOT                    =   $F800                   ; Plot point at (Y, A) -> (col, row)
VLINE                   =   $F828                   ; Draw vertical line
COUT                    =   $FDED                   ; Output character in A

; Colors
BLACK                   =   $00
MAGENTA                 =   $01
DKBLUE                  =   $02
PURPLE                  =   $03
DKGREEN                 =   $04
GREY1                   =   $05
MEDBLUE                 =   $06
LTBLUE                  =   $07
BROWN                   =   $08
ORANGE                  =   $09
GREY2                   =   $0A
PINK                    =   $0B
GREEN                   =   $0C
YELLOW                  =   $0D
AQUA                    =   $0E
WHITE                   =   $0F

; Game Constants
SPACE                   =   $A0                     ; ASCII Space
NUM_COLS                =   40                      ; Number of columns in GR window
TOP_ROW                 =   0                       ; Top row
BOTTOM_ROW              =   39                      ; Bottom row
LEFT_WALL               =   0                       ; Left wall X position
RIGHT_WALL              =   39                      ; Right wall X position
PADDLE_H                =   6                       ; Paddle height
WIN_W                   =   40                      ; Window width
WIN_H                   =   40                      ; Window height
P1_X                    =   2                       ; Player 1 X position
P2_X                    =   37                      ; Player 2 X position
INITIAL_BALL_XY         =   20                      ; Initial Ball X and Y position
INITIAL_BALL_VELX       =   1                       ; Initial Ball X velocity
INITIAL_BALL_VELY       =   $FF                     ; Initial Ball Y velocity
INITIAL_SCORE           =   0                       ; Initial Score
SCORE_DISPLAY_ROW       =   21                      ; Row to display scores
SCORE_DISPLAY_P1_COL    =   10                      ; Column for Player 1 score
SCORE_DISPLAY_P2_COL    =   30                      ; Column for Player 2 score
END_SCORE               =   9                       ; Score needed to win
DELAY                   =   $40                     ; Delay value for frame rate control

; Keys
A                       =   $41                     ; 'A'
ALC                     =   $61                     ; 'a'
Z                       =   $5A                     ; 'Z'
ZLC                     =   $7A                     ; 'z'
K                       =   $4B                     ; 'K'
KLC                     =   $6B                     ; 'k'
M                       =   $4D                     ; 'M'
MLC                     =   $6D                     ; 'm'

; ==============================================================================
; Main Program
; ==============================================================================
                        ORG $8000                   ; Standard start address for binary programs

Start
                        JSR Init

GameLoop
                        JSR DrawPaddle1
                        JSR DrawPaddle2
                        JSR DrawBall
                        JSR DrawScore               ; Update Score Display
                        JSR WaitFrame               ; Simple delay
                        JSR EraseBall               ; Erase old ball position
                        JSR MoveBall
                        JSR CheckCollision
                        JSR ReadInput
                        JMP GameLoop

; ==============================================================================
; Initialization
; ==============================================================================
Init
                                                    ; 1. Set Soft Switches Manually
                        STA TEXT                    ; Set GRAPHICS mode (Text OFF)
                        STA MIXED                   ; Set MIXED mode
                        STA PAGE1                   ; Set PAGE 1
                        STA LORES

                                                    ; 2. Clear Entire Screen ($0400-$07FF) to Black ($00)
                        LDA #BLACK
                        LDX #$00
ClearScreenLoop
                        STA $0400,X
                        STA $0500,X
                        STA $0600,X
                        STA $0700,X
                        INX
                        BNE ClearScreenLoop

                                                    ; 3. Clear Text Window (Rows 20-23) to Spaces ($A0)
                                                    ; Row 20: $0650
                                                    ; Row 21: $06D0
                                                    ; Row 22: $0750
                                                    ; Row 23: $07D0

                        LDA #SPACE                  ; Space
                        LDX #0
ClearTextLoop
                        STA $0650,X                 ; Row 20
                        STA $06D0,X                 ; Row 21
                        STA $0750,X                 ; Row 22
                        STA $07D0,X                 ; Row 23
                        INX
                        CPX #NUM_COLS
                        BNE ClearTextLoop

                                                    ; Initialize Variables
                        LDA #INITIAL_BALL_XY        ; Ball start position, both X and Y are the same
                        STA BallX
                        STA BallY
                        STA P1Y
                        STA P2Y

                        LDA #INITIAL_BALL_VELX
                        STA BallVelX

                        LDA #INITIAL_BALL_VELY
                        STA BallVelY

                        LDA #INITIAL_SCORE
                        STA Score1
                        STA Score2

                        RTS

; ==============================================================================
; Subroutines
; ==============================================================================

DrawScore
                                                    ; Position Cursor for Player 1 Score
                        LDA #SCORE_DISPLAY_ROW      ; Row 21
                        STA $25                     ; CV
                        LDA #SCORE_DISPLAY_P1_COL   ; Column 10
                        STA $24                     ; CH
                        JSR $FC22                   ; VTAB

                        LDA Score1
                        ORA #$B0                    ; Convert to ASCII number + $80
                        JSR COUT

                                                    ; Position Cursor for Player 2 Score
                        LDA #SCORE_DISPLAY_ROW
                        STA $25
                        LDA #SCORE_DISPLAY_P2_COL
                        STA $24
                        JSR $FC22

                        LDA Score2
                        ORA #$B0
                        JSR COUT
                        RTS

DrawPaddle1
                        LDA #WHITE
                        JSR COLOR
                        LDA #P1_X                   ; X coordinate
                        LDY P1Y                     ; Y coordinate (top of paddle)
                        JSR DrawPaddleCommon
                        RTS

DrawPaddle2
                        LDA #WHITE
                        JSR COLOR
                        LDA #P2_X                   ; X coordinate
                        LDY P2Y                     ; Y coordinate
                        JSR DrawPaddleCommon
                        RTS

ErasePaddle1
                        LDA #BLACK
                        JSR COLOR
                        LDA #P1_X
                        LDY P1Y
                        JSR DrawPaddleCommon
                        RTS

ErasePaddle2
                        LDA #BLACK
                        JSR COLOR
                        LDA #P2_X
                        LDY P2Y
                        JSR DrawPaddleCommon
                        RTS

DrawPaddleCommon
                                                    ; A = X coord, Y = Y start
                        STA Temp                    ; Save X coord
                        STY Temp2                   ; Save Y start (Current Row)

                        LDA #WHITE                  ; Paddle Color (REMOVED - Caller sets color)
                                                    ; STA $30         ; Manually set COLOR register
                                                    ; JSR COLOR       ; And call routine just in case

                        LDX #PADDLE_H               ; Height counter
DrawPaddleLoop
                        TXA                         ; Save X (Height counter)
                        PHA

                        LDY Temp                    ; Column (X coord)
                        LDA Temp2                   ; Row (Y coord)
                        JSR PLOT                    ; PLOT(Y=Col, A=Row)

                        PLA                         ; Restore X
                        TAX

                        INC Temp2                   ; Next Row
                        DEX
                        BNE DrawPaddleLoop

                        RTS

DrawBall
                        LDA #YELLOW                 ; Ball Color
                        JSR COLOR
                        LDY BallX                   ; Column (Y-Reg)
                        LDA BallY                   ; Row (Accumulator)
                        JSR PLOT                    ; PLOT(Y=Col, A=Row)
                        RTS

EraseBall
                        LDA #BLACK                  ; Background Color
                        JSR COLOR
                        LDY BallX                   ; Column (Y-Reg)
                        LDA BallY                   ; Row (Accumulator)
                        JSR PLOT                    ; PLOT(Y=Col, A=Row)
                        RTS

MoveBall
                                                    ; Update X
                        LDA BallX
                        CLC
                        ADC BallVelX
                        STA BallX

                                                    ; Update Y
                        LDA BallY
                        CLC
                        ADC BallVelY
                        STA BallY

                                                    ; Wall Collision (Top/Bottom)
                                                    ; Check Top
                        LDA BallY
                        CMP #TOP_ROW
                        BNE CheckBottom
                                                    ; Bounce
                        LDA BallVelY
                        EOR #$FF
                        CLC
                        ADC #1
                        STA BallVelY
                        JMP CheckHorizontal

CheckBottom
                        LDA BallY
                        CMP #BOTTOM_ROW             ; Bottom of GR window (0-39)
                        BNE CheckHorizontal
                                                    ; Bounce
                        LDA BallVelY
                        EOR #$FF
                        CLC
                        ADC #1
                        STA BallVelY

CheckHorizontal
                                                    ; Check Left Side (Player 1)
                        LDA BallX
                        CMP #P1_X+1                 ; Just past the paddle
                        BEQ CheckP1Collision

                                                    ; Check Right Side (Player 2)
                        LDA BallX
                        CMP #P2_X-1                 ; Just before the paddle
                        BEQ CheckP2Collision

                                                    ; Check Scoring (Left Wall)
                        LDA BallX
                        CMP #LEFT_WALL
                        BEQ ScoreP2

                                                    ; Check Scoring (Right Wall)
                        LDA BallX
                        CMP #RIGHT_WALL
                        BEQ ScoreP1

                        JMP DoneMove

CheckP1Collision
                                                    ; Ball is at X = P1_X + 1. Check if Y is within paddle range.
                        LDA BallY
                        SEC
                        SBC P1Y                     ; BallY - P1Y
                        BMI NoCollision             ; Ball is above paddle
                        CMP #PADDLE_H
                        BCS NoCollision             ; Ball is below paddle (>= Height)

                                                    ; Collision! Bounce
                        LDA #1                      ; Ball now moving right
                        STA BallVelX
                        JMP DoneMove

CheckP2Collision
                                                    ; Ball is at X = P2_X - 1. Check if Y is within paddle range.
                        LDA BallY
                        SEC
                        SBC P2Y
                        BMI NoCollision
                        CMP #PADDLE_H
                        BCS NoCollision

                                                    ; Collision! Bounce
                        LDA #$FF                    ; Ball now moving left
                        STA BallVelX
                        JMP DoneMove

NoCollision
                        JMP DoneMove

ScoreP1
                        INC Score1
                        LDA Score1
                        CMP #END_SCORE
                        BEQ GameOver
                        JSR ResetBall
                        JMP DoneMove

ScoreP2
                        INC Score2
                        LDA Score2
                        CMP #END_SCORE
                        BEQ GameOver
                        JSR ResetBall
                        JMP DoneMove

GameOver
                        JSR DrawScore               ; Draw the final score before freezing
Freeze
                        JMP Freeze

ResetBall
                        LDA #INITIAL_BALL_XY
                        STA BallX
                        STA BallY
                                                    ; Reset velocity or randomize? Let's just keep it simple.
                        LDA #INITIAL_BALL_VELX
                        STA BallVelX
                        LDA #INITIAL_BALL_VELY
                        STA BallVelY
                        RTS

DoneMove
                        RTS

CheckCollision
                                                    ; Logic moved into MoveBall for efficiency in this simple loop
                        RTS

ReadInput
                        LDA KBD                     ; Read keyboard
                        BMI KeyPressed              ; Key pressed (bit 7 set)
                        RTS                         ; No key, return immediately

KeyPressed
                        STA KBDSTRB                 ; Clear strobe
                        AND #$7F                    ; Clear high bit to get ASCII

                                                    ; Check Player 1 Keys
                        CMP #ALC
                        BEQ P1Up
                        CMP #A
                        BEQ P1Up
                        CMP #ZLC
                        BEQ P1Down
                        CMP #Z
                        BEQ P1Down

                                                    ; Check Player 2 Keys
                        CMP #KLC
                        BEQ P2Up
                        CMP #K
                        BEQ P2Up
                        CMP #MLC
                        BEQ P2Down
                        CMP #M
                        BEQ P2Down

                        RTS

P1Up
                        LDA P1Y
                        BEQ NoKey                   ; Already at top (0)
                        JSR ErasePaddle1
                        DEC P1Y
                        LDA P1Y
                        BEQ DoneP1Up                ; If reached 0, stop
                        DEC P1Y                     ; Move 2nd pixel
DoneP1Up
                        RTS

P1Down
                        LDA P1Y
                        CLC
                        ADC #PADDLE_H
                        CMP #BOTTOM_ROW             ; Bottom of screen (was 40)
                        BCS NoKey                   ; Already at bottom
                        JSR ErasePaddle1
                        INC P1Y

                                                    ; Check if we can move one more
                        LDA P1Y
                        CLC
                        ADC #PADDLE_H
                        CMP #BOTTOM_ROW             ; Bottom of screen (was 40)
                        BCS DoneP1Down
                        INC P1Y
DoneP1Down
                        RTS

P2Up
                        LDA P2Y
                        BEQ NoKey
                        JSR ErasePaddle2
                        DEC P2Y
                        LDA P2Y
                        BEQ DoneP2Up
                        DEC P2Y
DoneP2Up
                        RTS

P2Down
                        LDA P2Y
                        CLC
                        ADC #PADDLE_H
                        CMP #BOTTOM_ROW
                        BCS NoKey
                        JSR ErasePaddle2
                        INC P2Y

                                                    ; Check if we can move one more
                        LDA P2Y
                        CLC
                        ADC #PADDLE_H
                        CMP #BOTTOM_ROW
                        BCS DoneP2Down
                        INC P2Y
DoneP2Down
                        RTS

NoKey
                        RTS

WaitFrame
                        LDX #$00
WaitLoop1
                        LDY #DELAY                  ; Adjust for speed
WaitLoop2
                        DEY
                        BNE WaitLoop2
                        DEX
                        BNE WaitLoop1
                        RTS

; ==============================================================================
; Variables (Absolute Memory)
; ==============================================================================
BallX                   DFB 0
BallY                   DFB 0
BallVelX                DFB 0
BallVelY                DFB 0
P1Y                     DFB 0
P2Y                     DFB 0
Score1                  DFB 0
Score2                  DFB 0
Temp                    DFB 0
Temp2                   DFB 0

                                                    ; Merlin32 Directives
                        TYP BIN                     ; Binary file type
                        DSK PONG                    ; Save as PONG.dsk (or PONG on disk)
