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

; Set CONFIG
; NOTE: There seem to be differences in the naming of the CONFIG parameters
;       between versions of the p18F2480.inf files

  CONFIG  FCMEN = OFF, OSC = HSPLL, IESO = OFF
	CONFIG  PWRT = ON,BOREN = BOHW, BORV=0
  CONFIG  WDT=OFF
  CONFIG  MCLRE = ON
  CONFIG  LPT1OSC = OFF, PBADEN = OFF
  CONFIG  DEBUG = OFF
  CONFIG  XINST = OFF,LVP = OFF,STVREN = ON,CP0 = OFF
  CONFIG  CP1 = OFF, CPB = OFF, CPD = OFF,WRT0 = OFF,WRT1 = OFF, WRTB = OFF
  CONFIG  WRTC = OFF,WRTD = OFF, EBTR0 = OFF, EBTR1 = OFF, EBTRB = OFF

; Processor uses 4 MHz resonator with HSPLL to give a clock of 16MHz



;******************************************************************************
; Definitions

  include   "cbuslib/cbusdefs.inc"

MANUFACTURER_ID               equ  MANU_MERG
FIRMWARE_MAJOR_VERSION        equ  2
FIRMWARE_MINOR_VERSION        equ  "r"
MODULE_TYPE                   equ  MTYP_CANACC4_2
OLD_NUMBER_OF_EVENTS          equ  32
NUMBER_OF_EVENTS              equ  128
VARIABLES_PER_EVENT           equ  2
NUMBER_OF_HASH_TABLE_ENTRIES  equ  8
NUMBER_OF_NODE_VARIABLES      equ  16
NODE_FLAGS                    equ  B'00001001'  ; Consumer = Yes, Producer = No,
                                                ; FliM = No, Boot = YES
CPU_TYPE                      equ  P18F2480

MAXIMUM_NUMBER_OF_CAN_IDS equ  100  ; Maximum CAN Ids allowed in a CAN segment


;                            +---+ +---+
;                         RE3|1  |_| 28|RB7 -> Green LED (SLiM)
;  Charge Pump Enable  <- RA0|2      27|RB6 -> Yellow LED (FLiM)
;                         RA1|3      26|RB5 <- Polarity
;                         RA2|4      25|RB4 <- Learn
;                Setup -> RA3|5      24|RB3 <- CAN Rx
;          Charge Pump <- RA4|6      23|RB2 -> CAN Tx
;              Unlearn -> RA5|7      22|RB1 <- Select 1
;                            |8      21|RB0 <- Select 0
;                            |9      20|
;                            |10     19|
;            Output 1a <- RC0|11     18|RC7 -> Output 1b
;            Output 2a <- RC1|12     17|RC6 -> Output 2b
;            Output 3b <- RC2|13     16|RC5 -> Output 3a
;            Output 4b <- RC3|14     15|RC4 -> Output 4a
;                            +---------+

#define  Charge_Pump_Output         PORTA,4  ; CANACC2 charger doubler drive
#define  Charge_Pump_Enable_Output  PORTA,0  ; CANACC2 charger enable
#define  Learn_Input                PORTB,4
#define  Yellow_LED_Output          PORTB,6
#define  Green_LED_Output           PORTB,7
#define  Polarity_Input             PORTB,5
#define  Setup_Input                PORTA,3
#define  Unlearn_Input              PORTA,5

#define  Set_SLiM_LED_On    bsf Green_LED_Output
#define  Set_SLiM_LED_Off   bcf Green_LED_Output
#define  Toggle_SLiM_LED    btg Green_LED_Output
#define  Set_FLiM_LED_On    bsf Yellow_LED_Output
#define  Set_FLiM_LED_Off   bcf Yellow_LED_Output
#define  Toggle_FLiM_LED    btg Yellow_LED_Output

; Defaults
DEFAULT_FIRE_TIME                 equ  5 ; Units of 10mS
DEFAULT_RECHARGE_DELAY            equ 25 ; Units of 10mS
DEFAULT_FIRE_DELAY                equ  0 ; Units of 10mS
DEFAULT_CHARGE_PUMP_ENABLE_DELAY  equ  3 ; Units of 10mS

CHARGE_PUMP_FREQUENCY     equ  100       ; 50, 100 or 200Hz
LP_INTERRUPTS_PER_SECOND  equ  CHARGE_PUMP_FREQUENCY * 2
TIMER1_COUNT              equ  0x10000 - (4000000 / LP_INTERRUPTS_PER_SECOND)

#define  Skip_If_New_Rx_Message      btfss Datmode,0
#define  Skip_If_Not_New_Rx_Message  btfsc Datmode,0
#define  Set_New_Rx_Message          bsf Datmode,0
#define  Unset_New_Rx_Message        bcf Datmode,0
#define  Skip_If_Enumerating         btfss Datmode,1
#define  Skip_If_Not_Enumerating     btfsc Datmode,1
#define  Set_Enumerating             bsf Datmode,1
#define  Unset_Enumerating           bcf Datmode,1
#define  Skip_If_In_Setup            btfss Datmode,2
#define  Skip_If_Not_In_Setup        btfsc Datmode,2
#define  Set_In_Setup                bsf Datmode,2
#define  Unset_In_Setup              bcf Datmode,2
#define  Skip_If_Running             btfss Datmode,3
#define  Skip_If_Not_Running         btfsc Datmode,3
#define  Set_Running                 bsf Datmode,3
#define  Unset_Running               bcf Datmode,3
#define  Skip_If_In_Learn_Mode       btfss Datmode,4
#define  Skip_If_Not_In_Learn_Mode   btfsc Datmode,4
#define  Set_In_Learn_Mode           bsf Datmode,4
#define  Unset_In_Learn_Mode         bcf Datmode,4

#define  Skip_If_FLiM                btfss Mode,1
#define  Set_in_FLiM                 bsf Mode,1
#define  Skip_If_SLiM                btfsc Mode,1
#define  Set_in_SLiM                 bcf Mode,1

#define  Skip_If_Learn               btfsc Learn_Input
#define  Skip_If_Not_Learn           btfss Learn_Input
#define  Skip_If_Unlearn             btfsc Unlearn_Input
#define  Skip_If_Not_Unlearn         btfss Unlearn_Input
#define  Enable_Charge_Pump          bsf Charge_Pump_Enable_Output
#define  Disable_Charge_Pump         bcf Charge_Pump_Enable_Output
#define  Turn_On_Output              iorwf PORTC,F
#define  Turn_Off_Output             andwf PORTC,F


Modstat  equ 1  ; Address in EEPROM

RESET_VECTOR               equ  0x0800
NODE_TYPE_PARAMETERS       equ  0x0810
NODE_PARAMETERS            equ  0x0820
NUMBER_OF_NODE_PARAMETERS  equ  24
AFTER_NODE_PARAMETERS      equ  NODE_PARAMETERS + NUMBER_OF_NODE_PARAMETERS
EVENT_RAM                  equ  0x0100


;******************************************************************************
  include   "cbuslib/boot_loader.inc"
;******************************************************************************


