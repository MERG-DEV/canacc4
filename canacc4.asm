  TITLE   "Source for CAN accessory decoder using CBUS"
; filename CANACC4e.asm
; use with CANACC4 pcb rev C

; CANACC4 is a basic 'consumer only' turnout driver with 4 output pairs.
; small model learning mode using the digital inputs for switch detection.
; This has no CAN ID enumeration.


; CAN rate at 125000 


; Busy mode NOT incorporated.
; 
; 
; DVs are timer settings for outputs (8)
; These are fixed at 50 millisecs. (pulse only)

; Rewritten for 32 bit ENs, 8/10/07
; Added delay for CDU recharge

; Seems to be working as expected  8/10/07

; Added clear of all ENs if unlearn is on during power up
; Tested OK

; DIL switch positions

; 1 Output select LSB
; 2 Outpot select MSB
; 3 Polarity of output
; 4 Learn
; 5 Unlearn /reset
; 6 Not used

; added RUN LED turnon. No full diagnostics yet.
; added short event handling for 'many' producers.
; correction for POL learning
; correction for bug in output. 
; fixed POL test handling 21/04/08

; changed to rev b  03/05/08

; increase in number of events
; LED flash when events full
; correction to EV change sequence for already learned events. (Bug fix)  22/08/08

; Rev d  includes fix for corruption of Rx0d0 - Roger Healey 05/11/08
; Rev e has fix to CAN filters so extended frames are ignored  1/11/09




; 
; Assembly options
  LIST  P=18F2480,r=hex,N=75,C=120,T=ON

  include   "p18f2480.inc"

; set config registers

; note. there seem to be differences in the naming of the CONFIG parameters between
; versions of the p18F2480.inf files

  CONFIG  FCMEN = OFF, OSC = HSPLL, IESO = OFF
  CONFIG  PWRT = ON,BOREN = BOHW, BORV=0
  CONFIG  WDT=OFF
  CONFIG  MCLRE = ON
  CONFIG  LPT1OSC = OFF, PBADEN = OFF
  CONFIG  DEBUG = OFF
  CONFIG  XINST = OFF,LVP = OFF,STVREN = ON,CP0 = OFF
  CONFIG  CP1 = OFF, CPB = OFF, CPD = OFF,WRT0 = OFF,WRT1 = OFF, WRTB = OFF
  CONFIG  WRTC = OFF,WRTD = OFF, EBTR0 = OFF, EBTR1 = OFF, EBTRB = OFF
  
;original CONFIG settings left here for reference
  
; __CONFIG  _CONFIG1H,  B'00100110' ;oscillator HS with PLL
; __CONFIG  _CONFIG2L,  B'00001110' ;brown out voltage and PWT  
; __CONFIG  _CONFIG2H,  B'00000000' ;watchdog time and enable (disabled for now)
; __CONFIG  _CONFIG3H,  B'10000000' ;MCLR enable  
; __CONFIG  _CONFIG4L,  B'10000001' ;B'10000001'  for   no debug
; __CONFIG  _CONFIG5L,  B'00001111' ;code protection (off)  
; __CONFIG  _CONFIG5H,  B'11000000' ;code protection (off)  
; __CONFIG  _CONFIG6L,  B'00001111' ;write protection (off) 
; __CONFIG  _CONFIG6H,  B'11100000' ;write protection (off) 
; __CONFIG  _CONFIG7L,  B'00001111' ;table read protection (off)  
; __CONFIG  _CONFIG7H,  B'01000000' ;boot block protection (off)




; processor uses 4 MHz resonator but clock is 16 MHz.

;**************************************************************************
;definitions

LEARN     equ 4 ;input bits in port B
POL   equ 5
UNLEARN   equ 5 ;setup jumper in port A (unlearn)
EN_NUM    equ .32
CMD_ON    equ   0x90
CMD_OFF equ 0x91
SCMD_ON equ 0x98  ;short command
SCMD_OFF  equ 0x99


