define(test_name, flim_clear_test)dnl
include(common.inc)dnl
include(data_file.inc)dnl
include(rx_tx.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  test_timeout: process is
    begin
      wait for 16934 ms;
      report("test_name: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    file     data_file : text;
    variable file_stat  : file_open_status;
    variable file_line  : string;
    begin
      report("test_name: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- Learn off
      RA5 <= '1'; -- Unlearn off
      --
      wait until RB6 == '1'; -- Booted into FLiM
      report("test_name: Yellow LED (FLiM) on");
      --
      report("test_name: Reject clear events request");
      rx_data(16#55#, 4, 2) -- NNCLR, CBUS clear events to node 4 2
      tx_wait_for_node_message(16#6F#, 4, 2, 2, error number) -- CMDERR, CBUS error response
      --
      report("test_name: Check available event space");
      rx_data(16#56#, 4, 2) -- NNEVN, CBUS request available event space to node 4 2
      tx_wait_for_node_message(16#70#, 4, 2, 123) -- EVLNF, CBUS available event space response
      --
      report("test_name: Check number of stored events");
      rx_data(16#58#, 4, 2) -- RQEVN, CBUS request number of stored events to node 4 2
      tx_wait_for_node_message(16#74#, 4, 2, 5, number of stored events) -- NNEVN, CBUS number of stored events response
      --
      report("test_name: Enter learn mode");
      rx_data(16#53#, 4, 2) -- NNLRN, CBUS enter learn mode to node 4 2
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      --
      report("test_name: Clear events");
      rx_data(16#55#, 4, 2) -- NNCLR, CBUS clear events to node 4 2
      tx_wait_for_node_message(16#59#, 4, 2) -- WRACK, CBUS write acknowledge response
      --
      report("test_name: Exit learn mode");
      rx_data(16#54#, 4, 2) -- NNULN, exit learn mode to node 4 2
      --
      report("test_name: Reheck available event space");
      rx_data(16#56#, 4, 2) -- NNEVN, CBUS request available event space to node 4 2
      tx_wait_for_node_message(16#70#, 4, 2, 128) -- EVLNF, CBUS available event space response
      --
      report("test_name: Reheck number of stored events");
      rx_data(16#58#, 4, 2) -- RQEVN, CBUS request number of stored events to node 4 2
      tx_wait_for_node_message(16#74#, 4, 2, 0, number of stored events) -- NNEVN, CBUS number of stored events response
      --
      report("test_name: Check events are now ignored");
      data_file_open(learnt_events.dat)
      --
      while endfile(data_file) == false loop
        rx_wait_if_not_ready
        readline(data_file, file_line);
        report(file_line);
        read(data_file, RXB0D0, 1);
        read(data_file, RXB0D1, 1);
        read(data_file, RXB0D2, 1);
        read(data_file, RXB0D3, 1);
        read(data_file, RXB0D4, 1);
        rx_frame(5)
        --
        readline(data_file, file_line);
        while match(file_line, "Done") == false loop
          readline(data_file, file_line);
        end loop;
        --
        wait until PORTC != 0 for 1005 ms;
        if PORTC != 0 then
          report("test_name: Unexpected trigger");
          test_state := fail;
          wait until PORTC == 0;
        end if;
      end loop;
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