;******************************************************************************
; RAM storage

  CBLOCK  0x0280

  EV1         ;start of EV ram

  ENDC


  CBLOCK  0x0200

  EN1         ;start of EN ram
  EN1a
  EN1b
  EN1c

  EN2
  EN2a
  EN2b
  EN2c

  ENDC


  ; Bank 1 is reserved for use by evhndlr


  CBLOCK  0x0080

  in_use_can_ids ; Bitmap of CAN Ids used by other nodes, needs 14 bytes

  ENDC


  CBLOCK  0x0000

  LPInt_W
  LPInt_STATUS
  LPInt_BSR

  HPInt_FSR1L
  HPInt_FSR1H
  HPInt_FSR2L
  HPInt_FSR2H

  TempCANCON
  TempCANSTAT
  TempINTCON
  Datmode     ;flag for data waiting
  loop_counter     ;counter for loading
  loop_counter1
  loop_counter2

  DNindex   ;holds number of allowed DNs
  Match   ;match flag

  ENcount   ;which EN matched
  ENcount1
  event_variable_1
  event_variable_2
  copy_of_event_variable_1

  received_can_id          ; CAN Id received whilst self enumerating
  received_can_id_bitmask  ; Rolling bitmask to record received CAN Id
  unused_can_id            ; CAN Id available for self enumeration
  unused_can_id_bitmask    ; Rolling bitmask to find unused CAN Id

  Latcount
  Mode    ;for FLiM / SLiM etc
  Mask
  Shift
  Shift1

  Temp      ;temps
  Temp1
  CanID_tmp ;temp for CAN Node ID
  IDtemph   ;used in ID shuffle
  IDtempl
  node_number_high    ;node number in RAM
  node_number_low
  ENtemp1     ;number of events

  Rx_sidh   ; Start of received frame
  Rx_sidl
  Rx_eidh
  Rx_eidl
  Rx_dlc
  Rx_d0
  Rx_d1
  Rx_d2
  Rx_d3
  Rx_d4
  Rx_d5
  Rx_d6
  Rx_d7

  Tx_sidh   ; Start of frame to transmit
  Tx_sidl
  Tx_eidh
  Tx_eidl
  Tx_dlc
  Tx_d0
  Tx_d1
  Tx_d2
  Tx_d3
  Tx_d4
  Tx_d5
  Tx_d6
  Tx_d7

  output_pulse_timer    ; Output timer (countdown)
  output_trigger_bits    ; Output channel trigger mask
  output_off_bitmask    ; Output flags  Timout    ;used in timer routines
  output_interval_timer    ; Output fire delay
  charge_pump_delay_timer    ; Output charge delay
  low_priority_interrupt_counter    ; LPint Counter

  output_1a_pulse_time     ;timer registers for each output
  output_1b_pulse_time
  output_2a_pulse_time
  output_2b_pulse_time
  output_3a_pulse_time
  output_3b_pulse_time
  output_4a_pulse_time
  output_4b_pulse_time
  output_recharge_time   ; Recharge Time. Must follow output_4b_pulse_time
  output_interval_duration   ; Fire delay. Must follow output_recharge_time
  charge_pump_delay_time   ; Charge delay. Must follow output_interval_duration
  ;End of timer values

  output_1a_mask   ; Mask for output 1a
  output_1b_mask   ; Mask for output 1b
  output_2a_mask   ; Mask for output 2a
  output_2b_mask   ; Mask for output 2b
  output_3a_mask   ; Mask for output 3a
  output_3b_mask   ; Mask for output 3b
  output_4a_mask   ; Mask for output 4a
  output_4b_mask   ; Mask for output 4b

  ;variables used by Flash Ram event handling

  current_event_address_high
  current_event_address_low
  previous_event_address_high
  previous_event_address_low
  next_event_address_high
  next_event_address_low
  current_event_list_head_high
  current_event_list_head_low
  current_hashtable_entry
  current_hash_number
  current_free_entry_address_high
  current_free_entry_address_low
  initFlags   ; used in intialising Flash from EEPROM events
  saved_FSR0L
  saved_FSR0H
 
  received_opcode
  ev0
  ev1
  ev2
  ev3
  event_variable_index   ; EV index from learn cmd
  event_variable_value    ; EV data from learn cmd

  event_index   ; event index from commands which access events by index
  flash_access_counter_0  ; counters used by Flash handling
  flash_access_counter_1

  ENDC



;******************************************************************************
;
;   Start of program code

  ORG     RESET_VECTOR
  nop           ;for debug
  bra     setup


  ORG     NODE_TYPE_PARAMETERS
node_type_name
  db      "ACC4_2 "


  ORG   NODE_PARAMETERS
node_parameters
	db      MANUFACTURER_ID, FIRMWARE_MINOR_VERSION, MODULE_TYPE, NUMBER_OF_EVENTS
	db      VARIABLES_PER_EVENT, NUMBER_OF_NODE_VARIABLES
	db      FIRMWARE_MAJOR_VERSION, NODE_FLAGS, CPU_TYPE, PB_CAN
	dw      RESET_VECTOR  ; Load address for module code above bootloader
	dw      0             ; Top 2 bytes of 32 bit load address, not used

unused_node_parameters
  fill 0,AFTER_NODE_PARAMETERS - $ ; Zero fill unused parameter space

NODE_PARAMETER_COUNT  equ  unused_node_parameters - node_parameters

NODE_PARAMETER_CHECKSUM  set                           MANUFACTURER_ID
NODE_PARAMETER_CHECKSUM  set NODE_PARAMETER_CHECKSUM + FIRMWARE_MINOR_VERSION
NODE_PARAMETER_CHECKSUM  set NODE_PARAMETER_CHECKSUM + MODULE_TYPE
NODE_PARAMETER_CHECKSUM  set NODE_PARAMETER_CHECKSUM + NUMBER_OF_EVENTS
NODE_PARAMETER_CHECKSUM  set NODE_PARAMETER_CHECKSUM + VARIABLES_PER_EVENT
NODE_PARAMETER_CHECKSUM  set NODE_PARAMETER_CHECKSUM + NUMBER_OF_NODE_VARIABLES
NODE_PARAMETER_CHECKSUM  set NODE_PARAMETER_CHECKSUM + FIRMWARE_MAJOR_VERSION
NODE_PARAMETER_CHECKSUM  set NODE_PARAMETER_CHECKSUM + NODE_FLAGS
NODE_PARAMETER_CHECKSUM  set NODE_PARAMETER_CHECKSUM + CPU_TYPE
NODE_PARAMETER_CHECKSUM  set NODE_PARAMETER_CHECKSUM + PB_CAN
NODE_PARAMETER_CHECKSUM  set NODE_PARAMETER_CHECKSUM + high node_type_name
NODE_PARAMETER_CHECKSUM  set NODE_PARAMETER_CHECKSUM + low node_type_name
NODE_PARAMETER_CHECKSUM  set NODE_PARAMETER_CHECKSUM + high RESET_VECTOR
NODE_PARAMETER_CHECKSUM  set NODE_PARAMETER_CHECKSUM + low RESET_VECTOR
NODE_PARAMETER_CHECKSUM  set NODE_PARAMETER_CHECKSUM + NODE_PARAMETER_COUNT


  ORG AFTER_NODE_PARAMETERS
  dw  NODE_PARAMETER_COUNT     ; Number of parameters implemented
  dw  node_type_name           ; Pointer to module type name
  dw  0                        ; Top 2 bytes of 32 bit address not used
  dw  NODE_PARAMETER_CHECKSUM  ; Checksum of parameters



;******************************************************************************
;   High priority interrupt. Used for CAN receive and transmit error.

high_priority_interrupt_routine
  movff   CANSTAT, TempCANSTAT

	; Save registers to protect during interrupt
	movff   FSR2L, HPInt_FSR2L
	movff   FSR2H, HPInt_FSR2H
	movff   FSR1L, HPInt_FSR1L
	movff   FSR1H, HPInt_FSR1H

  movlw high cstatab
  movwf PCLATH
  movf  TempCANSTAT,W
  andlw B'00001110'
  addwf PCL,F

cstatab
  bra   exit_high_priority_interrupt
  bra   errint
  bra   exit_high_priority_interrupt
  bra   exit_high_priority_interrupt
  bra   exit_high_priority_interrupt
  bra   copy_rx_buffer1
  bra   copy_rx_buffer0
  bra   exit_high_priority_interrupt


  ; Error handling here, only acts on lost Tx arbitration
errint
  movlb   15                            ; Select RAM bank 15
  btfss   TXB1CON, TXLARB
  bra     exit_error_interrupt

  decfsz  Latcount,F
  bra     exit_error_interrupt

  movlw   B'00111111'
  andwf   TXB1SIDH,F                    ; Change priority of transmitted frame

