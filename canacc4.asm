    TITLE   "Source for CAN accessory decoder using CBUS"
; filename CANACC4_2_v2q.asm
; use with ACC4_2 pcb rev A or with original ACC4 pcb

;ACC4_2 is a modified version of ACC4_h for use with a 12V system
;Incorporates drive for the voltage doubler
;Changes 07/06/10
;RA4 is the doubler drive. Uses the LPINT for a 50Hz square wave
;RA0 is the charge cutoff. Hi is run, low is off.
;Tested 07/06/10. Works OK
; 28/02/11 version b, added Id for CANACC4_2
; 07/03/11 version c
;     Boot command only works with NN of zero
;       Read parameters by index now works in SLiM mode with NN of zero
; version d clear NN_temph and NN_templ in slimset
; 18/03/11 version e - set number of event to zero in enclear
; 19/03/11 version f - add WRACK after NNCLR and EVLRN
; 22/09/11 version g - add WRACK after EVULN

;Rev 102_a  First version wrt CBUS Developers Guide
;     Add code to support 0x11 (RQMN)
;     Add code to return 8th parameter by index - Flags
;     Add code to support QNN
;rev 102b Ignore extended frames in packet receive routine
;rev 102c Remove 102b fix 

; 27/11/11 Version 103 is a development version for Flash Ram events
; rev 103a  derived from 102c - move Opmap to Flash from EEPROM
; rev 103b  rearrange code
; rev 103c  test build, add flash code
; rev 103d  bug fixes
; rev 103e  save opc cmd byte for On/Off type events
; rev 103f  remove call to copyev in do_it and add call to rdfbev
; rev 103g  Save INTCON when erasing and writing Flash
; rev 103h  Fix SLiM mode learn bug in evhndlr code
; rev 103j  Add Phil Wheeler's mods for output control

; rev v2a - First release build
; Rev v2b - use evhndlr_c.asm
; Rev v2c - fix bug in unlearn event
; Rev v2d - remove logging
; Rev v2e - Add rdfbev for rdbak
; Rev v2f - set default recharge timer to 200ms
; Rev v2g - Change reply to QNN to OPC_PNN 0xB6
; Rev v2h - add check for zero param index
; Rev v2j - no v2i, include file now evhndlr_d.asm
; Rev v2k - include file now evhndlr_e.asm, remove NEVER compied code
; No Rev l
; Rev v2m - New parameter format
; Rev v2n New self.enum as subroutine. New enum OPCs. 0x5D and 0x75
; Rev v2o (23Sep13) - Added configurable fire delay (Phil Wheeler)
; Rev v2p - 11-Dec-13, improved TMR1 setting, fixed some bugs, added charge delay (Phil Wheeler)
; Rev v2q (6Apr16)- Fix SLiM learn mode issue

;end of comments for ACC4_2

; 
; Assembly options
  LIST  P=18F2480,r=dec,N=75,C=120,T=ON

  include   "p18f2480.inc"
  include   "cbuslib/cbusdefs.inc"


;set config registers

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

S_PORT    equ PORTA
CE_BIT    equ 0 ;CANACC2 Charger Enable
S_BIT   equ 3 ;PB input
CD_BIT    equ 4 ;CANACC2 Charger Doubler Drive
UNLEARN   equ 5 ;setup jumper in port A (unlearn)

LED_PORT  equ PORTB
DOLEARN   equ 4 ;input bits in port B
LED2    equ 7 ;PB7 is the green LED on the PCB
LED1    equ 6 ;PB6 is the yellow LED on the PCB

POL     equ 5 ;Not apparently used

;Defaults
DFFTIM  equ 5      ; Default fire time (units of 10mS)
DFRDLY  equ 25     ; Default recharge delay (units of 10mS)
DFFDLY  equ 0      ; Default fire delay (units of 10mS)
DFCDLY  equ 3      ; Default CANACC2 Charge pump enable delay (units of 10mS)  

CHGFREQ equ 100    ; CANACC2 Charge pump frequency (50,100 or 200Hz only)
LPINTI  equ CHGFREQ*2 ; Low Priority Interrupts per second
TMR1CN  equ 0x10000-(.4000000/LPINTI) ;Timer 1 count (counts UP)

CMD_ON  equ 0x90  ;on event
CMD_OFF equ 0x91  ;off event
CMD_REQ equ 0x92
SCMD_ON equ 0x98
SCMD_OFF  equ 0x99
SCMD_REQ  equ 0x9A
OPC_PNN equ 0xB6  ;reply to QNN

OLD_EN_NUM  equ 32
EN_NUM  equ 128    ;number of allowed events
EV_NUM  equ 2   ;number of allowed EVs per event
ACC4_2_ID equ 8
HASH_SZ equ 8

CONSUMER  equ 1
PRODUCER  equ 2
COMBI   equ 3

Modstat equ 1   ;address in EEPROM

MAN_NO      equ MANU_MERG    ;manufacturer number
MAJOR_VER   equ 2
MINOR_VER   equ "r"
MODULE_ID   equ MTYP_CANACC4_2 ; id to identify this type of module
EVT_NUM     equ EN_NUM           ; Number of events
EVperEVT    equ EV_NUM           ; Event variables per event
NV_NUM      equ 16          ; Number of node variables
NODEFLGS    equ B'00001001' ; Node flags  Consumer=Yes, Producer=No, 
              ;FliM=No, Boot=YES
CPU_TYPE    equ P18F2480
;module parameters  change as required

;Para1  equ 165  ;manufacturer number
;Para2  equ  "K"  ;for now
;Para3  equ ACC4_2_ID
;Para4  equ EN_NUM    ;node descriptors (temp values)
;Para5  equ EV_NUM
;Para6  equ NV_NUM
;Para7  equ 2

#define HIGH_INT_VECT 0x0808  ;HP interrupt vector redirect. Change if target is different
#define LOW_INT_VECT  0x0818  ;LP interrupt vector redirect. Change if target is different.
#define RESET_VECT  0x0800  ;start of target
#define TYPE_PARAM  0x0810
#define NODE_PARAM  0x0820
#define NUM_PARAM   24
#define META_PARAM  NODE_PARAM + NUM_PARAM

;*******************************************************************
  include   "cbuslib/boot_loader.inc"
;****************************************************************
; define RAM storage

;************************************************************
  
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
  Fsr_temp2L

  TempCANCON
  TempCANSTAT
  TempINTCON
  Datmode     ;flag for data waiting 
  Count     ;counter for loading
  Count1
  Count2

  Cmdtmp    ;command temp for number of bytes in frame jump table
  
  DNindex   ;holds number of allowed DNs
  Match   ;match flag

  ENcount   ;which EN matched
  ENcount1
  EVtemp    ;holds current EV
  EVtemp1 
  EVtemp2 
  IDcount   ;used in self allocation of CAN ID.
  Latcount
  Keepcnt ;keepalive count
  Mode    ;for FLiM / SLiM etc
  Mask
  Shift
  Shift1
  
  Temp      ;temps
  Temp1
  CanID_tmp ;temp for CAN Node ID
  IDtemph   ;used in ID shuffle
  IDtempl
  NN_temph    ;node number in RAM
  NN_templ
  ENtemp1     ;number of events
  Dlc       ;data length for CAN TX
  OpcCmd      ;copy of Rx0d0
  
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
  
  Tx1con      ;start of transmit frame  1
  Tx1sidh
  Tx1sidl
  Tx1eidh
  Tx1eidl
  Tx1dlc
  Tx1d0
  Tx1d1
  Tx1d2
  Tx1d3
  Tx1d4
  Tx1d5
  Tx1d6
  Tx1d7
    
  OpTimr    ; Output timer (countdown)
  OpTrig    ; Output channel trigger mask
  OpFlag    ; Output flags  Timout    ;used in timer routines
  OpFdly    ; Output fire delay
  OpCdly    ; Output charge delay
  LPintc    ; LPint Counter
  
  T1a     ;timer registers for each output
  T1b
  T2a
  T2b
  T3a
  T3b
  T4a
  T4b
  Trchg   ; Recharge Time. Must follow T4b
  Tfdly   ; Fire delay. Must follow Trchg
  Tcdly   ; Charge delay. Must follow Tfdly
  ;End of timer values

  Opm1a   ; Mask for output 1a
  Opm1b   ; Mask for output 1b
  Opm2a   ; Mask for output 2a
  Opm2b   ; Mask for output 2b
  Opm3a   ; Mask for output 3a
  Opm3b   ; Mask for output 3b
  Opm4a   ; Mask for output 4a
  Opm4b   ; Mask for output 4b
  Roll    ;rolling bit for enum
  
  Fsr_tmp1Le  ;temp store for FSR1
  Fsr_tmp1He 

  ;variables used by Flash Ram event handling

  evaddrh     ; event data ptr
  evaddrl
  prevadrh    ; previous event data ptr
  prevadrl
  nextadrh    ; next event data ptr
  nextadrl
  htaddrh     ; current hash table ptr
  htaddrl
  htidx     ; index of current hash table entry in EEPROM
  hnum      ; actual hash number
  freadrh     ; current free chain address
  freadrl
  initFlags   ; used in intialising Flash from EEPROM events
  Saved_Fsr0L   ; used in rdfbev routine
  Saved_Fsr0H
  
  ev0
  ev1
  ev2
  ev3
  
  EVidx   ; EV index from learn cmd
  EVdata    ; EV data from learn cmd
  ENidx   ; event index from commands which access events by index
  CountFb0  ; counters used by Flash handling
  CountFb1  

  ENDC
  
  CBLOCK  0x80
  Enum0   ;bits for new enum scheme.
  Enum1
  Enum2
  Enum3
  Enum4
  Enum5
  Enum6
  Enum7
  Enum8
  Enum9
  Enum10
  Enum11
  Enum12
  Enum13
  
  
    
  ENDC