;****************************************************************
; define RAM storage
  
  CBLOCK  0   ;file registers - access bank
          ;interrupt stack for low priority
          ;hpint uses fast stack
  W_tempL
  St_tempL
  Bsr_tempL
  PCH_tempH   ;save PCH in hpint
  PCH_tempL   ;save PCH in lpint
  Fsr_temp0L
  Fsr_temp0H 
  Fsr_temp1L
  Fsr_temp1H 
  TempCANCON
  TempCANSTAT
  Datmode     ;flag for data waiting 
  Count     ;counter for loading
  Count1
  Count2
  Rx0d0Copy   ; used in ev_set to avoid buffer corruption fault
  
  Temp      ;temps
  Temp1
  
  
  
  

  ENDC
  

  
  CBLOCK  h'60' ;rest of bank 0
  
  Rx0con      ;start of receive packet 0
  Rx0sidh
  Rx0sidl
  Rx0eidh
  Rx0eidl
  Rx0dlc
  Rx0d0
  Rx0d1
  Rx0d2
  Rx0d3
  Rx0d4
  Rx0d5
  Rx0d6
  Rx0d7
  
  
    
  
  Cmdtmp    ;command temp for number of bytes in frame jump table
  
  DNindex   ;holds number of allowed DNs
  Match   ;match flag

  ENcount   ;which EN matched
  ENend   ;last  EN number
  ENtemp
  EVtemp    ;holds current EV
  EVtemp1 
  EVtemp2 
  Mask
  Shift
  Shift1
  Eadr    ;temp eeprom address
    

  ;***************************************************************
  Timout    ;used in timer routines
  Timbit    ;
  Timset    ;
  Timtemp
  T1a     ;timer registers for each output
  T1b
  T2a
  T2b
  T3a
  T3b
  T4a
  T4b
  ;****************************************************************
  Opnum   ;used in testing for number match
  Opbit   ;bit to set or clear in output  
  Opbit1    ;temp used in output routine  
  ;*************************************************************
  
  Outtmp    ;used to sort out output
  Togmode   ;outputs to toggle
  ;
  ;****************************************************************
  
  
    
  ENDC
  
  CBLOCK  0x100   ;bank 1
  EN1         ;start of EN ram
  EN1a
  EN1b
  EN1c
  
  EN2
  EN2a
  EN2b
  EN2c
  
  ENDC
  CBLOCK  0x200   ;bank 2
  EV1         ;start of EV ram
  ENDC
  
  

  

;****************************************************************
;
;   start of program code

    ORG   0000h
    nop           ;for debug
    goto  setup

    ORG   0008h
    goto  hpint     ;high priority interrupt

    ORG   0018h 
    goto  lpint     ;low priority interrupt


;*******************************************************************

    ORG   0020h     ;start of program
; 
;
;   high priority interrupt. Used for CAN receive and transmit error.

hpint movff CANCON,TempCANCON
    movff CANSTAT,TempCANSTAT
  
  ; movff PCLATH,PCH_tempH    ;save PCLATH
    clrf  PCLATH
  
    movff FSR0L,Fsr_temp0L    ;save FSR0
    movff FSR0H,Fsr_temp0H
    movff FSR1L,Fsr_temp1L    ;save FSR1
    movff FSR1H,Fsr_temp1H
    
    movf  TempCANSTAT,W     ;Jump table
    andlw B'00001110'
    addwf PCL,F     ;jump
    bra   back
    bra   back      ;error interrupt
    bra   back
    bra   back
    bra   back
    bra   rxb1int     ;only receive interrupts used
    bra   rxb0int
    bra   back
    
rxb1int bcf   PIR3,RXB1IF   ;uses RB0 to RB1 rollover so may never use this
                ;may need bank switch?
    lfsr  FSR0,Rx0con   ; 
    goto  access
    
rxb0int bcf   PIR3,RXB0IF
    lfsr  FSR0,Rx0con
    goto  access
    
    ;error routine here. Only acts on lost arbitration  


