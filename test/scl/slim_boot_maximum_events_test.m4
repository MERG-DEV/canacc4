define(test_name, slim_boot_maximum_events_test)dnl
include(common.inc)dnl
include(rx_tx.inc)dnl
include(io.inc)dnl
include(hardware.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(88)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    begin
      report("test_name: START");
      test_state := pass;
      setup_button <= '1'; -- Setup button not pressed
      dolearn_switch <= '1'; -- DOLEARN off
      unlearn_switch <= '1'; -- UNLEARN off
      --
      wait until slim_led == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      report("test_name: Long on 0x0102,0x0201");
      rx_data(16#90#, 1, 2, 1, 128) -- ACON, CBUS accessory on, node 1 2, event 1 128
      --
      output_wait_for_output(PORTC, 32, "Trigger 3A")
      --
      end_test
    end process test_name;
end testbench;