;****************************************************************
    CBLOCK 0x100    ;bank 1
  ; 64 bytes of event data - the quanta size for updating Flash
  evt00       ; Event number - 4 bytes
  evt01
  evt02
  evt03
  next0h        ; next entry in list
  next0l
  prev0h        ; previous entry in list
  prev0l
  ev00        ; event variables - upto 8
  ev01
  ev02
  ev03
  ev04
  ev05
  ev06
  ev07
  
  evt10       ; Event number - 4 bytes
  evt11
  evt12
  evt13
  next1h        ; next entry in list
  next1l
  prev1h        ; previous entry in list
  prev1l
  ev10        ; event variables - upto 8
  ev11
  ev12
  ev13
  ev14
  ev15
  ev16
  ev17
  
  evt20       ; Event number - 4 bytes
  evt21
  evt22
  evt23
  next2h        ; next entry in list
  next2l
  prev2h        ; previous entry in list
  prev2l
  ev20        ; event variables - upto 8
  ev21
  ev22
  ev23
  ev24
  ev25
  ev26
  ev27
  
  evt30       ; Event number - 4 bytes
  evt31
  evt32
  evt33
  next3h        ; next entry in list
  next3l
  prev3h        ; previous entry in list
  prev3l
  ev30        ; event variables - upto 8
  ev31
  ev32
  ev33
  ev34
  ev35
  ev36
  ev37
  
  ENDC
  
  CBLOCK  0x200   ;bank 1
  EN1         ;start of EN ram
  EN1a
  EN1b
  EN1c
  
  EN2
  EN2a
  EN2b
  EN2c
  
  ENDC

  CBLOCK  0x280   ;bank 2
  EV1         ;start of EV ram
  ENDC
  
  

; processor uses  4 MHz. Resonator with HSPLL to give a clock of 16MHz

;********************************************************************************



;****************************************************************
;
;   start of program code

    ORG   RESET_VECT
loadadr
    nop           ;for debug
    goto  setup

    ORG   HIGH_INT_VECT
    goto  hpint     ;high priority interrupt

    ORG   TYPE_PARAM     ;node type parameters
myName  db    "ACC4_2 "

    ORG   LOW_INT_VECT 
    goto  lpint     ;low priority interrupt
    
    ORG   NODE_PARAM

nodeprm     db  MAN_NO, MINOR_VER, MODULE_ID, EVT_NUM, EVperEVT, NV_NUM 
      db  MAJOR_VER,NODEFLGS,CPU_TYPE,PB_CAN    ; Main parameters
            dw  RESET_VECT     ; Load address for module code above bootloader
            dw  0           ; Top 2 bytes of 32 bit address not used
sparprm     fill 0,prmcnt-$ ; Unused parameter space set to zero

PRMCOUNT    equ sparprm-nodeprm ; Number of parameter bytes implemented

             ORG META_PARAM

prmcnt      dw  PRMCOUNT    ; Number of parameters implemented
nodenam     dw  myName      ; Pointer to module type name
            dw  0 ; Top 2 bytes of 32 bit address not used


PRCKSUM     equ MAN_NO+MINOR_VER+MODULE_ID+EVT_NUM+EVperEVT+NV_NUM+MAJOR_VER+NODEFLGS+CPU_TYPE+PB_CAN+HIGH myName+LOW myName+HIGH loadadr+LOW loadadr+PRMCOUNT

cksum       dw  PRCKSUM     ; Checksum of parameters



;*******************************************************************

; 
;
;   high priority interrupt. Used for CAN receive and transmit error.

hpint movff CANCON,TempCANCON
    movff CANSTAT,TempCANSTAT
  
  ; movff PCLATH,PCH_tempH    ;save PCLATH
  ; clrf  PCLATH
  
    movff FSR0L,Fsr_temp0L    ;save FSR0
    movff FSR0H,Fsr_temp0H
    movff FSR1L,Fsr_temp1L    ;save FSR1
    movff FSR1H,Fsr_temp1H
    movlw 8
    movwf PCLATH
    movf  TempCANSTAT,W     ;Jump table
    andlw B'00001110'
    addwf PCL,F     ;jump
    bra   back
    bra   errint      ;error interrupt
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
    btfsc Datmode,1     ;setup mode?
    bra   setmode 
    lfsr  FSR0,Rx0con
    goto  access
    
    ;error routine here. Only acts on lost arbitration  

errint  movlb 15         ;change bank      
    btfss TXB1CON,TXLARB
    bra   errbak        ;not lost arb.
  
    movf  Latcount,F      ;is it already at zero?
    bz    errbak
    decfsz  Latcount,F
    bra   errbak
    bcf   TXB1CON,TXREQ
    movlw B'00111111'
    andwf TXB1SIDH,F      ;change priority
txagain bsf   TXB1CON,TXREQ   ;try again
          
errbak    bcf   RXB1CON,RXFUL
    movlb 0
    bcf   RXB0CON,RXFUL   ;ready for next  
    bcf   COMSTAT,RXB0OVFL  ;clear overflow flags if set
    bcf   COMSTAT,RXB1OVFL    
    bra   back1


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
    bcf   RXB0CON,RXFUL
    
    btfsc Rx0dlc,RXRTR    ;is it RTR?
    bra   isRTR
;   btfsc Datmode,1     ;setup mode?
;   bra   setmode 
    movf  Rx0dlc,F
    bz    back
;   btfss Rx0sidl,3   ;ignore extended frames
    bsf   Datmode,0   ;valid message frame  
    
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


isRTR btfsc Datmode,1   ;setup mode?
    bra   back      ;back
    btfss Mode,1      ;FLiM?
    bra   back
    movlb 15
    
isRTR1  btfsc TXB2CON,TXREQ ;send ID frame - preloaded in TXB2
    bra   isRTR1
    bsf   TXB2CON,TXREQ
    movlb 0
    bra   back

setmode tstfsz  RXB0DLC
    bra   back        ;only zero length frames for setup
    
    swapf RXB0SIDH,W      ;get ID into one byte
    rrcf  WREG
    andlw B'01111000'     ;mask
    movwf Temp
    swapf RXB0SIDL,W
    rrncf WREG
    andlw B'00000111'
    iorwf Temp,W
    movwf IDcount       ;has current incoming CAN_ID

    lfsr  FSR1,Enum0      ;set enum to table
enum_st clrf  Roll        ;start of enum sequence
    bsf   Roll,0
    movlw 8
enum_1  cpfsgt  IDcount
    bra   enum_2
    subwf IDcount,F     ;subtract 8
    incf  FSR1L       ;next table byte
    bra   enum_1
enum_2  dcfsnz  IDcount,F
    bra   enum_3
    rlncf Roll,F
    bra   enum_2
enum_3  movf  Roll,W
    iorwf INDF1,F