exit_error_interrupt
  bcf     RXB1CON, RXFUL
  movlb   0                             ; Select RAM bank 0
  bcf     RXB0CON, RXFUL
  bcf     COMSTAT, RXB0OVFL
  bcf     COMSTAT, RXB1OVFL
  bra     exit_high_priority_interrupt

copy_rx_buffer1
  bcf     PIR3, RXB1IF
  lfsr    FSR1, RXB1D7                  ; Source for received buffer copy
  bra     copy_rx_buffer

copy_rx_buffer0
  bcf     PIR3, RXB0IF
  lfsr    FSR1, RXB0D7                  ; Source for received buffer copy

copy_rx_buffer
  ; Copy relevant Rx buffer into working RAM
  lfsr    FSR2, Rx_d7                   ; Destination for received buffer copy

unload_rx_buffer
  movff   POSTDEC1, POSTDEC2
  movlw   Rx_sidh                       ; Test for end of Rx copy ...
  cpfseq  FSR2L                         ; ... skip if reached ...
  bra     unload_rx_buffer              ; ... else keep copying

  movff   POSTDEC1, INDF2               ; Copy last byte
  bcf     INDF1, RXFUL                  ; Mark Rx buffer available for use

  btfsc   Rx_dlc, RXRTR                 ; Skip if not received an RTR
  bra     respond_to_RTR

  Skip_If_Not_Enumerating
  bra     record_received_can_id

  movf    Rx_dlc,F                      ; Test length of received data ...
  btfss   STATUS, Z                     ; ... do nothing if zero

  Skip_If_New_Rx_Message
  Set_New_Rx_Message

#ifdef AUTOID
  ; Include automatic CAN ID enumeration (may cause problems with CANCAN)
  Skip_If_FLiM
  bra     exit_high_priority_interrupt  ; Don't do Can ID check if SLiM mode

  ; Check for ID conflict
  movf    Rx_sidh,W
  xorwf   Tx_sidh,W
  andlw   0x0f
  bnz     exit_high_priority_interrupt

  movf    Rx_sidl,W
  xorwf   Tx_sidl,W
  andlw   0xe0
  bnz     exit_high_priority_interrupt

  bsf     Datmode, MD_IDCONF
#endif

exit_high_priority_interrupt
  movlw   B'00000011'
  andwf   PIR3                          ; Clear all but Rx interrupt flags

  ; Restore registers to protected during interrupt
  movff   HPInt_FSR1L, FSR1L
  movff   HPInt_FSR1H, FSR1H
  movff   HPInt_FSR2L, FSR2L
  movff   HPInt_FSR2H, FSR2H

  retfie  1                             ; Restore from shadow registers


respond_to_RTR
  Skip_If_Not_Enumerating
  bra     exit_high_priority_interrupt

  Skip_If_FLiM
  bra     exit_high_priority_interrupt

  movlb   15                            ; Select RAM bank 15

RTR_response_Tx_wait
  btfsc   TXB2CON, TXREQ
  bra     RTR_response_Tx_wait

  bsf     TXB2CON, TXREQ
  movlb   0                             ; Select RAM bank 0
  bra     exit_high_priority_interrupt


record_received_can_id
  tstfsz  Rx_dlc                        ; Only zero length frames for setup
  bra     exit_high_priority_interrupt

  ; Get received CAN Id into a single byte
  swapf   Rx_sidh,W
  rrcf    WREG
  andlw   B'01111000'
  movwf   Temp
  swapf   Rx_sidl,W
  rrncf   WREG
  andlw   B'00000111'
  iorwf   Temp,W
  movwf   received_can_id

  lfsr    FSR1, in_use_can_ids          ; Reference used CAN Id bitmask table
  clrf    received_can_id_bitmask       ; Initialise bitmask ...
  bsf     received_can_id_bitmask,0     ; ... to 0000 0001
  movlw   8                             ; Bits in each bitmask table byte

find_received_can_id_byte
  cpfsgt  received_can_id               ; Skip if CAN Id greater than eight ...
  bra     find_received_can_id_bit      ; ... else found byte, now find bit

  subwf   received_can_id,F             ; Reduce received CAN Id by eight
  incf    FSR1L                         ; Move on to next byte in bitmap table
  bra     find_received_can_id_byte

find_received_can_id_bit
  dcfsnz  received_can_id,F
  bra     found_received_can_id_bit

  rlncf   received_can_id_bitmask,F     ; Shift bitmask one bit left
  bra     find_received_can_id_bit

found_received_can_id_bit
  movf    received_can_id_bitmask,W     ; Set bit for received CAN Id ...
  iorwf   INDF1,F                       ; ... in bitmap table
  bra     exit_high_priority_interrupt



;******************************************************************************
;   Low priority interrupt. Used by output timer overflow.

low_priority_interrupt_routine
  ; Save registers to protect during interrupt
  movff   STATUS, LPInt_STATUS
  movff   BSR, LPInt_BSR
  movwf   LPInt_W

  movlw   low TIMER1_COUNT
  movwf   TMR1L
  clrf    PIR1                          ; Clear all timer flags

  movf    charge_pump_delay_timer,W
  btfsc   STATUS, Z                     ; Skip if charge pump delay is running
  btg     Charge_Pump_Output

  ; If necessary scale down interrupt frequncy to give 10 mSec intervals for
  ; output timing.
#if CHARGE_PUMP_FREQUENCY > 50
  incf    low_priority_interrupt_counter,F
  btfsc   low_priority_interrupt_counter,0
  bra     exit_low_priority_interrupt
#if CHARGE_PUMP_FREQUENCY >= 200
  btfsc   low_priority_interrupt_counter,1
  bra     exit_low_priority_interrupt
#endif ; if CHARGE_PUMP_FREQUENCY >= 200
#endif ; if CHARGE_PUMP_FREQUENCY > 50

  ; We get here once every 10mS, no matter what interrupt frequency is in use

  ; Time interval between output pulses
  movf    output_interval_timer,W
  btfss   STATUS, Z                     ; Skip if timer not running
  decf    output_interval_timer,F

  ; Time delay before charge pump runs
  movf    charge_pump_delay_timer,W
  btfss   STATUS, Z                     ; Skip if timer not running
  decf    charge_pump_delay_timer,F

  ; Time output pulse or recharge
  movf    output_pulse_timer,W
  bz      do_next_trigger               ; Jump if timer not running

  decfsz  output_pulse_timer,F
  bra     exit_low_priority_interrupt

  ; Time to end output pulse
  Enable_Charge_Pump
  movf    output_off_bitmask,W
  bz      do_next_trigger               ; Jump if no output to turn off

  Turn_Off_Output
  clrf    output_off_bitmask

  movf    output_recharge_time,W
  bz      do_next_trigger         

  movwf   output_pulse_timer
  bra     exit_low_priority_interrupt


  ; Find next bit to trigger
do_next_trigger
  movf    output_trigger_bits,F         ; Check trigger bitmap
  bz      exit_low_priority_interrupt   ; Jump if not outputs to trigger

  movf    output_interval_timer,F       ; Check interval between output pulses
  bnz     exit_low_priority_interrupt   ; Jump if not expired

Trigger_Output macro trigger_bit, other_mask, output_mask, pulse_time,
  local not_this_output

  btfss   output_trigger_bits, trigger_bit
  bra     not_this_output

  bcf     output_trigger_bits, trigger_bit
  comf    other_mask,W                  ; Inverted mask for other output of pair
  Turn_Off_Output
  movf    output_mask,W
  Turn_On_Output

  movf    pulse_time,W
  bz      exit_low_priority_interrupt   ; If time is zero output is steady state
  movwf   output_pulse_timer

  comf    output_mask,W                 ; Inverted mask for output of pair
  movwf   output_off_bitmask
  bra     end_of_triggering

