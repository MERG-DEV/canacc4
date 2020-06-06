    TITLE   "Source for CAN accessory decoder using CBUS"
; filename CANACC4_2_v2q.asm
;
; Assembly options
  LIST  P=18F2480,r=dec,N=75,C=120,T=ON

  include "p18f2480.inc"

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



  include "cbuslib/cbusdefs.inc"



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

#define  Charge_Pump_Output         PORTA,4
#define  Charge_Pump_Enable_Output  PORTA,0
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



  include   "cbuslib/boot_loader.inc"



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


  ; Bank 1 is reserved for use by event_store


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
  Datmode                   ; Bit 0 = New message received
                            ; Bit 1 = Enumerating CAN Id
                            ; Bit 2 = In FLiM setup
                            ; Bit 3 = Running normally
                            ; Bit 4 = In learn event mode, FLiM only
  loop_counter
  loop_counter1
  loop_counter2

  event_not_matched

  event_count
  event_count1
  event_variable_1
  event_variable_2
  copy_of_event_variable_1

  received_can_id           ; CAN Id received whilst self enumerating
  received_can_id_bitmask   ; Rolling bitmask to record received CAN Id
  unused_can_id             ; CAN Id available for self enumeration
  unused_can_id_bitmask     ; Rolling bitmask to find unused CAN Id

  tx_arbitration_count
  Mode
  shift_count

  Temp
  Temp1
  CanID_tmp
  sid_high
  sid_low
  node_number_high
  node_number_low

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

  output_pulse_timer
  output_trigger_bits
  output_off_bitmask
  output_interval_timer
  charge_pump_delay_timer
  low_priority_interrupt_counter

  output_1a_pulse_time
  output_1b_pulse_time
  output_2a_pulse_time
  output_2b_pulse_time
  output_3a_pulse_time
  output_3b_pulse_time
  output_4a_pulse_time
  output_4b_pulse_time
  output_recharge_time      ; Recharge Time. Must follow output_4b_pulse_time
  output_interval_duration  ; Fire delay. Must follow output_recharge_time
  charge_pump_delay_time    ; Charge delay. Must follow output_interval_duration

  output_1a_mask   ; Mask for output 1a
  output_1b_mask   ; Mask for output 1b
  output_2a_mask   ; Mask for output 2a
  output_2b_mask   ; Mask for output 2b
  output_3a_mask   ; Mask for output 3a
  output_3b_mask   ; Mask for output 3b
  output_4a_mask   ; Mask for output 4a
  output_4b_mask   ; Mask for output 4b

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
  event_variable_index
  event_variable_value
  event_index

  flash_access_counter_0  ; counters used by Flash handling
  flash_access_counter_1

  ENDC



;******************************************************************************
;
;   Start of program code

  ORG     RESET_VECTOR
  nop     ; For debug
  goto    setup


  ORG     NODE_TYPE_PARAMETERS
node_type_name
  db      "ACC4_2 "


  ORG     NODE_PARAMETERS
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


  ORG     AFTER_NODE_PARAMETERS
  dw      NODE_PARAMETER_COUNT     ; Number of parameters implemented
  dw      node_type_name           ; Pointer to module type name
  dw      0                        ; Top 2 bytes of 32 bit address not used
  dw      NODE_PARAMETER_CHECKSUM  ; Checksum of parameters



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
get_flags
  movlw   PF_CONSUMER
  Skip_If_SLiM
  iorlw   4         ; Set bit 2 to indicate FLiM
  iorlw   8         ; Set bit 3 to indicate bootable

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

  ; Read output pair selection from switch inputs
  movlw   B'00000011'
  andwf   PORTB,W
  btfsc   STATUS, Z
  return

  movwf   shift_count

test_next_output_pair_selection
  rlncf   event_variable_1,F    ; Shift ouput selection one bit left
  decfsz  shift_count,F
  bra     test_next_output_pair_selection

  return


;******************************************************************************
;   end of subroutines
;******************************************************************************



  include "cbuslib/event_store.inc"
  include "cbuslib/cbus_can_link.inc"



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

  ; Drop through into main loop



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

  include "cbuslib/cbus_message_handling.inc"



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
