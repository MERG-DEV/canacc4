define(test_name, slim_index_events_test)dnl
include(common.inc)dnl
include(rx_tx.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(2364)
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
      report("test_name: Request stored events");
      rx_data(16#57#, 0, 0) -- NERD, CBUS Stored events request, node 0 0
      tx_check_no_message(776)
      --
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Request available event space");
      rx_data(16#56#, 0, 0) -- NNEVN, CBUS request available event space, node 0 0
      tx_check_no_message(776)
      --
      report("test_name: Request number of stored events");
      rx_data(16#58#, 0, 0) -- RQEVN, CBUS request number of stored events, node 0 0
      tx_check_no_message(776)
      --
      end_test
    end process test_name;
end testbench;
