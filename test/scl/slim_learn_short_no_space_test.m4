define(test_name, slim_learn_short_no_space_test)dnl
include(common.inc)dnl
include(rx_tx.inc)dnl
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
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- Learn off
      RA5 <= '1'; -- Unlearn off
      --
      wait until RB7 == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      -- Learn events for output 3
      RB4 <= '0'; -- Learn on
      RB0 <= '0'; -- Sel 0 on
      RB1 <= '1'; -- Sel 1 off
      RB5 <= '1'; -- Polarity normal, On event => A, Off event => B
      --
      report("test_name: Short On 0x0102, 0x0180");
      rx_data(16#98#, 1, 2, 1, 128) -- ASON, CBUS accessory short on, node 1 2, event 1 128
      --
      wait until PORTC != 0;
      wait until PORTC == 0;
      --
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
      --if RB6 == '0' then
      --  wait until RB6 == '1';
      --end if;
      --wait until RB6 == '1';
      --
      if test_state == pass then
        report("test_name: PASS");
      else
        report("test_name: FAIL");
      end if;
      PC <= 0;
      wait;
    end process test_name;
end testbench;