;   call  shuffin       ;get CAN ID as a single byte in W
;   cpfseq  IDcount
;   bra   back        ;not equal
;   incf  IDcount,F
;   movlw 100
;   cpfslt  IDcount       ;too many?
;   decf  IDcount,F     ;stay at 100
    bra   back    


    
    
  

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
  

    movlw LOW TMR1CN      ;Timer 1 lo byte. (adjust if needed)
    movwf TMR1L       ;reset timer 1
    clrf  PIR1        ;clear all timer flags
    movf  OpCdly,W      ;Is charge delay active?
    bnz   lpint0        ;Don't toggle doubler drive then
    btg   S_PORT,CD_BIT   ;doubler drive
lpint0
#if CHGFREQ > 50
    incf  LPintc,F      ;Increment count
    btfsc LPintc,0      ;skip alternate interrupts
    bra   lpend       ;all done
#if CHGFREQ >= 200
    btfsc LPintc,1      ;skip alternate interrupts
    bra   lpend       ;all done
#endif
#endif
    
; We get here once every 10mS, no matter what interrupt rate is in use
; Countdown fire delay (time between an event received and an output firing)

    movf  OpFdly,W    ; Get fire delay, is it zero?
    bz    lpint1      ; Inactive, check for next operation
    decf  OpFdly,F    ; Decrement fire delay
lpint1

; Countdown charge delay (time between an output firing and the doubler restarting)

    movf  OpCdly,W    ; Get fire delay, is it zero?
    bz    lpint2      ; Inactive, check for next operation
    decf  OpCdly,F    ; Decrement fire delay
lpint2

; Control PORTC (trigger) outputs

    movf  OpTimr,W    ; Get timer value, is it zero?
    bz    donext      ; Inactive, check for next operation
    decfsz  OpTimr,F    ; Decrement timer, skip if zero (expired)
    bra   lpend     ; Timer not expired, all done for now

; Process expired timer

    bsf   S_PORT,CE_BIT ; Enable Charging
    movf  OpFlag,W    ; Get output flag to W and set/reset Z
    bz    donext      ; Not recharging, do next output
    andwf PORTC,F     ; Turn off last outputs
    clrf  OpFlag      ; Clear output flag
    movf  Trchg,W     ; Get recharge time
    bz    donext      ; None, do next output
    movwf OpTimr      ; Store timer value
    bra   lpend

; Find next bit to trigger

donext  movf  OpTrig,F    ; Check trigger
    bz    lpend     ; All done
    movf  OpFdly,F    ; Check fire delay
    bnz   lpend     ; Wait until zero
    btfsc OpTrig,0    ; Do output 1a?
    bra   trig1a
    btfsc OpTrig,1    ; Do output 1b?
    bra   trig1b
    btfsc OpTrig,2    ; Do output 2a?
    bra   trig2a
    btfsc OpTrig,3    ; Do output 2b?
    bra   trig2b
    btfsc OpTrig,4    ; Do output 3a?
    bra   trig3a
    btfsc OpTrig,5    ; Do output 3b?
    bra   trig3b
    btfsc OpTrig,6    ; Do output 4a?
    bra   trig4a
    bra   trig4b      ; Do output 4b

; Trigger output 1a

trig1a  bcf   OpTrig,0    ; Clear trigger bit
    comf  Opm1b,W     ; Get inverted mask for other output into W
    andwf PORTC,F     ; Set other output off
    movf  Opm1a,W     ; Get mask for active output into W
    iorwf PORTC,F     ; Active pair on
    movf  T1a,W     ; Get timer into W
    bz    lpend     ; If timer is zero, then all done
    movwf OpTimr      ; Save timer value
    comf  Opm1a,W     ; Get inverted mask for active output into W
    movwf OpFlag      ; Save in flag byte
    bra   trig

; Trigger output 1b

trig1b  bcf   OpTrig,1    ; Clear trigger bit
    comf  Opm1a,W     ; Get inverted mask for other output into W
    andwf PORTC,F     ; Set other output off
    movf  Opm1b,W     ; Get mask for active output into W
    iorwf PORTC,F     ; Active pair on
    movf  T1b,W     ; Get timer into W
    bz    lpend     ; If timer is zero, then all done
    movwf OpTimr      ; Save timer value
    comf  Opm1b,W     ; Get inverted mask for active output into W
    movwf OpFlag      ; Save in flag byte
    bra   trig

; Trigger output 2a

trig2a  bcf   OpTrig,2    ; Clear trigger bit
    comf  Opm2b,W     ; Get inverted mask for other output into W
    andwf PORTC,F     ; Set other output off
    movf  Opm2a,W     ; Get mask for active output into W
    iorwf PORTC,F     ; Active pair on
    movf  T2a,W     ; Get timer into W
    bz    lpend     ; If timer is zero, then all done
    movwf OpTimr      ; Save timer value
    comf  Opm2a,W     ; Get inverted mask for active output into W
    movwf OpFlag      ; Save in flag byte
    bra   trig

; Trigger output 2b

trig2b  bcf   OpTrig,3    ; Clear trigger bit
    comf  Opm2a,W     ; Get inverted mask for other output into W
    andwf PORTC,F     ; Set other output off
    movf  Opm2b,W     ; Get mask for active output into W
    iorwf PORTC,F     ; Active pair on
    movf  T2b,W     ; Get timer into W
    bz    lpend     ; If timer is zero, then all done
    movwf OpTimr      ; Save timer value
    comf  Opm2b,W     ; Get inverted mask for active output into W
    movwf OpFlag      ; Save in flag byte
    bra   trig

; Trigger output 3a

trig3a  bcf   OpTrig,4    ; Clear trigger bit
    comf  Opm3b,W     ; Get inverted mask for other output into W
    andwf PORTC,F     ; Set other output off
    movf  Opm3a,W     ; Get mask for active output into W
    iorwf PORTC,F     ; Active pair on
    movf  T3a,W     ; Get timer into W
    bz    lpend     ; If timer is zero, then all done
    movwf OpTimr      ; Save timer value
    comf  Opm3a,W     ; Get inverted mask for active output into W
    movwf OpFlag      ; Save in flag byte
    bra   trig

; Trigger output 3b

trig3b  bcf   OpTrig,5    ; Clear trigger bit
    comf  Opm3a,W     ; Get inverted mask for other output into W
    andwf PORTC,F     ; Set other output off
    movf  Opm3b,W     ; Get mask for active output into W
    iorwf PORTC,F     ; Active pair on
    movf  T3b,W     ; Get timer into W
    bz    lpend     ; If timer is zero, then all done
    movwf OpTimr      ; Save timer value
    comf  Opm3b,W     ; Get inverted mask for active output into W
    movwf OpFlag      ; Save in flag byte
    bra   trig

; Trigger output 4a

trig4a  bcf   OpTrig,6    ; Clear trigger bit
    comf  Opm4b,W     ; Get inverted mask for other output into W
    andwf PORTC,F     ; Set other output off
    movf  Opm4a,W     ; Get mask for active output into W
    iorwf PORTC,F     ; Active pair on
    movf  T4a,W     ; Get timer into W
    bz    lpend     ; If timer is zero, then all done
    movwf OpTimr      ; Save timer value
    comf  Opm4a,W     ; Get inverted mask for active output into W
    movwf OpFlag      ; Save in flag byte
    bra   trig

; Trigger output 4b

trig4b  bcf   OpTrig,7    ; Clear trigger bit
    comf  Opm4a,W     ; Get inverted mask for other output into W
    andwf PORTC,F     ; Set other output off
    movf  Opm4b,W     ; Get mask for active output into W
    iorwf PORTC,F     ; Active pair on
    movf  T4b,W     ; Get timer into W
    bz    lpend     ; If timer is zero, then all done
    movwf OpTimr      ; Save timer value
    comf  Opm4b,W     ; Get inverted mask for active output into W
    movwf OpFlag      ; Save in flag byte
    
trig  bcf   S_PORT,CE_BIT ; Disable Charging
    movf  OpTimr,W    ; Get output timer setting
    addwf Tcdly,W     ; Add a bit more delay
    movwf OpCdly      ; Set charge delay
    
lpend movff Bsr_tempL,BSR
    movf  W_tempL,W
    movff St_tempL,STATUS 
    retfie  
            

;*********************************************************************


; main waiting loop

main0 btfsc Mode,1      ;is it SLiM?
    bra   mainf     ;no

mains             ;is SLiM

    btfss PIR2,TMR3IF   ;flash timer overflow?
    bra   nofl_s      ;no SLiM flash
    btg   PORTB,7     ;toggle green LED
    bcf   PIR2,TMR3IF
