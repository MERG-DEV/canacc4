define(test_name, slim_nv_write_test)dnl
include(common.inc)dnl
include(rx_tx.inc)dnl
include(io.inc)dnl
include(hardware.inc)dnl
include(cbusdefs.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(873)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state  : test_result;
    begin
      report("test_name: START");
      test_state := pass;
      setup_button <= '1'; -- Setup button not pressed
      dolearn_switch <= '1'; -- Learn off
      unlearn_switch <= '1'; -- Unlearn off
     --
      wait until slim_led == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      report("test_name: Change 3A fire time");
      rx_data(OPC_NVSET, 0, 0, 5, 2) -- NVSET, CBUS set node variable by index, node 0 0, index = output 3A fire time
      tx_check_no_message(776)
      --
      report("test_name: Test long off 0x0102,0x0204, trigger 3A");
      rx_data(OPC_ACOF, 1, 2, 2, 4) -- ACOF, CBUS long off, node 1 2, event 2 4
      --
      output_check_pulse_duration(PORTC, 32, "Triggered 3A", 25)
      --
      end_test
    end process test_name;
end testbench;