not_this_output
  endm

  Trigger_Output 0, output_1b_mask, output_1a_mask, output_1a_pulse_time
  Trigger_Output 1, output_1a_mask, output_1b_mask, output_1b_pulse_time
  Trigger_Output 2, output_2b_mask, output_2a_mask, output_2a_pulse_time
  Trigger_Output 3, output_2a_mask, output_2b_mask, output_2b_pulse_time
  Trigger_Output 4, output_3b_mask, output_3a_mask, output_3a_pulse_time
  Trigger_Output 5, output_3a_mask, output_3b_mask, output_3b_pulse_time
  Trigger_Output 6, output_4b_mask, output_4a_mask, output_4a_pulse_time
  Trigger_Output 7, output_4a_mask, output_4b_mask, output_4b_pulse_time

end_of_triggering
  Disable_Charge_Pump
  movf    output_pulse_timer,W
  addwf   charge_pump_delay_time,W
  movwf   charge_pump_delay_timer

exit_low_priority_interrupt
  ; Restore registers to protected during interrupt
  movf    LPInt_W,W
  movff   LPInt_BSR, BSR
  movff   LPInt_STATUS, STATUS

  retfie



;******************************************************************************
; Main processing loop

main_loop
  Skip_If_SLiM
  bra     FLiM_main_loop

  ; SLiM main loop
  btfss   PIR2, TMR3IF
  bra     check_for_mode_switch

  bcf     PIR2, TMR3IF
  Toggle_SLiM_LED
  bra     check_for_mode_switch

FLiM_main_loop
  btfss   INTCON, TMR0IF
  bra     check_for_mode_switch

  bcf     INTCON, TMR0IF
  Skip_If_Not_In_Setup
  Toggle_FLiM_LED


check_for_mode_switch
  btfsc   Setup_Input         ; Skip if button pressed
  bra     no_mode_switch

  movlw   100
  movwf   loop_counter
  clrf    loop_counter1
  clrf    loop_counter2

wait_before_switching_mode
  decfsz  loop_counter2
  bra     wait_before_switching_mode

  Skip_If_In_Setup
  bra     do_not_flash_FLiM_led

  btfss   INTCON, TMR0IF
  bra     do_not_flash_FLiM_led

  bcf     INTCON, TMR0IF
  Toggle_FLiM_LED

do_not_flash_FLiM_led
  decfsz  loop_counter1
  bra     wait_before_switching_mode

  btfsc   Setup_Input         ; Skip if button pressed
  bra     abandon_mode_switch ; Button released too soon

  decfsz  loop_counter
  bra     wait_before_switching_mode

  Skip_If_FLiM
  bra     start_switch_to_FLiM

  ; Start switch to SLiM
  clrf    Datmode
  Set_FLiM_LED_Off
  Set_SLiM_LED_On
  clrf    INTCON              ; Disable interrupts
  movlw   1
  movwf   received_can_id
  movlw   Modstat
  movwf   EEADR
  movlw   0
  call    write_ee             ; Persist SLiM setting to EEPROM

  movlw   OPC_NNREL           ; Send Node Number release
  call    tx_without_data
  clrf    node_number_high
  clrf    node_number_low

wait_to_switch_mode
  btfss   Setup_Input
  bra     wait_to_switch_mode

  call    long_delay
  btfss   Setup_Input         ; Skip if button released
  bra     wait_to_switch_mode

  ; Setup button has been released, finish switching mode
  movlw   low NodeID
  movwf   EEADR
  movlw   0
  call    write_ee
  incf    EEADR
  movlw   0
  call    write_ee

  ; Enable high and low priority interrupts
  movlw   B'11000000'
  movwf   INTCON

  Skip_If_FLiM
  bra     switch_to_FLiM

  ; Switch to SLiM
  movlw   Modstat
  movwf   EEADR
  movlw   0
  call    write_ee
  clrf    Datmode
  Set_in_SLiM
  Set_FLiM_LED_Off
  Set_SLiM_LED_On
  bra     main_loop

start_switch_to_FLiM
  Set_Enumerating
  Set_SLiM_LED_Off
  bra     wait_to_switch_mode

switch_to_FLiM
  movlw   Modstat
  movwf   EEADR
  movlw   1
  call    write_ee             ; Persist FLiM setting to EEPROM
  Set_in_FLiM

restart_FLiM
  call    self_enumerate
  call    request_new_node_number
  Set_In_Setup
  bra     check_for_received_message

abandon_mode_switch
  Skip_If_In_Setup
  bra     restart_FLiM

  Unset_In_Setup
  Set_FLiM_LED_On
  call    send_node_number_acknowledge
  movlw   Modstat
  movwf   EEADR
  movlw   B'00001000'
  movwf   Datmode
  call    write_ee

no_mode_switch
  Skip_If_Enumerating
  bra     check_for_received_message

  Unset_Enumerating
  Set_In_Setup


check_for_received_message
  Skip_If_New_Rx_Message
  bra     main_loop

  movff   Rx_d0, received_opcode
  movff   Rx_d1, ev0
  movff   Rx_d2, ev1
  movff   Rx_d3, ev2
  movff   Rx_d4, ev3
  movff   Rx_d5, event_variable_index
  movff   Rx_d6, event_variable_value
  Unset_New_Rx_Message

;  Process received messages valid in both SLiM and FLiM

  movlw   OPC_ACON
  subwf   received_opcode,W
  bz      process_long_event

  movlw   OPC_ACOF
  subwf   received_opcode,W
  bz      process_long_event

  movlw   OPC_ASON
  subwf   received_opcode,W
  bz      process_short_event

  movlw   OPC_ASOF
  subwf   received_opcode,W
  bz      process_short_event

  movlw   OPC_RQNPN
  subwf   received_opcode,W
  bz      read_node_parameter

  movlw   OPC_RQNP
  subwf   received_opcode,W
  bz      read_key_node_parameters

  movlw   OPC_RQMN
  subwf   received_opcode,W
  bz      read_name

  movlw   OPC_BOOT
  subwf   received_opcode,W
  bz      reboot

  movlw   OPC_QNN
  subwf   received_opcode,W
  bz      respond_to_query_node

  Skip_If_SLiM
  bra     flim_process_received_message

  bra     main_loop



;******************************************************************************
process_short_event
  clrf    ev0
  clrf    ev1

process_long_event
  Skip_If_SLiM
  bra     process_event

  Skip_If_Learn
  bra     process_event

  call    find_event
  bz      found_event

  Skip_If_Not_Unlearn
  bra     main_loop

  call    learn_event
  sublw   0
  bz      process_event

  movlw   CMDERR_TOO_MANY_EVENTS
  bra     abort_and_send_error_message

found_event
  Skip_If_Unlearn
  bra     update_event

  call    forget_event
  bra     main_loop

update_event
  call    learn_event

process_event
  call    find_event
  btfss   STATUS, Z
  bra     main_loop

  call    fetch_event_data
  movff   POSTINC0, event_variable_1
  movff   POSTINC0, event_variable_2
  call    action_event
  bra     main_loop



;******************************************************************************
read_node_parameter
  call    is_message_for_this_node    ; Check message addressed to this node
  btfsc   STATUS, Z
  call    send_node_parameter
  bra     main_loop



;******************************************************************************
read_key_node_parameters
  Skip_If_Not_In_Setup
  call    send_key_node_parameters
  bra     main_loop



;******************************************************************************
read_name
  Skip_If_Not_In_Setup
  call    send_name
  bra     main_loop



;******************************************************************************
reboot
  Skip_If_FLiM
  bra     slim_reboot
  call    is_message_for_this_node
  btfss   STATUS, Z
  bra     main_loop

do_reboot
  movlw   0xFF
  movwf   EEADR
  movlw   0xFF
  call    write_ee
  reset