access  movf  CANCON,W
    andlw B'11110001'
    movwf CANCON
    movf  TempCANSTAT,W
    andlw B'00001110'
    iorwf CANCON
    lfsr  FSR1,RXB0CON  ;this is switched bank
load  movff POSTINC1,POSTINC0
    movlw 0x6E      ;end of access buffer lo byte
    cpfseq  FSR1L
    bra   load
    movlw B'00001111'   ;ignore any zero length frame
    andwf Rx0dlc,W
    bz    back
    bsf   Datmode,0   ;flag valid frame   
    
back  bcf   RXB0CON,RXFUL ;ready for next
  
back1 movlw B'00000011'
    andwf PIR3      ;clear any other flags
    movf  CANCON,W
    andlw B'11110001'
    iorwf TempCANCON,W
    
    movwf CANCON
;   movff PCH_tempH,PCLATH
    movff Fsr_temp0L,FSR0L    ;recover FSR0
    movff Fsr_temp0H,FSR0H
    movff Fsr_temp1L,FSR1L    ;recover FSR1
    movff Fsr_temp1H,FSR1H
    

    
    retfie  1       ;use shadow registers


    


    
    
  

;**************************************************************
;
;
;   low priority interrupt. Used by output timer overflow. Every 10 millisecs.
; 

lpint movwf W_tempL       ;used for output timers
    movff STATUS,St_tempL
    movff BSR,Bsr_tempL

;   movff PCLATH,PCH_tempL    ;save PCLATH
;   clrf  PCLATH
  

    movlw 0x78        ;Timer 1 lo byte. (adjust if needed)
    movwf TMR1L       ;reset timer 1
    clrf  PIR1        ;clear all timer flags
;   movf  PORTC,F
;   bz    lpend       ;all off so do nothing
    
  
lp1   clrf  Timout
    clrf  Timbit        ;rolling bit for testing which timer
    dcfsnz  T1a,F
    bsf   Timout,0      ;set bits in Timout if it needs to go off
    dcfsnz  T1b,F
    bsf   Timout,1  
    dcfsnz  T2a,F
    bsf   Timout,2
    dcfsnz  T2b,F
    bsf   Timout,3
    dcfsnz  T3a,F
    bsf   Timout,4
    dcfsnz  T3b,F
    bsf   Timout,5
    dcfsnz  T4a,F
    bsf   Timout,6
    dcfsnz  T4b,F
    bsf   Timout,7
    tstfsz  Timout
    bra   off           ;turn off outputs
    bra   lpend         ;nothing to do
    
off   bsf   Timbit,0        ;set rolling bit
off1  movf  Timbit,W
    andwf Timout,W
    bnz   dobit         ;this timer is out
off2  rlncf Timbit,F
    bra   off1          ;try next timer
dobit xorwf Timout,F        ;clear bit in Timout
    andwf Timset,W        ;is this timer continuous
    bz    donot         ;a zero is continuous
        
    xorwf Timset,F        ;ignore next time
    call  map           ;for mapping
    movwf Timtemp
    comf  Timtemp,W
    andwf PORTC,F         ;turn off output
donot tstfsz  Timout          ;any more outputs to turn off?
    bra   off2  
    
lpend movff Bsr_tempL,BSR
    movf  W_tempL,W
    movff St_tempL,STATUS 
    retfie  
            

;*********************************************************************


; main waiting loop

main  btfss PIR2,TMR3IF   ;flash timer overflow?
    bra   noflash
    btg   PORTB,6     ;toggle LED
    bcf   PIR2,TMR3IF       ;
  
noflash btfss Datmode,0   ;any new CAN frame received?
    bra   main
    
    
  
    

  
                ;main packet handling is here
    
packet  movlw CMD_ON      ;on command?
    subwf Rx0d0,W
    bz    go_on
    movlw CMD_OFF     ;off command?
    subwf Rx0d0,W
    bz    go_on   
    movlw SCMD_ON
    subwf Rx0d0,W
    bz  short
    movlw SCMD_OFF
    subwf Rx0d0,W
    bz  short
              ;else do nothing
    
