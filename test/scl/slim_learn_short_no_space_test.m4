define(test_name, slim_learn_short_no_space_test)dnl
include(common.inc)dnl
include(rx_tx.inc)dnl
include(io.inc)dnl
include(hardware.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(333)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
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
      -- Learn events for output 3
      dolearn_switch <= '0'; -- Learn on
      sel0_switch <= '0'; -- Sel 0 on
      sel1_switch <= '1'; -- Sel 1 off
      polarity_switch <= '1'; -- Polarity normal, On event => A, Off event => B
      --
      report("test_name: Short On 0x0102, 0x0180");
      rx_data(16#98#, 1, 2, 1, 128) -- ASON, CBUS accessory short on, node 1 2, event 1 128
      output_wait_for_any_pulse(PORTC)
      tx_check_no_message
      --
      report("test_name: Learnt 128 events");
      --
      report("test_name: Short On 0x0102, 0x0181");
      rx_data(16#98#, 1, 2, 2, 129) -- ASON, CBUS accessory short on, node 1 2, event 2 129
      --
      report("test_name: Awaiting CMDERR");
      tx_wait_for_cmderr_message(0, 0, 4) -- CMDERR, CBUS error response, node 0 0, no event space left
      --
      -- FIXME yellow LED should flash
      --if flim_led == '0' then
      --  wait until flim_led == '1';
      --end if;
      --wait until flim_led == '1';
      --
      end_test
    end process test_name;
end testbench;