slim_reboot
  movf    ev0,W
  addwf   ev1,W
  bz      do_reboot
  bra     main_loop



;******************************************************************************
respond_to_query_node
  movf    node_number_high,W
  addwf   node_number_low,W
  btfsc   STATUS, Z
  bra     main_loop

  ; Send Node Number, Manufacturer Id, Module Id and Flags
  call    long_delay        ; Allow time for other nodes to also respond
  movlw   OPC_PNN
  movwf   Tx_d0
  movlw   MANUFACTURER_ID
  movwf   Tx_d3
  movlw   MODULE_TYPE
  movwf   Tx_d4
  call    get_flags
  movwf   Tx_d5
  movlw   6
  movwf   Tx_dlc
  call    tx_with_node_number

  bra     main_loop



;******************************************************************************
;  Process received messages only valid in FLiM

flim_process_received_message
  movlw   OPC_SNN
  subwf   received_opcode,W
  bz      set_node_number

  Skip_If_In_Learn_Mode
  bra     check_if_addressed_message

  movlw   OPC_EVULN
  subwf   received_opcode,W
  bz      unlearn_event

  movlw   OPC_EVLRN
  subwf   received_opcode,W
  bz      learn_event_and_variable

  movlw   OPC_REQEV
  subwf   received_opcode,W
  bz      read_event_variable

check_if_addressed_message
  call    is_message_for_this_node
  btfsc   STATUS, Z
  bra     flim_process_addressed_message
  bra     main_loop



;******************************************************************************
set_node_number
  Skip_If_In_Setup
  bra     main_loop

  movff   ev0, node_number_high
  movff   ev1, node_number_low

  movlw   low NodeID
  movwf   EEADR
  movf    node_number_high,W
  call    write_ee
  incf    EEADR
  movf    node_number_low,W
  call    write_ee

  movlw   Modstat
  movwf   EEADR
  movlw   B'00001000'       ; Module status = Node Number is set
  call    write_ee

  Unset_In_Setup
  Set_Running
  call    send_node_number_acknowledge
  Set_SLiM_LED_Off
  Set_FLiM_LED_On
  bra     main_loop



;******************************************************************************
unlearn_event
  call    find_event
  btfss   STATUS, Z
  bra     main_loop

  call    forget_event
  movlw   OPC_WRACK
  call    tx_without_data
  bra     main_loop



;******************************************************************************
learn_event_and_variable
  movf    event_variable_index,W
  bz      event_variable_index_invalid

  decf    event_variable_index  ; Convert index to offset
  movlw   VARIABLES_PER_EVENT
  cpfslt  event_variable_index
  bra     event_variable_index_invalid

  call    learn_event
  sublw   0
  btfsc   STATUS, Z
  bra     process_event

  movlw   CMDERR_TOO_MANY_EVENTS
  bra     abort_and_send_error_message



;******************************************************************************
read_event_variable
  movff   event_variable_index, Tx_d5   ; Save to echo back in response
  movf    event_variable_index,W
  bz      event_variable_index_invalid

  decf    event_variable_index          ; Convert from index to offset
  movlw   VARIABLES_PER_EVENT
  cpfslt  event_variable_index
  bra     event_variable_index_invalid

  call    find_event
  bnz     no_event_to_read

  call    fetch_event_data
  movf    event_variable_index,W
  movff   PLUSW0, Tx_d6
  movlw   OPC_EVANS
  movwf   Tx_d0
  movff   ev0, Tx_d1
  movff   ev1, Tx_d2
  movff   ev2, Tx_d3
  movff   ev3, Tx_d4
  movlw   7
  movwf   Tx_dlc
  call    tx_message
  bra     main_loop


no_event_to_read
  movlw   CMDERR_NO_EV
  call    send_error_message
  bra     main_loop




;******************************************************************************
event_variable_index_invalid
  movlw   CMDERR_INV_EV_IDX
  bra     abort_and_send_error_message



;******************************************************************************
;  Process received messages only valid in FLiM and addressed to this node

flim_process_addressed_message
  movlw   OPC_CANID
  subwf   received_opcode,W
  bz      set_link_id

  movlw   OPC_ENUM
  subwf   received_opcode,W
  bz      force_self_enumeration

  movlw   OPC_NNLRN
  subwf   received_opcode,W
  bz      enter_learn_mode

  movlw   OPC_NNULN
  subwf   received_opcode,W
  bz      exit_learn_mode

  movlw   OPC_NNCLR
  subwf   received_opcode,W
  bz      clear_all_events

  movlw   OPC_NNEVN
  subwf   received_opcode,W
  bz      read_free_event_space

  movlw   OPC_RQEVN
  subwf   received_opcode,W
  bz      read_number_of_events

  movlw   OPC_NERD
  subwf   received_opcode,W
  bz      read_all_events

  movlw   OPC_NENRD
  subwf   received_opcode,W
  bz      read_indexed_event

  movlw   OPC_REVAL
  subwf   received_opcode,W
  bz      read_indexed_event_and_variable

  movlw   OPC_NVSET
  subwf   received_opcode,W
  bz      set_node_variable

  movlw   OPC_NVRD
  subwf   received_opcode,W
  bz      read_node_variable

  bra     main_loop



;******************************************************************************
set_link_id
  movff   ev2, unused_can_id
  call    update_link_id
  call    send_node_number_acknowledge
  bra     main_loop



;******************************************************************************
force_self_enumeration
  call    self_enumerate
  call    send_node_number_acknowledge
  bra     main_loop



;******************************************************************************
enter_learn_mode
  Set_In_Learn_Mode
  Set_FLiM_LED_On
  bra     main_loop



;******************************************************************************
exit_learn_mode
  Unset_In_Learn_Mode
  bra     main_loop



;******************************************************************************
clear_all_events
  movlw   CMDERR_NOT_LRN
  Skip_If_In_Learn_Mode
  bra     abort_and_send_error_message

  call    initialise_event_data
  movlw   OPC_WRACK
  call    tx_without_data
  bra     main_loop



;******************************************************************************
read_free_event_space
  call    send_free_event_space
  bra     main_loop



;******************************************************************************
read_number_of_events
  call    send_number_of_events
  bra     main_loop



;******************************************************************************
read_all_events
  call    send_all_events
  bra     main_loop



;******************************************************************************
read_indexed_event
  movff   ev2, event_index
  call    send_indexed_event
  bra     main_loop



;******************************************************************************
read_indexed_event_and_variable
  movff   ev2, event_index
  movff   ev3, event_variable_index
  call    send_indexed_event_and_variable
  bra     main_loop



;******************************************************************************
;  Set a node variable by index

set_node_variable
  call    store_indexed_node_variable
  call    reload_timers
  bra     main_loop



;******************************************************************************
read_node_variable
  movlw   NUMBER_OF_NODE_VARIABLES + 1
  cpfslt  ev2
  bz      node_variable_index_invalid

  movf    ev2,W
  bz      node_variable_index_invalid

  decf    WREG                  ; Convert index to offset
  addlw   low node_variables
  call    read_ee_at_address
  movwf   Tx_d4

  movff   ev2, Tx_d3            ; Echo back requested node variable index

send_node_variable
  movff   ev0, Tx_d1            ; Echo back Node Number high
  movff   ev1, Tx_d2            ; Echo back Node Number low
  movlw   OPC_NVANS
  movwf   Tx_d0
  movlw   5
  movwf   Tx_dlc
  call    tx_message
  bra     main_loop

node_variable_index_invalid
  clrf    Tx_d3                 ; Return Node Variable index of zero
  clrf    Tx_d4                 ; Return Node Variable value of zero
  bra     send_node_variable



;******************************************************************************
;   Send error message and end processing of received message
;     Error number to return is in W
abort_and_send_error_message
  call  send_error_message
  bra   main_loop



;******************************************************************************
;   Check if received message was addressed to this node
;     Zero status on return indicates match