main2 bcf   Datmode,0   ;clear message flag
    bra   main

short   clrf  Rx0d1     ;clear NN for multi producer mode.
    clrf  Rx0d2
    

go_on btfss PORTB,LEARN   ;learn mode?
    goto  learn1
    call  enmatch     ;this is an event in this node?
    sublw 0       ;returns zero if a match
    bz    do_it
    
    bra   main2
    
do_it call  ev_set      ;direction is sorted out in ev_set
    bra   main2 

    

; learning routine  

learn1  call  enmatch     ;is it there already?
    sublw   0
    bz    isthere
    btfss PORTA,UNLEARN   ;if unset and not here
    bra   l_out     ;do nothing else 
    call  learnin     ;put EN into stack and RAM
    sublw 0
    bz    new_EV
    bra   l_out     ;too many so do nothing
isthere btfss PORTA,UNLEARN   ;is it here and unlearn,goto unlearn
    bra   unlearn     ;else modify EVs
    bra   mod_EV


    
  
new_EV  movlw LOW ENindex+1
    movwf EEADR
    bsf   EECON1,RD
    decf  EEDATA,W
    movwf ENcount       ;recover EN counter
mod_EV  rlncf ENcount,W     ;two byte values
    addlw LOW EVstart       ;point to EV
    movwf EEADR
    bsf   EECON1,RD
    call  getop       ;get switch. value in EVtemp
    movf  EVtemp,W
        
    iorwf EEDATA,W
    movwf Temp
    call  eewrite       ;put back EV value  
    incf  EEADR
    bsf   EECON1,RD
    
    btfsc PORTB,POL     ;test polarity
    bra   shift3
    movf  EVtemp,W
        
    iorwf EEDATA,W
    movwf EVtemp2
shift4  call  eewrite       ;put back EV qual value 
    movff Temp,EVtemp
    call  ev_set      ;try it
    bra   l_out

shift3  comf  EVtemp,W    ;clear the POL bit
    andwf EEDATA,W
    movwf EVtemp2
    bra   shift4  

l_out bcf   Datmode,0
    clrf  PCLATH
    goto  main2


    
                ;unlearn an EN. 
unlearn movlw LOW ENindex+1   ;get number of events in stack
    movwf EEADR
    bsf   EECON1,RD
    
    movff EEDATA,ENend
    movff EEDATA,ENtemp
    rlncf ENend,F     ;ready for end value
    rlncf ENend,F
    movlw LOW ENstart
    addwf ENend,F     ;end now points to next past end in EEPROM
    movlw 4
    addwf ENend,F
    rlncf ENcount,F   ;Double the counter for two bytes
    rlncf ENcount,F   ;Double the counter for two bytes
    movlw LOW ENstart + 4
    addwf ENcount,W
    movwf EEADR
un1   bsf   EECON1,RD
    movf  EEDATA,W    ;get byte
    decf  EEADR,F
    decf  EEADR,F
    decf  EEADR,F
    decf  EEADR,F
    call  eewrite     ;put back in
    movlw 5
    addwf EEADR,F
    movf  ENend,W
    cpfseq  EEADR
    bra   un1
    
    rrncf ENcount,F   ;back to double bytes
    rlncf ENtemp,F
    movlw LOW EVstart
    addwf ENtemp,F
    movlw 2
    addwf ENtemp,F
    movlw LOW EVstart + 2
    addwf ENcount,W
    movwf EEADR
un2   bsf   EECON1,RD
    movf  EEDATA,W    ;get byte
    decf  EEADR,F
    decf  EEADR,F
    call  eewrite     ;put back in
    movlw 3
    addwf EEADR,F
    movf  ENtemp,W
    cpfseq  EEADR
    bra   un2
    movlw LOW ENindex+1
    movwf EEADR
    bsf   EECON1,RD
    movf  EEDATA,W
    movwf Temp
    decf  Temp,W
    call  eewrite     ;put back number in stack less 1
    call  en_ram      ;rewrite RAM stack
    bcf   T3CON,TMR3ON  ;flash timer off
    bcf   PIR2,TMR3IF
    bcf   PORTB,6     ;LED off
    bra   l_out
    