nofl_s  bra   noflash       ;main1
    
; here if FLiM mde

mainf btfss INTCON,TMR0IF   ;is it flash?
    bra   noflash
    btfss Datmode,2
    bra   nofl1
    
    btg   PORTB,6     ;flash yellow LED
    
nofl1 bcf   INTCON,TMR0IF
    btfss Datmode,3   ;running mode
    bra   noflash
    decfsz  Keepcnt     ;send keep alive?
    bra   noflash
    movlw 10
    movwf Keepcnt
    movlw 0x52
;   call  nnrel     ;send keep alive frame (works OK, turn off for now)

noflash btfsc S_PORT,S_BIT  ;setup button?
    bra   main3
    movlw 100
    movwf Count
    clrf  Count1
    clrf  Count2
wait  decfsz  Count2
    goto  wait
    btfss Datmode,2
    bra   wait2
    btfss INTCON,TMR0IF   ;is it flash?
    bra   wait2
    btg   PORTB,6     ;flash LED
    bcf   INTCON,TMR0IF
wait2 decfsz  Count1
    goto  wait
    btfsc S_PORT,S_BIT
    bra   main4     ;not held long enough
    decfsz  Count
    goto  wait
    btfss Mode,1      ;is it in FLiM?
    bra   go_FLiM
    clrf  Datmode     ;back to virgin
;   bcf   Mode,1      ;SLiM mode
    bcf   PORTB,6     ;yellow off
    
    bsf   PORTB,7     ;Green LED on
    clrf  INTCON      ;interrupts off
    movlw 1
    movwf IDcount     ;back to start
    movlw Modstat
    movwf EEADR
    movlw   0
    call  eewrite     ;status to reset
    movlw 0x51      ;send node release frame
    call  nnrel
    clrf  NN_temph
    clrf  NN_templ
wait1 btfss S_PORT,S_BIT
    bra   wait1     ;wait till release
    call  ldely
    btfss S_PORT,S_BIT
    bra   wait1
  
    
    movlw LOW NodeID      ;put NN back to 0000
    movwf EEADR
    movlw 0
    call  eewrite
    incf  EEADR
    movlw 0
    call  eewrite 
    btfss Mode,1
    bra   main5       ;FLiM setup
    movlw Modstat
    movwf EEADR
    movlw 0
    call  eewrite       ;mode back to SLiM
    clrf  Datmode
    bcf   Mode,1
    bcf   PORTB,6
    bsf   PORTB,7       ;green LED on
  
    movlw B'11000000'
    movwf INTCON
    goto  main0       ;

main5 movlw Modstat
    movwf EEADR
    movlw 1
    call  eewrite       ;mode to FLiM in EEPROM
    bsf   Mode,1        ;to FLiM
    call  self_en       ;self enumerate routine
    bcf   Datmode,1
    call  nnack       ;send request for NN
    bsf   Datmode,2
;   movlw Modstat       ;only if needed
;   movwf EEADR
;   movlw B'00000100'
;   call  eewrite       ;mode to wait for NN in EEPROM
    bra   main1


main4 ;btfss  Datmode,3   
    ;bra    main3
    btfss Datmode,2
    bra   mset2
    bcf   Datmode,2
    bsf   PORTB,6     ;LED on
    movlw 0x52
    call  nnrel
    movlw Modstat
    movwf EEADR
    movlw B'00001000'
    movwf Datmode     ;normal
    call  eewrite
    bra   main3
    
mset2 bsf   Datmode,2
    call  self_en
    bcf   Datmode,1
    call  nnack
    bra   main1

main3 btfss Datmode,1   ;setup mode ?
    bra   main1
;   call  self_en

    bcf   Datmode,1   ;out of setup
    bsf   Datmode,2   ;wait for NN
;   call  nnack     ;send blank NN for config
  
;   
;   bsf   PORTB,7     ;on light
    bra   main1     ;continue normally

go_FLiM bsf   Datmode,1   ;FLiM setup mode
    bcf   PORTB,7     ;green off
    bra   wait1
    
    

; common to FLiM and SLiM   
  
  
main1 
    btfss Datmode,0   ;any new CAN frame received?
    bra   main0
    
    bra   packet      ;yes
    
;   These are here as branch was too long

unset 
    btfss Datmode,4     ;Roger's mod
    bra   main2       ;no error message on OPC 0x95
    bsf   Datmode,5
    call  copyev
    bra   learn2

readEV  btfss Datmode,4
    bra   main2     ;prevent error message
    call  copyev
    movf  EVidx,w     ;check EV index
    bz    rdev1
    decf  EVidx
    movlw EV_NUM
    cpfslt  EVidx
rdev1 bra   noEV1
    bsf   Datmode,6
    bra   learn2

evns1 call  thisNN        ;read event numbers
    sublw 0
    bnz   notNNx
    call  evnsend
    bra   main2
;evns3  goto  notNN

reval call  thisNN        ;read event numbers
    sublw 0
    bnz   notNNx
    movff Rx0d3,ENidx
    movff Rx0d4,EVidx
    call  evsend
    bra   main2
    
notNNx  goto  notNN

name
    btfss Datmode,2   ;only in setup mode
    bra   main2
    call  namesend
    bra   main2
    
doQnn
    movf  NN_temph,w    ;respond if NN is not zero
    addwf NN_templ,w
    btfss STATUS,Z
    call  whoami
    bra   main2
    
go_on_x goto  go_on

params  btfss Datmode,2   ;only in setup mode
    bra   main2
    call  parasend
    bra   main2
    
setNV call  thisNN
    sublw 0
    bnz   notNNx      ;not this node
    call  putNV
    call  timload     ;Reload NV's into RAM
    bra   main2

short clrf  Rx0d1
    clrf  Rx0d2
    bra   go_on

short1  goto  short     ;branches too long
evns  goto  evns1   
setNVx  goto  setNV
readNVx goto  readNV
readENx goto  readEN
readEVx goto  readEV
rden_x  goto  rden

    
;********************************************************************
                ;main packet handling is here
                ;add more commands for incoming frames as needed
    
packet  movlw CMD_ON  ;only ON, OFF  events supported
    subwf Rx0d0,W 
    bz    go_on_x
    movlw CMD_OFF
    subwf Rx0d0,W
    bz    go_on_x
    
    movlw SCMD_ON
    subwf Rx0d0,W
    bz    short
    movlw SCMD_OFF
    subwf Rx0d0,W
    bz    short
    
    movlw 0x5C      ;reboot
    subwf Rx0d0,W
    bz    reboot
    movlw 0x73
    subwf Rx0d0,W
    bz    para1a      ;read individual parameters
  
    
    movlw 0x0d      ; QNN
    subwf Rx0d0,w
    bz    doQnn
    movlw 0x10      
    subwf Rx0d0,W
    bz    params      ;read node parameters
    movlw 0x11
    subwf Rx0d0,w
    bz    name      ;read module name
    btfss Mode,1      ;FLiM?
    bra   main2
    movlw 0x42      ;set NN on 0x42
    subwf Rx0d0,W
    bz    setNN
    movlw 0x53      ;set to learn mode on 0x53
    subwf Rx0d0,W
    bz    setlrn1   
    movlw 0x54      ;clear learn mode on 0x54
    subwf Rx0d0,W
    bz    notlrn1
    movlw 0x55      ;clear all events on 0x55
    subwf Rx0d0,W
    bz    clrens1
    movlw 0x56      ;read number of events left
    subwf Rx0d0,W
    bz    rden_x
    movlw 0x71      ;read NVs
    subwf Rx0d0,W
    bz    readNVx
    movlw 0x96      ;set NV
    subwf Rx0d0,W
    bz    setNVx
    movlw 0x5D      ;re-enumerate
    subwf Rx0d0,W
    bz    enum1
    movlw 0x71      ;read NVs
    subwf Rx0d0,W
    bz    readNVx
    movlw 0x75      ;force new CAN_ID
    subwf Rx0d0,W
    bz    newID1
    movlw 0x96      ;set NV
    subwf Rx0d0,W
    bz    setNVx
    movlw 0xD2      ;is it set event?
    subwf Rx0d0,W
    bz    chklrn1     ;do learn
    movlw 0x95      ;is it unset event
    subwf Rx0d0,W     
    bz    unset1
    movlw 0xB2      ;read event variables
    subwf Rx0d0,W
    bz    readEVx
  
    movlw 0x57      ;is it read events
    subwf Rx0d0,W
    bz    readENx
    movlw 0x72
    subwf Rx0d0,W
    bz    readENi1      ;read event by index
    movlw 0x58
    subwf Rx0d0,W
    bz    evns
    movlw 0x9C        ;read event variables by EN#
    subwf Rx0d0,W
    bz    reval1

    bra main2       ;end of events lookup