is_message_for_this_node
  movf    node_number_high,W
  subwf   ev0,W
  btfss   STATUS, Z       ; Skip if match ...
  return                  ; ... else return with non zero status

  movf    node_number_low,W
  subwf   ev1,W

  return



;******************************************************************************
;   Main setup routine

setup
  clrf    INTCON            ; Ensure interrupts are disabled

  lfsr    FSR0,0

clear_ram_loop
  clrf    POSTINC0
  btfss   FSR0L,7           ; Clear first 128 bytes of RAM
  bra     clear_ram_loop

  movlw   1
  movwf   received_can_id

  clrf    ADCON0            ; Turn off A/D, all I/O digital
  movlw   B'00001111'
  movwf   ADCON1

  ; Port settings will be hardware dependent. RB2 and RB3 are for CAN.

  movlw   B'00101000'       ; PortA bit 3, setup pushbutton input
                            ;       bit 5, unlearn switch input
  movwf   TRISA
  movlw   B'00111011'       ; PortB bit 0 1, select inputs
                            ;       bit 3, CAN Rx input
                            ;       bit 4, learn switch input
                            ;       bit 5, polarity switch input
  movwf   TRISB             ; Pullups enabled on PORTB inputs
  Set_FLiM_LED_Off
  Set_SLiM_LED_Off
  bsf     PORTB, CANTX      ; Initalise CAN Tx as recessive
  clrf    TRISC             ; Port C all outputs
  clrf    PORTC

  bsf     RCON, IPEN        ; Enable interrupt priority levels
  clrf    BSR               ; Select RAM bank 0
  clrf    EECON1            ; Disable accesses to program memory
  clrf    ECANCON           ; CAN mode 0, legacy

  bsf     CANCON,7          ; CAN module into configure mode
  movlw   B'00000011'       ; Bit rate 125, 000
  movwf   BRGCON1

  movlw   B'10011110'       ; Phase Segment 2 Time Freely Programmable
                            ; Bus sampled once at sample point
                            ; Phase Segment 1 Time 4 x Tq
                            ; Propogation Time 7 x Tq
  movwf   BRGCON2

  movlw   B'00000011'       ; Enable bus activity wake up
                            ; Bus filter not used for wake up
                            ; Phase Segment 2 Time 4 x Tq
  movwf   BRGCON3

  movlw   B'00100000'       ; CAN Tx to Vdd when recesive
                            ; Disable message capture
  movwf   CIOCON

  movlw   B'00100100'       ; Receive valid messages with standard identifier
                            ; Enable double buffer
                            ; Allow jump table offset between 1 and 10
                            ; Enable acceptance filter 0
  movwf   RXB0CON           ; Configure Rx buffer 0

  movlb   15                ; Select RAM bank 15
  movlw   B'00100000'       ; Receive valid messages with standard identifier
  movwf   RXB1CON           ; Configure Rx buffer 1

  clrf    RXF0SIDL
  clrf    RXF1SIDL
  movlb   0                 ; Select RAM bank 0

  lfsr    FSR0, RXM0SIDH    ; Clear Rx acceptance masks

clear_rx_masks_loop
  clrf    POSTINC0
  movlw   low RXM1EIDL + 1
  cpfseq  FSR0L
  bra     clear_rx_masks_loop

  clrf    CANCON            ; CAN module out of configure mode

  bcf     COMSTAT, RXB0OVFL ; Ensure overflow flags are clear
  bcf     COMSTAT, RXB1OVFL

  clrf    CCP1CON           ; Disable capture, compare, or pwm

  ; Enable Timer0, 16 bit, 1:32 prescaler, internal clock
  movlw   B'10000100'
  movwf   T0CON

  ; Enable Timer1, 16 bit write, no prescaler,  no oscillator, internal clock
  movlw   B'10000001'
  movwf   T1CON
  movlw   high TIMER1_COUNT
  movwf   TMR1H

  ; High priority interrupt for CAN Tx error and Rx, anything else low priority
  clrf    IPR1
  clrf    IPR2
  movlw   B'00100011'
  movwf   IPR3

  ; Enable interrupts from Timer1, CAN Tx error, CAN Rx
  movlw   B'00000001'
  movwf   PIE1
  clrf    PIE2
  movlw   B'00100011'
  movwf   PIE3

  clrf    PIR1
  clrf    PIR2
  clrf    PIR3
  clrf    INTCON2
  clrf    INTCON3

  call    reload_timers
  call    reload_events

  ; Find out if starting into SLiM or FLiM
  clrf    Mode
  movlw   Modstat
  call    read_ee_at_address
  movwf   Datmode
  sublw   0
  bz      slim_setup

  Set_in_FLiM
  call    reload_tx_sid_and_node_number

  Unset_New_Rx_Message
  Set_FLiM_LED_On
  Set_SLiM_LED_Off

  ; Enable high and low priority interrupts
  movlw   B'11000000'
  movwf   INTCON

  bra     main_loop

slim_setup
  Set_in_SLiM
  clrf    node_number_high
  clrf    node_number_low

  Skip_If_Not_Learn
  bra     keep_events

  Skip_If_Not_Unlearn
  call    initialise_event_data

keep_events
  call    reset_trigger_times

  Set_FLiM_LED_Off
  Set_SLiM_LED_On

  ; Enable high and low priority interrupts
  movlw   B'11000000'
  movwf   INTCON

  bra     main_loop



;******************************************************************************
;   start of subroutines
;******************************************************************************

;******************************************************************************
;   Set output triggers for an event

action_event
  movff   output_interval_duration, output_interval_timer

Set_Triggers macro output_pair_bit, output_a_trigger, output_b_trigger
  local   is_on_event, a_on_b_off, a_off_b_on, triggers_set

  btfss   event_variable_1, output_pair_bit
  bra     triggers_set

  btfss   received_opcode,0                 ; Skip if off event
  bra     is_on_event

  btfss   event_variable_2, output_pair_bit ; Skip if polarity inverted
  bra     a_off_b_on                        ; Off event, normal polarity
  bra     a_on_b_off                        ; Off event, inverted polarity

is_on_event
  btfsc   event_variable_2, output_pair_bit ; Skip if polarity inverted
  bra     a_off_b_on                        ; On event, inverted polarity

  ; Clear trigger bit for output turning off before setting trigger bit for
  ; output turning on as these are used to set actual ouputs in interrupt
  ; handler and must avoid two outputs for the same pair being turned on at the
  ; same time

a_on_b_off
  bcf     output_trigger_bits, output_b_trigger
  bsf     output_trigger_bits, output_a_trigger
  bra     triggers_set

a_off_b_on
  bcf     output_trigger_bits, output_a_trigger
  bsf     output_trigger_bits, output_b_trigger

triggers_set
  endm

  Set_Triggers 0,0,1        ; Pair 1a, 1b
  Set_Triggers 1,2,3        ; Pair 2a, 2b
  Set_Triggers 2,4,5        ; Pair 3a, 3b
  Set_Triggers 3,6,7        ; Pair 4a, 4b

  return



;******************************************************************************
;   Reload the timer settings from EEPROM and output masks from Flash

reload_timers
  movlw   low node_variables
  movwf   EEADR
  lfsr    FSR0, output_1a_pulse_time

timer_reload_loop
  bsf     EECON1, RD
  movff   EEDATA, POSTINC0
  incf    EEADR
  movlw   low node_variables + 11 ; Trigger x 8, recharge, fire, charge
  cpfseq  EEADR
  bra     timer_reload_loop

  movlw   high output_masks
  movwf   TBLPTRH
  movlw   low output_masks
  movwf   TBLPTRL
  clrf    TBLPTRU
  movlw   8                       ; 8 outputs
  movwf   loop_counter
  lfsr    FSR0, output_1a_mask

output_mask_reload_loop
  tblrd*+
  movff   TABLAT, POSTINC0
  decfsz  loop_counter
  bra     output_mask_reload_loop

  return



