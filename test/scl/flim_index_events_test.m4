define(test_name, flim_index_events_test)dnl
include(common.inc)dnl
include(data_file.inc)dnl
include(rx_tx.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(1619)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state  : test_result;
    variable event_index : integer;
    file     data_file  : text;
    variable file_stat   : file_open_status;
    variable file_line   : string;
    variable ev_node_hi  : integer;
    variable ev_node_lo  : integer;
    variable ev_ev_hi    : integer;
    variable ev_ev_lo    : integer;
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
      report("test_name: Ignore read events request not addressed to node");
      rx_data(16#57#, 0, 0) -- NERD, CBUS Read events request, node 0 0
      tx_check_no_message(776)  -- Test if unexpected response sent
      --
      report("test_name: Read events");
      rx_data(16#57#, 4, 2) -- NERD, CBUS Read events request, node 4 2
      --
      data_file_open(stored_events.dat)
      --
      event_index := 1;
      while endfile(data_file) == false loop
        data_file_report_line
        data_file_read(ev_node_hi)
        data_file_read(ev_node_lo)
        data_file_read(ev_ev_hi)
        data_file_read(ev_ev_lo)
        tx_wait_for_node_message(16#F2#, 4, 2, ev_node_hi, event node high, ev_node_lo, event node low, ev_ev_hi, event event high, ev_ev_lo, event event low, event_index, event index) -- ENRSP, CBUS stored event response
        --
        while match(file_line, "Done") == false loop
          readline(data_file, file_line);
        end loop;
        --
        event_index := event_index + 1;
      end loop;
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1' for 776 ms; -- Test if response sent
      if TXB1CON.TXREQ == '1' then
        report("test_name: Unexpected response");
        test_state := fail;
      end if;
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