enum1 goto  enum
clrens1 goto  clrens  
newID1  goto  newID
notlrn1 goto  notlrn
chklrn1 goto  chklrn
setlrn1 goto  setlrn
unset1  goto  unset
readENi1 goto readENi
reval1  goto  reval

    bra   main2

;short1 goto  short     ;branches too long
;evns goto  evns1   
;etNVx  goto  setNV
;readNVx  goto  readNV
;readENx  goto  readEN
;eadEVx goto  readEV
;rden_x goto  rden
    
reboot  btfss Mode,1      ;FLiM?
    bra   reboots
    call  thisNN
    sublw 0
    bnz   notNN
    
reboot1 movlw 0xFF
    movwf EEADR
    movlw 0xFF
    call  eewrite     ;set last EEPROM byte to 0xFF
    reset         ;software reset to bootloader

reboots
    movf  Rx0d1,w
    addwf Rx0d2,w
    bnz   notNN
    bra   reboot1 
  
para1a  btfss Mode, 1
    bra   para1s
    call  thisNN      ;read parameter by index
    sublw 0
    bnz   notNN
    call  para1rd
    bra   main2
    
para1s
    movf  Rx0d1,w
    addwf Rx0d2,w
    bnz   notNN
    call  para1rd
    bra   main2
      
main2 bcf   Datmode,0
    goto  main0     ;loop
    
setNN btfss Datmode,2   ;in NN set mode?
    bra   main2     ;no
    call  putNN     ;put in NN
    bcf   Datmode,2
    bsf   Datmode,3
    movlw 10
    movwf Keepcnt     ;for keep alive
    movlw 0x52
    call  nnrel     ;confirm NN set
    bcf   PORTB,7 
    bsf   PORTB,6     ;LED ON
    bra   main2

newID call  thisNN
    sublw 0
    bnz   notNN
    movff Rx0d3,IDcount

    call  here2       ;put in as if it was enumerated
    movlw 0x52
    call  nnrel       ;acknowledge new CAN_ID
    goto  main2


    
sendNN  btfss Datmode,2   ;in NN set mode?
    bra   main2     ;no
    movlw 0x50      ;send back NN
    movwf Tx1d0
    movlw 3
    movwf Dlc
    call  sendTX
    bra   main2

rden  goto  rden1
  
setlrn  call  thisNN
    sublw 0
    bnz   notNN
    bsf   Datmode,4
    bsf   PORTB,6     ;LED on
    bra   main2

notlrn  call  thisNN
    sublw 0
    bnz   notNN
    bcf   Datmode,4
notln1    ;leave in learn mode
    bcf   Datmode,5
;   bcf   LED_PORT,LED2
    bra   main2
clrens  call  thisNN
    sublw 0
    bnz   notNN
    btfss Datmode,4
    bra   clrerr
    call  initevdata
    movlw 0x59
    call  nnrel   ;send WRACK
    bra   notln1
    
notNN bra   main2

clrerr  movlw 2     ;not in learn mode
    goto  errmsg

    
chklrn  btfss Datmode,4   ;is in learn mode?
    bra   main2     ;j if not
    call  copyev
    movf  EVidx,w     ;check EV index
    bz    noEV1
    decf  EVidx
    movlw EV_NUM
    cpfslt  EVidx
    bra   noEV1
    bra   learn2
    
noEV1
    movlw 6
    goto  errmsg

readENi call  thisNN      ;read event by index
    sublw 0
    bnz   notNN
    call  enrdi
    bra   main2



enum  call  thisNN
    sublw 0
    bnz   notNN1
    call  self_en
    movlw 0x52
    call  nnrel     ;send confirm frame
    movlw B'00001000'   ;back to normal running
    movwf Datmode
    goto  main2
notNN1  goto  notNN
  
copyev    ; copy event data to safe buffer
    movff Rx0d1, ev0
    movff Rx0d2, ev1
    movff Rx0d3, ev2
    movff Rx0d4, ev3
    movff Rx0d5, EVidx    ; only used by learn and some read cmds
    movff Rx0d6, EVdata   ; only used by learn cmd
    return    

go_on call  copyev
    btfss Mode,1      ;FLiM?
    bra   go_on_s
    
go_on1  call  enmatch
    sublw 0
    bz    do_it
    bra   main2     ;not here

go_on_s btfss PORTB,DOLEARN
    bra   learn2      ;is in learn mode
    bra   go_on1

paraerr movlw 3       ;error not in setup mode
    goto  errmsg



readNV  call  thisNN
    sublw 0
    bnz   notNN     ;not this node
    call  getNV
    bra   main2

readEN  call  thisNN
    sublw 0
    bnz   notNN
    call  enread
    bra   main2
    
do_it
    call  rdfbev
    movff POSTINC0, EVtemp
    movff POSTINC0, EVtemp2
    call  ev_set      ;do it -  for consumer action
    bra   main2
      
rden1 call  thisNN
    sublw 0
    bnz   notNN
    call  rdFreeSp
    bra   main2   
    
learn1
    bra   learn2
    
learn2  call  enmatch     ;is it there already?
    sublw   0
    bz    isthere
    btfsc Mode,1      ;FLiM?
    bra   learn3
    btfss S_PORT,UNLEARN  ;if unset and not here
    bra   l_out2      ;do nothing else 
    call  learnin     ;put EN into stack and RAM
    sublw 0
    bz    lrnend
    movlw 4
    goto  errmsg1     ;too many
    
    ;here if FLiM
learn3  btfsc Datmode,6   ;read EV?
    bra   rdbak1      ;not here
    btfsc Datmode,5   ;if unset and not here
    bra   l_out1      ;do nothing else 
    
learn4  call  learnin     ;put EN into stack and RAM
    sublw 0
    bz    lrnend

    movlw 4
    goto  errmsg2 
    
rdbak1  movlw 5       ;no match
    goto  errmsg2
    
lrnend
    bra   go_on1
                
isthere
    btfsc Mode,1
    bra   isthf     ;j if FLiM mode
    btfsc S_PORT,UNLEARN  ;is it here and unlearn...
    bra   dolrn
    call  unlearn     ;...goto unlearn  
    bra   l_out1
      
isthf
    btfsc Datmode, 6    ;is it read back
    bra   rdbak
    btfss Datmode,5   ;FLiM unlearn?
    bra   dolrn
    call  unlearn
    movlw 0x59
    call  nnrel
    bra   l_out1
    
dolrn
    call  learnin
    bra   lrnend
    
rdbak
    call  rdfbev      ; read event info
    movff EVidx,Tx1d5   ;Index for readout  
    incf  Tx1d5,F     ;add one back
    movf  EVidx,w
    movff PLUSW0,Tx1d6
    movlw 0xD3        ;readback of EVs
    movwf Tx1d0
    movff ev0,Tx1d1
    movff ev1,Tx1d2
    movff ev2,Tx1d3
    movff ev3,Tx1d4
    movlw 7
    movwf Dlc
    call  sendTXa 
    bra   l_out1

l_out bcf   Datmode,4
;   bcf   LED_PORT,LED2
l_out1  bcf   Datmode,6
l_out2  bcf   Datmode,0
    
    clrf  PCLATH
    goto  main2

noEV  movlw 6       ;invalid EV#
    goto  errmsg2

;***************************************************************************
;   main setup routine
;*************************************************************************

setup lfsr  FSR0, 0     ; clear 128 bytes of ram
nxtram  clrf  POSTINC0
    btfss FSR0L, 7
    bra   nxtram
    
    clrf  INTCON      ;no interrupts yet
    clrf  ADCON0      ;turn off A/D, all digital I/O
    movlw B'00001111'
    movwf ADCON1
    
    ;port settings will be hardware dependent. RB2 and RB3 are for CAN.
    ;set S_PORT and S_BIT to correspond to port used for setup.
    ;rest are hardware options
    
  
    movlw B'00101000'   ;Port A. PA3 is setup PB
    movwf TRISA     ;
    movlw B'00111011'   ;RB2 = CANTX, RB3 = CANRX,  
                ;RB6,7 for debug and ICSP and LEDs
                ;PORTB has pullups enabled on inputs
    movwf TRISB
    bcf   PORTB,6
    bcf   PORTB,7
    bsf   PORTB,2     ;CAN recessive
    movlw B'00000000'   ;Port C  set to outputs.
    movwf TRISC
    clrf  PORTC
  
    