;******************************************************************************
;   Read byte from EEPROM
;      Address to read passed in W
;      Value read returned in W

read_ee_at_address
  movwf   EEADR
  ; drop through to read_ee

;   Read byte from EEPROM
;      EEADR must be set with address before calling
;      Value read returned in W
read_ee
  movlw   B'00000001'       ; Clear EEPGD and CFGS, set RD
  movwf   EECON1

  movf    EEDATA,W

  return



;******************************************************************************
;   Write byte to EEPROM
;      EEADR must be set with address before calling
;      Value to write passed in W

write_ee
  clrf    INTCON            ; Disable interrupts

  movwf   EEDATA

  movlw   B'00000100'       ; Clear EEPGD and CFGS, set WREN
  movwf   EECON1

  movlw   0x55
  movwf   EECON2
  movlw   0xAA
  movwf   EECON2
  bsf     EECON1, WR

write_ee_wait_loop
  btfsc   EECON1, WR
  bra     write_ee_wait_loop

  bcf     PIR2, EEIF
  bcf     EECON1, WREN

  ; Enable high and low priority interrupts
  movlw   B'11000000'
  movwf   INTCON

  return



;******************************************************************************
reload_tx_sid_and_node_number
  movlw   low CANid
  call    read_ee_at_address

  ; Transform single byte CAN Id into SIDH and SIDL
  ; CAN Id 0HHHHLLL => SIDL LLL00000 & SIDH 000HHHH
  movwf   IDtemph           ; CAN Id                     0HHHHLLL
  swapf   IDtemph,F         ; Swap high and low nibbles  HLLL0HHH
  rlncf   IDtemph,F         ; Rotate left one bit        LLL0HHHH
  movlw   B'11100000'
  andwf   IDtemph,W         ; W = LLL00000
  movwf   IDtempl           ; SIDL = LLL00000
  movlw   B'00001111'       ; Mask out upper nibble
  andwf   IDtemph,F         ; SIDH = 0000HHHH

  ; Load SIDH into Tx buffer maintaining current priority value
  movlw   B'11110000'
  andwf   Tx_sidh,F
  movf    IDtemph,W
  iorwf   Tx_sidh,F

  movff   IDtempl, Tx_sidl

  movlw   low NodeID
  call    read_ee_at_address
  movwf   node_number_high
  incf    EEADR
  call    read_ee
  movwf   node_number_low

  movlb   15                ; Select RAM bank 15

new_1
  btfsc   TXB2CON, TXREQ
  bra     new_1

  movff   IDtemph, TXB2SIDH
  movff   IDtempl, TXB2SIDL
  movlw   0xB0
  iorwf   TXB2SIDH          ; Set priority
  clrf    TXB2DLC           ; No data nor RTR
  movlb   0                 ; Select RAM bank 0

  return



#include "cbuslib/evhndlr.asm"



;******************************************************************************
;   Send first seven node parameters

send_key_node_parameters
  movlw   low node_parameters
  movwf   TBLPTRL
  movlw   8
  movwf   TBLPTRH

  lfsr    FSR0, Tx_d1
  movlw   7
  movwf   loop_counter
  bsf     EECON1, EEPGD

parameter_tx_load_loop
  tblrd*+
  movff   TABLAT, POSTINC0
  decfsz  loop_counter
  bra     parameter_tx_load_loop

  bcf     EECON1, EEPGD

  movlw   8
  movwf   Tx_dlc
  movlw   0xEF
  movwf   Tx_d0
  bra     tx_message



;******************************************************************************
;   Send module name - 7 bytes

send_name
  movlw   low node_type_name
  movwf   TBLPTRL
  movlw   high node_type_name
  movwf   TBLPTRH

  lfsr    FSR0, Tx_d1
  movlw   7
  movwf   loop_counter
  bsf     EECON1, EEPGD

name_tx_load_loop
  tblrd*+
  movff   TABLAT, POSTINC0
  decfsz  loop_counter
  bra     name_tx_load_loop

  bcf     EECON1, EEPGD

  movlw   8
  movwf   Tx_dlc
  movlw   OPC_NAME
  movwf   Tx_d0
  bra     tx_message



;******************************************************************************
;   Send and individual parameter
;   ev2 contains index of parameter to send, index 0 sends number of parameters

send_node_parameter
  movf    ev2,W
  bz      tx_number_of_parameters

  movlw   NODE_PARAMETER_COUNT
  movff   ev2, Temp
  decf    Temp                  ; Convert index to offset
  cpfslt  Temp
  bra     parameter_index_invalid

  movlw   7
  subwf   Temp,W
  bz      tx_flags_parameter

  movlw   low node_parameters
  movwf   TBLPTRL
  movlw   high node_parameters
  movwf   TBLPTRH
  clrf    TBLPTRU
  decf    ev2,W                 ; Convert index to offset
  addwf   TBLPTRL
  bsf     EECON1, EEPGD
  tblrd*
  movff   TABLAT, Tx_d4

tx_parameter
  movff   ev2, Tx_d3            ; Echo back requested index
  movlw   5
  movwf   Tx_dlc
  movlw   OPC_PARAN
  movwf   Tx_d0
  bra     tx_with_node_number

tx_number_of_parameters
  movlw   NODE_PARAMETER_COUNT
  movwf   Tx_d4
  bra     tx_parameter

parameter_index_invalid
  movlw   CMDERR_INV_PARAM_IDX
  bra     send_error_message

tx_flags_parameter
  call    get_flags
  movwf   Tx_d4
  bra     tx_parameter



;******************************************************************************
get_flags
  movlw   PF_CONSUMER
  Skip_If_SLiM
  iorlw   4         ; Set bit 2 to indicate FLiM
  iorlw   8         ; Set bit 3 to indicate bootable

  return



;******************************************************************************
;   Send a CMDERR message response
;      Error number is in W

send_error_message
  movwf   Tx_d3
  movlw   OPC_CMDERR
  movwf   Tx_d0
  movlw   4
  movwf   Tx_dlc
  bra     tx_with_node_number



send_node_number_acknowledge
  movlw   OPC_NNACK
  ; Drop through to tx_without_data


;******************************************************************************
;   Send message comprising just opcode and Node Number
;      Opcode passed in W

tx_without_data
  movwf   Tx_d0
  movlw   3
  movwf   Tx_dlc
  ; Drop through to tx_with_node_number

;******************************************************************************
;   Send message after adding Node Number

tx_with_node_number
  movff   node_number_high, Tx_d1
  movff   node_number_low, Tx_d2
  ; Drop through to tx_message

;******************************************************************************
;   Send message after adding CAN Standard Identifier

tx_message
  movlw   B'00001111'       ; Clear priority of previous transmission
  andwf   Tx_sidh,F
  movlw   B'10110000'
  iorwf   Tx_sidh,F         ; Set low transmission priority
  movlw   10
  movwf   Latcount

  ; Send contents of Tx_ buffer via CAN TXB1
  lfsr    FSR1, TXB1CON

tx_wait
  btfsc   INDF1, TXREQ    ; Skip if Tx buffer available ...
  bra     tx_wait         ; ... otherwise wait

  lfsr    FSR0, Tx_d7
  lfsr    FSR1, TXB1D7

load_tx_buffer
  movff   POSTDEC0, POSTDEC1
  movlw   Tx_sidh
  cpfseq  FSR0L
  bra     load_tx_buffer
  movff   INDF0, POSTDEC1 ; Copy last byte

  bsf     INDF1, TXREQ

  return



;******************************************************************************
;   Delay routine

delay
  movlw   10
  movwf   loop_counter1

delay_loop
  clrf    loop_counter

delay_inner_loop
  decfsz  loop_counter,F
  bra     delay_inner_loop

  decfsz  loop_counter1
  bra     delay_loop

  return



;******************************************************************************
;   Longer delay routine