;************************************************************** 

    
;***************************************************************************
;   main setup routine
;*************************************************************************
setup clrf  INTCON      ;no interrupts 
    clrf  ADCON0      ;ADC is off
    movlw B'00001111'   ;set Port A to all digital for now
    movwf ADCON1
    movlw B'11111111'   ;Port A all inputs  A3 is setup switch. 0 is setup
                ;Port A 5 is unlearn
    movwf TRISA     ;
    clrf  LATB
    movlw B'00111011'   ;RB0,1 logic inputs,  RB2 = CANTX, RB3 = CANRX, 
                ;RB4 is LEARN ,RB5 is POL 
                ;RB6,7 for debug, ICSP and diagnostics LEDs
    movwf TRISB
    clrf  PORTB
    bsf   PORTB,2     ;CAN recessive
    clrf  LATC
    movlw B'00000000'   ;Port C drives the output MOSFETs
    movwf TRISC
    clrf  PORTC     ;all outputs off

    
    bsf   RCON,IPEN   ;enable interrupt priority levels
    clrf  BSR       ;set to bank 0
    clrf  EECON1      ;no accesses to program memory  
    clrf  Datmode     ;flag for received frame
    clrf  Opbit
    clrf  Opnum
    
    clrf  ECANCON     ;CAN mode 0 for now
     
    bsf   CANCON,7    ;CAN to config mode
    movlw B'00000011'   ;set CAN bit rate at 125000 for now
    movwf BRGCON1
    movlw B'10011110'   ;set phase 1 etc
    movwf BRGCON2
    movlw B'00000011'   ;set phase 2 etc
    movwf BRGCON3
    movlw B'00100000'
    movwf CIOCON      ;CAN to high when off
    movlw B'00100100'
    movwf RXB0CON   ;enable double buffer of RX0
    movlb .15
    movlw B'00100000'   ;prevent extended frames
    movwf RXB1CON
    clrf  RXF0SIDL
    clrf  RXF1SIDL
    movlb 0
    
mskload lfsr  0,RXM0SIDH    ;Clear masks, point to start
mskloop clrf  POSTINC0    
    movlw LOW RXM1EIDL+1    ;end of masks
    cpfseq  FSR0L
    bra   mskloop 
    
    clrf  CANCON      ;out of CAN setup mode
    
    movlw B'10110000'
    movwf T3CON     ;set T3 for LED flash
    
    movlw B'10000001'   ;Timer 1 control.16 bit write
    movwf T1CON     ;Timer 1 is for output duration
    movlw 0x63
    movwf TMR1H     ;set timer hi byte
    movlw B'00000011'
    movwf IPR3      ;high priority CAN RX  interrupts(for now)
    clrf  IPR1      ;all peripheral interrupts are low priority
    clrf  IPR2
    clrf  PIE2
    movlw B'00000001'
    movwf PIE1      ;enable interrupt for timer 1
        
    
    
    clrf  INTCON2     ;enable port B pullups 
    clrf  INTCON3     ;just in case
    
  
    movlw B'00000011'   ;Rx0 and RX1 interrupt 
    movwf PIE3  
    call  timload     ;load timer settings to RAM
    
    
      ;test for clear all events
    btfss PORTB,LEARN   ;ignore the clear if learn is set
    goto  set2
    btfss PORTA,UNLEARN
    call  enclear     ;clear all events if unlearn is set during power up
    call  en_ram      ;load ENs into RAM for fast access
  
set2  clrf  PIR1
    clrf  PIR2
    clrf  PIR3      ;clear all flags
    movlw B'11000000'
    movwf INTCON      ;enable interrupts
    bsf PORTB,7     ;run LED on
    goto  main
    
  
    
  
    

    
;****************************************************************************
;   start of subroutines    
;*************************************************************************
;   sets an output  
    