; next segment is essential.
    
    bsf   RCON,IPEN   ;enable interrupt priority levels
    clrf  BSR       ;set to bank 0
    clrf  EECON1      ;no accesses to program memory  
    clrf  Datmode
    clrf  Latcount
    clrf  ECANCON     ;CAN mode 0 for now. 
     
    bsf   CANCON,7    ;CAN to config mode
    movlw B'00000011'   ;set CAN bit rate at 125000 for now
    movwf BRGCON1
    movlw B'10011110'   ;set phase 1 etc
    movwf BRGCON2
    movlw B'00000011'   ;set phase 2 etc
    movwf BRGCON3
    movlw B'00100000'
    movwf CIOCON      ;CAN to high when off
    movlw B'00100100'   ;B'00100100'
    movwf RXB0CON     ;enable double buffer of RX0
    movlb 15
    movlw B'00100000'   ;reject extended frames
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
    clrf  CCP1CON
    movlw B'10000100'
    movwf T0CON     ;set Timer 0 for LED flash
    movlw B'10000001'   ;Timer 1 control.16 bit write
    movwf T1CON     ;Timer 1 is for output duration
    movlw HIGH TMR1CN
    movwf TMR1H     ;set timer hi byte
    
    clrf  Tx1con
    movlw B'00100011'
    movwf IPR3      ;high priority CAN RX and Tx error interrupts(for now)
    clrf  IPR1      ;all peripheral interrupts are low priority
    clrf  IPR2
    clrf  PIE2
    movlw B'00000001'
    movwf PIE1      ;enable interrupt for timer 1


;next segment required
    
    movlw B'00000001'
    movwf IDcount     ;set at lowest value for starters
    
    clrf  INTCON2     ;
    clrf  INTCON3     ;
    

    movlw B'00100011'   ;B'00100011'  Rx0 and RX1 interrupt and Tx error
                
    movwf PIE3
  
    clrf  PIR1
    clrf  PIR2
    movlb 15
    bcf   RXB1CON,RXFUL
    movlb 0
    bcf   RXB0CON,RXFUL   ;ready for next
    bcf   COMSTAT,RXB0OVFL  ;clear overflow flags if set
    bcf   COMSTAT,RXB1OVFL
    clrf  PIR3      ;clear all flags
  
    call  clrvar      ;clear variables
    
    ;   test for setup mode
    call  copyEVs
    clrf  Mode
    movlw Modstat     ;get setup status
    movwf EEADR
    call  eeread
    movwf Datmode
    sublw 0       ;not set yet
    bnz   setid
    bra   slimset     ;wait for setup PB
  
    
setid bsf   Mode,1      ;flag FLiM
    call  newid_f     ;put ID into Tx1buf, TXB2 and ID number store
    
  
seten_f 
    movlw B'11000000'
    movwf INTCON      ;enable interrupts
    bsf   PORTB,6   ;Yellow LED on.
    bcf   PORTB,7     
    bcf   Datmode,0
    call  timload     ;load stuff
    goto  main0

slimset bcf   Mode,1
    clrf  NN_temph
    clrf  NN_templ
    ;test for clear all events
    btfss PORTB,DOLEARN   ;ignore the clear if learn is set
    goto  seten
    btfss S_PORT,UNLEARN
    call  initevdata      ;clear all events if unlearn is set during power up
seten
    call  nv_rest     ;if SLiM put default NVs in.
    call  timload     ;Load NV's into RAM
  
    movlw B'11000000'
    movwf INTCON      ;enable interrupts
    bcf   PORTB,6
    bsf   PORTB,7     ;RUN LED on. Green for SLiM
    goto  main0     
  
    

    
;****************************************************************************
;   start of subroutines    
;*************************************************************************


;
;   shuffle for standard ID. Puts 7 bit ID into IDtemph and IDtempl for CAN frame
shuffle movff CanID_tmp,IDtempl   ;get 7 bit ID
    swapf IDtempl,F
    rlncf IDtempl,W
    andlw B'11100000'
    movwf IDtempl         ;has sidl
    movff CanID_tmp,IDtemph
    rrncf IDtemph,F
    rrncf IDtemph,F
    rrncf IDtemph,W
    andlw B'00001111'
    movwf IDtemph         ;has sidh
    return

;*********************************************************************************

;   reverse shuffle for incoming ID. sidh and sidl into one byte.

shuffin movff Rx0sidl,IDtempl
    swapf IDtempl,F
    rrncf IDtempl,W
    andlw B'00000111'
    movwf IDtempl
    movff Rx0sidh,IDtemph
    rlncf IDtemph,F
    rlncf IDtemph,F
    rlncf IDtemph,W
    andlw B'01111000'
    iorwf IDtempl,W     ;returns with ID in W
    return


;************************************************************************************
;   sets an output  
    

;********************************************************************
;   Do an event.  arrives with EV in EVtemp and POL in EVtemp2
;   Toggles outputs. Turns off before on.
;   Checks which outputs are active for the event
;   Checks command for ON or OFF and checks the POL bit for which way to set output

ev_set
    movff Tfdly,OpFdly  ;Reload fire delay counter
    btfss EVtemp,0
    bra   ev_set2   ;no action on pair 1
    btfss Rx0d0,0   ;on or off?
    bra   ev1a
    btfss EVtemp2,0 ;reverse?
    bra   ev1_off
    bra   ev1_on

ev1a  btfss EVtemp2,0
    bra   ev1_on
    bra   ev1_off     

; Process pair 1

ev1_on            ; Output 1 is on, 2 off
    bcf   OpTrig,1  ; Clear other output trigger
    bsf   OpTrig,0  ; Set output trigger
    bra   ev_set2   ; All done for this pair

ev1_off           ; Output 1 is off, 2 is on
    bsf   OpTrig,1  ; Set active output trigger
    bcf   OpTrig,0  ; Clear other output trigger
              ; Drop through

; Process pair 2

ev_set2 btfss EVtemp,1
    bra   ev_set3   ;no action on pair 2
    btfss Rx0d0,0   ;on or off?
    bra   ev2a
    btfss EVtemp2,1 ;reverse?
    bra   ev2_off
    bra   ev2_on

ev2a  btfss EVtemp2,1
    bra   ev2_on
    bra   ev2_off     

ev2_on            ; Output 3 is on, 4 off
    bcf   OpTrig,3  ; Clear other output trigger
    bsf   OpTrig,2  ; Set active output trigger
    bra   ev_set3   ; All done for this pair

ev2_off           ; Output 3 is off, 4 is on
    bsf   OpTrig,3  ; Set active output trigger
    bcf   OpTrig,2  ; Clear other output trigger
              ; Drop through

; Process pair 3

ev_set3 btfss EVtemp,2
    bra   ev_set4   ;no action on pair 3
    btfss Rx0d0,0   ;on or off?
    bra   ev3a
    btfss EVtemp2,2 ;reverse?
    bra   ev3_off
    bra   ev3_on

ev3a  btfss EVtemp2,2
    bra   ev3_on
    bra   ev3_off     

ev3_on            ; Output 5 is on, 6 off
    bcf   OpTrig,5  ; Clear other output trigger
    bsf   OpTrig,4  ; Set active output trigger
    bra   ev_set4   ; All done for this pair

ev3_off           ; Output 5 is off, 6 is on
    bsf   OpTrig,5  ; Set active output trigger
    bcf   OpTrig,4  ; Clear other output trigger
              ; Drop through

; Process pair 4

ev_set4 btfss EVtemp,3
    bra   ev_setx   ;no action on pair 4
    btfss Rx0d0,0   ;on or off?
    bra   ev4a
    btfss EVtemp2,3 ;reverse?
    bra   ev4_off
    bra   ev4_on

ev4a  btfss EVtemp2,3
    bra   ev4_on
    bra   ev4_off     

ev4_on            ; Output 7 is on, 8 off
    bcf   OpTrig,7  ; Clear other output trigger
    bsf   OpTrig,6  ; Set active output trigger
    bra   ev_setx   ; All done for this pair