long_delay
  movlw   100
  movwf   loop_counter2

long_delay_loop
  call    delay
  decfsz  loop_counter2
  bra     long_delay_loop

  return



;******************************************************************************
;   Load events and event_variables from EEPROM to RAM

copy_events_to_ram
  movlw   OLD_NUMBER_OF_EVENTS
  movwf   loop_counter
  rlncf   loop_counter,F    ; x 2
  rlncf   loop_counter,F    ; x 4
  lfsr    FSR0, EN1
  movlw   low ENstart
  movwf   EEADR

copy_events_to_ram_loop
  movlw   B'00000001'       ; Clear EEPGD and CFGS, set RD
  movwf   EECON1
  movff   EEDATA, POSTINC0
  incf    EEADR
  decfsz  loop_counter,F
  bra     copy_events_to_ram_loop

  ; Copy event variables
  movlw   OLD_NUMBER_OF_EVENTS
  movwf   loop_counter
  rlncf   loop_counter      ; Number of events x number of variables per event
  lfsr    FSR0, EV1
  movlw   low EVstart
  movwf   EEADR

copy_event_variables_to_ram_loop
  bsf     EECON1, RD
  movf    EEDATA,W
  movwf   POSTINC0
  incf    EEADR
  decfsz  loop_counter,F
  bra     copy_event_variables_to_ram_loop

  return



;******************************************************************************
;   Set indicator bit for selected ouput pair in first event variable

get_selected_output_pair
  movlw   1
  movwf   event_variable_1      ; Initialise output selection bit

  movlw   B'00000011'
  andwf   PORTB,W
  btfsc   STATUS, Z
  return

  movwf   Shift

test_next_output_pair_selection
  rlncf   event_variable_1,F    ; Shift ouput selection one bit left
  decfsz  Shift,F
  bra     test_next_output_pair_selection

  return



;******************************************************************************
request_new_node_number
  movlw   OPC_RQNN
  bra     tx_without_data



;******************************************************************************
;  Store a node variable by index
;
;    ev2 - Index of Node Variable
;    ev3 - Value for Node Variable

store_indexed_node_variable
  movlw   NUMBER_OF_NODE_VARIABLES + 1
  cpfslt  ev2
  return

  movf    ev2,W
  bnz     node_variable_index_in_range
  return

node_variable_index_in_range
  decf    WREG                  ; Convert index to offset
  addlw   low node_variables
  movwf   EEADR
  movf    ev3,W
  goto    write_ee



;******************************************************************************
;   Reset Node Variables to default values

reset_trigger_times
  movlw   8
  movwf   loop_counter
  movlw   low trigger_time_defaults
  movwf   Temp
  movwf   EEADR

trigger_times_reset_loop
  call    read_ee
  movwf   Temp1
  movlw   low node_variables - low trigger_time_defaults
  addwf   EEADR,F
  movf    Temp1,W
  call    write_ee
  dcfsnz  loop_counter
  return

  incf    Temp,F
  movf    Temp,W
  movwf   EEADR
  bra     trigger_times_reset_loop



;******************************************************************************
;   Find an unused CAN Id to adopt for self, report an error if non available

self_enumerate
  ; Enable high and low priority interrupts
  movlw   B'11000000'
  movwf   INTCON

  Set_Enumerating

  movlw   14
  movwf   loop_counter
  lfsr    FSR0, in_use_can_ids

clear_in_use_can_ids_loop
  clrf    POSTINC0
  decfsz  loop_counter
  bra     clear_in_use_can_ids_loop

  ; Set up RTR frame for transmission with fixed default CAN Id
  movlw   B'10111111'
  movwf   Tx_sidh
  movlw   B'11100000'
  movwf   Tx_sidl
  movlw   B'01000000'
  movwf   Tx_dlc

  ; Set 100 mSec timer to allow other nodes to report their CAN Ids
  movlw   0x3C
  movwf   TMR3H
  movlw   0xAF
  movwf   TMR3L
  movlw   B'10110001'
  movwf   T3CON

  call    tx_message                ; Send RTR frame
  clrf    Tx_dlc                    ; Prevent sending more RTR frames

self_enumeration_wait
  btfss   PIR2, TMR3IF
  bra     self_enumeration_wait

  ; Disable Timer3
  bcf     T3CON, TMR3ON
  bcf     PIR2, TMR3IF

  movlw   1
  movwf   unused_can_id             ; CAN Id starts at 1
  movwf   unused_can_id_bitmask     ; Initialise bitmask to 0000 0001
  lfsr    FSR0, in_use_can_ids      ; Reference used CAN Id bitmask table

find_unused_can_id_byte
  incf    INDF0,W                   ; Test current table byte ...
  bnz     find_unused_can_id_bit    ; ... jump if it contains at least one zero

  movlw   8
  addwf   unused_can_id,F           ; Increase CAN Id by eight
  incf    FSR0L                     ; Move on to next byte in bitmap table
  bra     find_unused_can_id_byte

find_unused_can_id_bit
  movf    unused_can_id_bitmask,W
  andwf   INDF0,W
  bz      update_link_id

  rlcf    unused_can_id_bitmask,F   ; Shift bitmask one bit left
  incf    unused_can_id,F           ; Increment CAN Id
  bra     find_unused_can_id_bit

update_link_id
  movlw   MAXIMUM_NUMBER_OF_CAN_IDS
  cpfslt  unused_can_id
  bra     can_segment_full

store_link_id
  movlw   low CANid
  movwf   EEADR
  movf    unused_can_id,W
  call    write_ee
  call    reload_tx_sid_and_node_number
  Unset_Enumerating

  return

can_segment_full
  movlw   CMDERR_INVALID_EVENT
  call    send_error_message
  setf    unused_can_id
  bcf     unused_can_id,7
  bra     store_link_id



;******************************************************************************
output_masks
  ; Output masks, don't change these
  db  B'00000001', B'10000000'
  db  B'00000010', B'01000000'
  db  B'00100000', B'00000100'
  db  B'00010000', B'00001000'



;******************************************************************************
  ORG 0x3000

event_storage



;******************************************************************************
; EEPROM data

  ORG 0xF00000

CANid             de  B'01111111',0  ; CAN id default and module status
NodeID            de  0,0            ; Node ID
free_event_space  de  0,0            ; free_event_space contains free space
                                     ; free_event_space + 1 contains number of
                                     ; events
                                     ; hi byte + lo byte = NUMBER_OF_EVENTS
                                     ; initialised in initialise_event_data

trigger_time_defaults
  de  DEFAULT_FIRE_TIME, DEFAULT_FIRE_TIME
  de  DEFAULT_FIRE_TIME, DEFAULT_FIRE_TIME
  de  DEFAULT_FIRE_TIME, DEFAULT_FIRE_TIME
  de  DEFAULT_FIRE_TIME, DEFAULT_FIRE_TIME

next_free_event_entry  de  0,0
hashtable              de  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


  ORG 0xF00020

ENstart ;start of 32 event numbers. 128 bytes


  ORG 0xF000A0

EVstart
  de  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0   ;event qualifiers
  de  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0   ;clear EEPROM
  de  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  de  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

node_variables
  de  DEFAULT_FIRE_TIME,                DEFAULT_FIRE_TIME
  de  DEFAULT_FIRE_TIME,                DEFAULT_FIRE_TIME
  de  DEFAULT_FIRE_TIME,                DEFAULT_FIRE_TIME
  de  DEFAULT_FIRE_TIME,                DEFAULT_FIRE_TIME
  de  DEFAULT_RECHARGE_DELAY,           DEFAULT_FIRE_DELAY
  de  DEFAULT_CHARGE_PUMP_ENABLE_DELAY, 0
  de  0,0,0,0

hash_number_event_counts
  de  0,0,0,0,0,0,0,0


  ORG 0xF000FE
  de  0,0                 ;for boot.



  end