do_out  movf  Opbit,W     ;Opbit has bit set for corresponding output number
    call  map       ;remaps this bit to correspond with actual output pin.
    iorwf PORTC,F     ;set output
    movf  Opbit,W
    iorwf Timset,F    ;set to timed for now
    lfsr  2,T1a     ;get time
    movf  Opnum,W
    addlw LOW Timers      ;EEPROM
    movwf EEADR
    bsf   EECON1,RD
    movf  EEDATA,W
    movwf Timtemp     ;hold value
    bz    timcont     ;time was zero so continuous
    movf  Opnum,W     ;get index
    movff Timtemp,PLUSW2  ;put in
    
    bra   onback      ;done
timcont comf  Opbit,W
    andwf Timset,F    ;clear bit
onback  return
;************************************************************************
;   turns an output off
    
out_off movf  Opbit,W
    call  map
    movwf Opbit1
    comf  Opbit1,W
    andwf PORTC,F     ;clear this output
    comf  Opbit,W
    andwf Timset,F    ;set to  no timer
offback return  
    
;********************************************************************
;   Do an event.  arrives with EV in EVtemp and POL in EVtemp2
;   Toggles outputs. Turns off before on.
;   Checks which outputs are active for the event
;   Checks command for ON or OFF and checks the POL bit for which way to set output

ev_set    movff Rx0d0, Rx0d0Copy
      clrf  Opbit
      btfss EVtemp,0
      bra   ev_set1   ;no action on pair 1
      btfss Rx0d0Copy,0   ;on or off?
      bra   ev1a
      btfss EVtemp2,0 ;reverse?
      bra   ev1_off
      bra   ev1_on
ev1a    btfss EVtemp2,0
      bra   ev1_on
      bra   ev1_off     
ev1_on    movlw 0
      movwf Opnum   ;output 1 is on
      bsf   Opbit,1
      call  out_off
      rrncf Opbit,F
      call  do_out
      call  delay2
      bra   ev_set1
ev1_off   movlw 1
      movwf Opnum   ;output 2 is on
      bsf   Opbit,0
      call  out_off
      rlncf Opbit,F
      call  do_out
      call  delay2
ev_set1   clrf  Opbit
      btfss EVtemp,1
      bra   ev_set2   ;no action on pair 2
      btfss Rx0d0Copy,0   ;on or off?
      bra   ev2a
      btfss EVtemp2,1 ;reverse?
      bra   ev2_off
      bra   ev2_on
ev2a    btfss EVtemp2,1
      bra   ev2_on
      bra   ev2_off     
ev2_on    movlw 2
      movwf Opnum   ;output 3 is on
      bsf   Opbit,3
      call  out_off
      rrncf Opbit,F
      call  do_out
      call  delay2
      bra   ev_set2
ev2_off   movlw 3
      movwf Opnum   ;output 4 is on
      bsf   Opbit,2
      call  out_off
      rlncf Opbit,F
      call  do_out
      call  delay2
ev_set2   clrf  Opbit
      btfss EVtemp,2
      bra   ev_set3   ;no action on pair 3
      btfss Rx0d0Copy,0   ;on or off?
      bra   ev3a
      btfss EVtemp2,2 ;reverse?
      bra   ev3_off
      bra   ev3_on
ev3a    btfss EVtemp2,2
      bra   ev3_on
      bra   ev3_off     
ev3_on    movlw 4
      movwf Opnum   ;output 5 is on
      bsf   Opbit,5
      call  out_off
      rrncf Opbit,F
      call  do_out
      call  delay2
      bra   ev_set3
ev3_off   movlw 5
      movwf Opnum   ;output 6 is on
      bsf   Opbit,4
      call  out_off
      rlncf Opbit,F
      call  do_out
      call  delay2
ev_set3   clrf  Opbit
      btfss EVtemp,3
      bra   ev_set4   ;no action on pair 4
      btfss Rx0d0Copy,0   ;on or off?
      bra   ev4a
      btfss EVtemp2,3 ;reverse?
      bra   ev4_off
      bra   ev4_on