ev4_off           ; Output 7 is off, 8 is on
    bsf   OpTrig,7  ; Set active output trigger
    bcf   OpTrig,6  ; Clear other output trigger
              ; Drop through

; All done
ev_setx return


;***************************************************************************
;   reloads the timer settings and output masks from EEPROM/Flash to RAM

timload movlw LOW NVstart     ;reloads timers
    movwf EEADR
    lfsr  FSR1,T1a
timloop bsf   EECON1,RD
    movff EEDATA,POSTINC1
    incf  EEADR
    movlw LOW NVstart+.11   ; 8 outputs and 3 timers
    cpfseq  EEADR
    bra   timloop
    movlw HIGH Opmap      ; Opmap is in Flash
    movwf TBLPTRH
    movlw LOW Opmap
    movwf TBLPTRL 
    clrf  TBLPTRU
    movlw 8
    movwf Count
    lfsr  FSR1, Opm1a
opmloop
    tblrd*+
    movff TABLAT, POSTINC1
    decfsz  Count
    bra   opmloop
    return
    
;**************************************************************************
; Clear key variables used for output timing
;**************************************************************************
clrvar  clrf  WREG
    movwf OpTimr        ; Clear working variables
    movwf OpTrig
    movwf OpFlag
    movwf OpFdly
    movwf OpCdly
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
    
;************************************************************************************
;   
eeread  bcf   EECON1,EEPGD  ;read a EEPROM byte, EEADR must be set before this sub.
    bcf   EECON1,CFGS   ;returns with data in W
    bsf   EECON1,RD
    movf  EEDATA,W
    return


;***************************************************************************  

newid_f movlw LOW CANid     ;put in stored ID. FLiM mode
    movwf EEADR
    bsf   EECON1,RD
    movf  EEDATA,W
    movwf CanID_tmp     
    call  shuffle
    movlw B'11110000'
    andwf Tx1sidh
    movf  IDtemph,W   ;set current ID into CAN buffer
    iorwf Tx1sidh     ;leave priority bits alone
    movf  IDtempl,W
    movwf Tx1sidl     ;only top three bits used
    movlw LOW NodeID
    movwf EEADR
    call  eeread
    movwf NN_temph      ;get stored NN
    incf  EEADR
    call  eeread
    movwf NN_templ  
    movlb 15       ;put ID into TXB2 for enumeration response to RTR

new_1 btfsc TXB2CON,TXREQ
    bra   new_1
    clrf  TXB2SIDH
    movf  IDtemph,W
    movwf TXB2SIDH
    movf  IDtempl,W
    movwf TXB2SIDL
    movlw 0xB0
    iorwf TXB2SIDH    ;set priority
    clrf  TXB2DLC     ;no data, no RTR
    movlb 0
  
    return  

;**************************************************************************

;   check if command is for this node

thisNN  movf  NN_temph,W
    subwf Rx0d1,W
    bnz   not_NN
    movf  NN_templ,W
    subwf Rx0d2,W
    bnz   not_NN
    retlw   0     ;returns 0 if match
not_NN  retlw 1


#include "cbuslib/evhndlr.asm"



;**************************************************************************
;   send node parameter bytes (7 maximum)

parasend  
    movlw 0xEF
    movwf Tx1d0
    movlw LOW nodeprm
    movwf TBLPTRL
    movlw 8
    movwf TBLPTRH   ;relocated code
    lfsr  FSR0,Tx1d1
    movlw 7
    movwf Count
    bsf   EECON1,EEPGD
    
para1 tblrd*+
    movff TABLAT,POSTINC0
    decfsz  Count
    bra   para1
    bcf   EECON1,EEPGD  
    movlw 8
    movwf Dlc
    call  sendTXa
    return

;**************************************************************************
;   send module name - 7 bytes

namesend  
    movlw 0xE2
    movwf Tx1d0
    movlw LOW myName
    movwf TBLPTRL
    movlw HIGH myName
    movwf TBLPTRH   ;relocated code
    lfsr  FSR0,Tx1d1
    movlw 7
    movwf Count
    bsf   EECON1,EEPGD
    
name1 tblrd*+
    movff TABLAT,POSTINC0
    decfsz  Count
    bra   name1
    bcf   EECON1,EEPGD  
    movlw 8
    movwf Dlc
    call  sendTXa
    return
    

;**********************************************************

;   send individual parameter

;   Index 0 sends no of parameters

para1rd movf  Rx0d3,w
    sublw 0
    bz    numParams
    movlw PRMCOUNT
    movff Rx0d3, Temp
    decf  Temp
    cpfslt  Temp
    bra   pidxerr
    movlw 0x9B
    movwf Tx1d0
    movlw 7   ;FLAGS index in nodeprm
    cpfseq  Temp
    bra   notFlags      
    call  getflags
    movwf Tx1d4
    bra   addflags
notFlags    
    movlw LOW nodeprm
    movwf TBLPTRL
    movlw HIGH nodeprm
    movwf TBLPTRH   ;relocated code
    clrf  TBLPTRU
    decf  Rx0d3,W
    addwf TBLPTRL
    bsf   EECON1,EEPGD
    tblrd*
    movff TABLAT,Tx1d4
addflags            
    movff Rx0d3,Tx1d3
    movlw 5
    movwf Dlc
    call  sendTX
    return  
    
numParams
    movlw 0x9B
    movwf Tx1d0
    movlw PRMCOUNT
    movwf Tx1d4
    movff Rx0d3,Tx1d3
    movlw 5
    movwf Dlc
    call  sendTX
    return
    
pidxerr
    movlw 10
    call  errsub
    return
    
getflags    ; create flags byte
    movlw PF_CONSUMER
    btfsc Mode,1
    iorlw 4   ; set bit 2
    movwf Temp
    bsf   Temp,3    ;set bit 3, we are bootable
    movf  Temp,w
    return
    
    
;**********************************************************

; returns Node Number, Manufacturer Id, Module Id and Flags

whoami
    call  ldely   ;wait for other nodes
    movlw OPC_PNN
    movwf Tx1d0
    movlw MAN_NO    ;Manufacturer Id
    movwf Tx1d3
    movlw MODULE_ID   ; Module Id
    movwf Tx1d4
    call  getflags
    movwf Tx1d5
    movlw 6
    movwf Dlc
    call  sendTX
    return
    


;*********************************************************************
;   put in NN from command

putNN movff Rx0d1,NN_temph
    movff Rx0d2,NN_templ
    movlw LOW NodeID
    movwf EEADR
    movf  Rx0d1,W
    call  eewrite
    incf  EEADR
    movf  Rx0d2,W
    call  eewrite
    movlw Modstat
    movwf EEADR
    movlw B'00001000'   ;Module status has NN set
    call  eewrite
    return

;***********************************************************

; error message send

errmsg  call  errsub
    goto  main2 
errmsg1 call  errsub
    goto  l_out2
errmsg2 call  errsub
    goto  l_out1

errsub  movwf Tx1d3   ;main eror message send. Error no. in WREG
    movlw 0x6F
    movwf Tx1d0
    movlw 4
    movwf Dlc
    call  sendTX
    return

;sendlog
;   movlw 0xF7
;   movwf Tx1d0
;   movff FSR0H, Tx1d3
;   movff FSR0L, Tx1d4
;   movff EVtemp, Tx1d5
;   movff EVtemp2, Tx1d6
;   clrf  Tx1d7
;   movlw 8
;   movwf Dlc
;   call  sendTX
;   call  ldely
;   return


;*********************************************************************
;   send a CAN frame
;   entry at sendTX puts the current NN in the frame - for producer events
;   entry at sendTXa neeeds Tx1d1 and Tx1d2 setting first
;   Latcount is the number of CAN send retries before priority is increased
;   the CAN-ID is pre-loaded in the Tx1 buffer 
;   Dlc must be loaded by calling source to the data length value
    
sendTX  movff NN_temph,Tx1d1
    movff NN_templ,Tx1d2

sendTXa movf  Dlc,W       ;get data length
    movwf Tx1dlc
    movlw B'00001111'   ;clear old priority
    andwf Tx1sidh,F
    movlw B'10110000'
    iorwf Tx1sidh     ;low priority
    movlw 10
    movwf Latcount
    call  sendTX1     ;send frame
    return

;   Send contents of Tx1 buffer via CAN TXB1

sendTX1 lfsr  FSR0,Tx1con
    lfsr  FSR1,TXB1CON
    
    movlb 15       ;check for buffer access
ldTX2 btfsc TXB1CON,TXREQ ; Tx buffer available...?
    bra   ldTX2     ;... not yet
    movlb 0
    
ldTX1 movf  POSTINC0,W
    movwf POSTINC1  ;load TXB1
    movlw Tx1d7+1
    cpfseq  FSR0L
    bra   ldTX1

    
    movlb 15       ;bank 15
tx1test btfsc TXB1CON,TXREQ ;test if clear to send
    bra   tx1test
    bsf   TXB1CON,TXREQ ;OK so send
    
tx1done movlb 0       ;bank 0
    return          ;successful send

;***************************************************************

    


    
    
;*********************************************************************
;   a delay routine
;   may be used to allow CDU to recharge between succesive outputs.
;   probably needs to be longer for this.
      
dely  movlw 10
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

;****************************************************************

;   longer delay

ldely movlw 100
    movwf Count2
ldely1  call  dely
    decfsz  Count2
    bra   ldely1
    
    return  

;**********************************************************************
;   loads ENs  and EVs from EEPROM to RAM for fast access
;   shifts all 32 even if less are used

en_ram  movlw OLD_EN_NUM
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

ev_ram  movlw OLD_EN_NUM    ;now copy original EVs to RAM
    movwf Count     ;number of ENs allowed 
    bcf   STATUS,C
    rlncf Count     ; 2 EVs per event
    lfsr  FSR0, EV1
    movlw LOW EVstart
    movwf EEADR
ev_load
    bsf   EECON1,RD   ;get first byte
    movf  EEDATA,W
    movwf POSTINC0
    incf  EEADR
    decfsz  Count,F
    bra   ev_load   
    
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

enclear movlw OLD_EN_NUM * 6  ;number of locations in EEPROM
    movwf Count
    movlw LOW ENstart
    movwf EEADR
enloop  movlw 0
    call  eewrite
    incf  EEADR
    decfsz  Count
    bra   enloop
    movlw LOW ENindex + 1
    movwf EEADR
    movlw 0
    call  eewrite
    
    ;now clear shadow ram
    movlw OLD_EN_NUM * 4
    movwf Count
    lfsr  FSR0, EN1
ramloop
    clrf  POSTINC0
    decfsz  Count
    bra   ramloop
    return  
;****************************************************************************

nnack movlw 0x50      ;request frame for new NN or ack if not virgin
nnrel movwf Tx1d0
    movff NN_temph,Tx1d1
    movff NN_templ,Tx1d2
    movlw 3
    movwf Dlc
    call  sendTX
    return

;**************************************************************************

putNV movlw NV_NUM + 1    ;put new NV in EEPROM and the NV ram.
    cpfslt  Rx0d3
    return
    movf  Rx0d3,W
    bz    no_NV
    decf  WREG      ;NVI starts at 1
    addlw LOW NVstart
    movwf EEADR
    movf  Rx0d4,W
  
    call  eewrite 
    
no_NV return

;************************************************************************

getNV movlw NV_NUM + 1    ;get NV from EEPROM and send.
    cpfslt  Rx0d3
    bz    no_NV1
    movf  Rx0d3,W
    bz    no_NV1
    decf  WREG      ;NVI starts at 1
    addlw LOW NVstart
    movwf EEADR
    call  eeread
    movwf Tx1d4     ;NV value
getNV1  movff Rx0d3,Tx1d3   ;NV index
getNV2  movff Rx0d1,Tx1d1
    movff Rx0d2,Tx1d2
    movlw 0x97      ;NV answer
    movwf Tx1d0
    movlw 5
    movwf Dlc
    call  sendTXa
    return

no_NV1  clrf  Tx1d3     ;if not valid NV
    clrf  Tx1d4
    bra   getNV2

nv_rest movlw 8
    movwf Count
    movlw LOW Timers
    movwf Temp
    movwf EEADR
nv_rest1 call eeread
    movwf Temp1
    movlw LOW NVstart - LOW Timers
    addwf EEADR,F
    movf  Temp1,W
    call  eewrite
    decfsz  Count
    bra   nv_rest2
    return
nv_rest2 incf Temp,F
    movf  Temp,W
    movwf EEADR
    bra   nv_rest1



;***************************************************************
;
;   self enumeration as separate subroutine

self_en movff FSR1L,Fsr_tmp1Le  ;save FSR1 just in case
    movff FSR1H,Fsr_tmp1He 
    movlw B'11000000'
    movwf INTCON      ;start interrupts if not already started
    bsf   Datmode,1   ;set to 'setup' mode
    clrf  Tx1con      ;CAN ID enumeration. Send RTR frame, start timer
    movlw 14
    movwf Count
    lfsr  FSR0, Enum0
clr_en
    clrf  POSTINC0
    decfsz  Count
    bra   clr_en
    
    movlw B'10111111'   ;fixed node, default ID  
    movwf Tx1sidh
    movlw B'11100000'
    movwf Tx1sidl
    movlw B'01000000'   ;RTR frame
    movwf Dlc
    
    movlw 0x3C      ;set T3 to 100 mSec (may need more?)
    movwf TMR3H
    movlw 0xAF
    movwf TMR3L
    movlw B'10110001'
    movwf T3CON     ;enable timer 3

    movlw 10
    movwf Latcount
    
    call  sendTXa     ;send RTR frame
    clrf  Tx1dlc      ;prevent more RTR frames

self_en1    btfss PIR2,TMR3IF   ;setup timer out?
    bra   self_en1      ;fast loop till timer out 
    bcf   T3CON,TMR3ON  ;timer off
    bcf   PIR2,TMR3IF   ;clear flag


    clrf  IDcount
    incf  IDcount,F     ;ID starts at 1
    clrf  Roll
    bsf   Roll,0
    lfsr  FSR1,Enum0      ;set FSR to start
here1 incf  INDF1,W       ;find a space
    bnz   here
    movlw 8
    addwf IDcount,F
    incf  FSR1L
    bra   here1
here  movf  Roll,W
    andwf INDF1,W
    bz    here2
    rlcf  Roll,F
    incf  IDcount,F
    bra   here
here2 movlw 100        ;limit to ID
    cpfslt  IDcount
    bra   segful        ;segment full
    
here3 movlw LOW CANid   ;put new ID in EEPROM
    movwf EEADR
    movf  IDcount,W
    call  eewrite
    call  newid_f     ;put new ID in various buffers
;   movlw Modstat
;   movwf EEADR
;   movlw 1
;   call  eewrite     ;set to normal status
;   bcf   Datmode,1   ;out of setup
      
    movff Fsr_tmp1Le,FSR1L  ;
    movff Fsr_tmp1He,FSR1H 
    return

segful  movlw 7   ;segment full, no CAN_ID allocated
    call  errsub
    setf  IDcount
    bcf   IDcount,7
    bra   here3


      
Opmap db  B'00000001',B'10000000'         ;output mapping
    db  B'00000010',B'01000000'         ;don't change this
    db  B'00100000',B'00000100'
    db  B'00010000',B'00001000' 
  
    ORG 0x3000
evdata        
;************************************************************************
  
  ORG 0xF00000      ;EEPROM data. Defaults

CANid de  B'01111111',0 ;CAN id default and module status
NodeID  de  0,0   ;Node ID
ENindex de  0,0   ;ENindex contains free space
          ;ENindex +1 contains number of events
          ;hi byte + lo byte = EN_NUM
          ;initialised in initevdata
    
Timers  de  5,5       ;Timers (for now)
    de  5,5       ;These are for each output
    de  5,5                       
    de  5,5                       
    
FreeCh  de  0,0
hashtab de  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0   
  
    ORG 0xF00020
  
ENstart ;start of 32 event numbers. 128 bytes
    
    ORG 0xF000A0
    
EVstart de  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0   ;event qualifiers
    de  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0   ;clear EEPROM
    de  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    de  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

NVstart
    de  DFFTIM,DFFTIM,DFFTIM,DFFTIM     ;NV 1..4
    de  DFFTIM,DFFTIM,DFFTIM,DFFTIM     ;NV 5..8
    de  DFRDLY,DFFDLY,DFCDLY,0        ;NV 9..11
    de  0,0,0,0               ;NV 12..16
hashnum   
    de  0,0,0,0,0,0,0,0

    ORG 0xF000FE
    de  0,0                 ;for boot.
    
      
    
    end