ev4a    btfss EVtemp2,3
      bra   ev4_on
      bra   ev4_off     
ev4_on    movlw 6
      movwf Opnum   ;output 7 is on
      bsf   Opbit,7
      call  out_off
      rrncf Opbit,F
      call  do_out
      call  delay2
      bra   ev_set4
ev4_off   movlw 7
      movwf Opnum   ;output 8 is on
      bsf   Opbit,6
      call  out_off
      rlncf Opbit,F
      call  do_out
      call  delay2
ev_set4   return      
      

          
    
;******************************************************************
;   maps logical output to real output  (PCB layout was a problem)

map   movwf Opbit1      ;save opbit 
    clrf  Shift1
map1  rrcf  Opbit1,F    ;which bit is set?
    bc    map2      ;this one
    incf  Shift1,F      ;add one
    bra   map1
map2  movf  Shift1,W
    addlw LOW Opmap
    movwf EEADR     ;get mapped value
    bsf   EECON1,RD
    movf  EEDATA,W    ;output bit in W
    return
    
;***************************************************************************

;   reloads the timer settings from EEPROM to RAM

timload movlw LOW Timers      ;reloads timers
    movwf EEADR
    lfsr  FSR1,T1a
timloop bsf   EECON1,RD
    movff EEDATA,POSTINC1
    incf  EEADR
    movlw LOW Timers+8
    cpfseq  EEADR
    bra   timloop
    return
    

;**************************************************************************
;   write to EEPROM, EEADR must be set before this sub.
;   data to write comes in W
eewrite movwf EEDATA      
    bcf   EECON1,EEPGD
    bcf   EECON1,CFGS
    bsf   EECON1,WREN
    
    clrf  INTCON  ;disable interrupts
    movlw 0x55
    movwf EECON2
    movlw 0xAA
    movwf EECON2
    bsf   EECON1,WR
eetest  btfsc EECON1,WR
    bra   eetest
    bcf   PIR2,EEIF
    bcf   EECON1,WREN
    movlw B'11000000'
    movwf INTCON    ;reenable interrupts
    
    return  
    



      
;**************************************************************************
;
;   EN match. Compares EN (in Rx0d1 and Rx0d2) with stored ENs
;   If match, returns with W = 0
;   The matching number is in ENcount. The corresponding EV is in EVtemp and EVtemp2
;
enmatch lfsr  FSR0,EN1  ;EN ram image
    movlw LOW ENindex+1 ;
    movwf EEADR
    bsf   EECON1,RD
    movff EEDATA,Count
    clrf  ENcount
  
    
ennext  clrf  Match
    movf  POSTINC0,W
    cpfseq  Rx0d1
    incf  Match
    movf  POSTINC0,W
    cpfseq  Rx0d2
    incf  Match
    movf  POSTINC0,W
    cpfseq  Rx0d3
    incf  Match
    movf  POSTINC0,W
    cpfseq  Rx0d4
    incf  Match
    tstfsz  Match
    bra   en_match
    rlncf ENcount,W   ;get EVs
    addlw LOW EVstart   
    movwf EEADR
    bcf   EEADR,0   ;multiple of 2
    bsf   EECON1,RD
    movff EEDATA,EVtemp ;EV
    incf  EEADR
    bsf   EECON1,RD
    movff EEDATA,EVtemp2  ;EV qualifier
    
    retlw 0     ;is a match
en_match  
    movf  Count,F
    bz    en_out
    decf  Count,F
    incf  ENcount,F
    bra   ennext
en_out  retlw 1     ;no match
      
;**************************************************************************


;   learn input of EN

learnin btfss PORTA,UNLEARN     ;don't do if unlearn
    return
    movlw LOW ENindex+1
    movwf EEADR
    bsf   EECON1,RD
    movff EEDATA,ENcount    ;hold pointer
    movlw EN_NUM
    cpfslt  ENcount
    retlw 1           ;too many
    lfsr  FSR0,EN1      ;point to EN stack in RAM
    
    rlncf ENcount,F     ;double it
    rlncf ENcount,F     ;double again
    movf  ENcount,W
    movff Rx0d1,PLUSW0    ;put in RAM stack
    addlw 1
    movff Rx0d2,PLUSW0
    addlw 1
    movff Rx0d3,PLUSW0
    addlw 1
    movff Rx0d4,PLUSW0
    movlw LOW ENstart
    addwf ENcount,W
    movwf EEADR
    movf  Rx0d1,W       ;get EN hi byte
    call  eewrite
    incf  EEADR
    movf  Rx0d2,W
    call  eewrite
    incf  EEADR
    movf  Rx0d3,W
    call  eewrite
    incf  EEADR
    movf  Rx0d4,W
    call  eewrite
    
    
    movlw LOW ENindex+1
    movwf EEADR
    bsf   EECON1,RD
    movf  EEDATA,W
    addlw 1
    movwf Temp          ;increment for next
    call  eewrite       ;put back
    movlw EN_NUM        ;is it full now?
    subwf Temp,W
    bnz   notful
    bsf   T3CON,TMR3ON    ;set for flash
    retlw 1
notful  retlw 0     
    
    
;*********************************************************************
;   a delay routine
;   may be used to allow CDU to recharge between succesive outputs.
;   probably needs to be longer for this.
      
dely  movlw .10
    movwf Count1
dely2 clrf  Count
dely1 decfsz  Count,F
    goto  dely1
    decfsz  Count1
    bra   dely2
    return    
delay2  clrf  Count2    ;long delay for CDU recharge
del2  call  dely
    decfsz  Count2
    bra   del2
    return    

;**********************************************************************
;   loads ENs from EEPROM to RAM for fast access
;   shifts all 32 even if less are used

en_ram  movlw EN_NUM
    movwf Count     ;number of ENs allowed 
    
    bcf   STATUS,C    ;clear carry
    rlncf Count,F     ;double it
    rlncf Count,F     ;double again
    lfsr  FSR0,EN1    ;set FSR0 to start of ram buffer
    movlw LOW ENstart     ;load ENs from EEPROM to RAM
    movwf EEADR
enload  bsf   EECON1,RD   ;get first byte
    movff EEDATA,POSTINC0
    incf  EEADR
    decfsz  Count,F
    bra   enload
    return
    
;***************************************************************  
    
getop movlw B'00000011'   ;get DIP switch setting for output
    andwf PORTB,W     ;mask
        
    movwf Shift
    movlw 1
    movwf EVtemp
shift movf  Shift,F     ;is it zero?
    bz    shift2
    rlncf EVtemp,F    ;put rolling bit into EVtemp
    decf  Shift,F
    bra   shift
    
shift2  return

;****************************************************************
    
    ;   clears all stored events

enclear movlw EN_NUM * 6 + 2    ;number of locations in EEPROM
    movwf Count
    movlw LOW ENindex
    movwf EEADR
enloop  movlw 0
    call  eewrite
    incf  EEADR
    decfsz  Count
    bra   enloop
    return  
    
;************************************************************************
  
  ORG 0xF00000      ;EEPROM data. Defaults

    
Timers  de  .5,.5       ;Timers (for now)
    de  .5,.5       ;These are for each output
    de  .5,.5                       
    de  .5,.5                       
        

Opmap de  B'00000001',B'10000000'         ;output mapping
    de  B'00000010',B'01000000'         ;don't change this
    de  B'00100000',B'00000100'
    de  B'00010000',B'00001000' 
    
    ORG 0xF00020
    
ENindex de  0,0   ;points to next available EN number (only hi byte used)

  
  
ENstart ;start of 32 event numbers. 128 bytes
    
    ORG 0xF000A2
    
EVstart de  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0   ;event qualifiers
    de  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0   ;clear EEPROM
    de  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    de  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    de  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    de  0,0,0,0,0,0,0,0,0,0,0,0,0
    
      
    
    end
