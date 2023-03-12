define(test_name, flim_event_by_index_test)dnl
include(common.inc)dnl
include(data_file.inc)dnl
include(rx_tx.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(789)
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
      report("test_name: Ignore read events by index not addressed to node");
      rx_data(16#72#, 0, 0, 1) -- NENRD, CBUS Read event by index request, node 0, index 1
      --
      tx_check_no_message(776)
      --
      report("test_name: Read events");
      data_file_open(stored_events.dat)
      --
      event_index := 1;
      while endfile(data_file) == false loop
        data_file_report_line
        data_file_read(ev_node_hi)
        data_file_read(ev_node_lo)
        data_file_read(ev_ev_hi)
        data_file_read(ev_ev_lo)
        --
        rx_data(16#72#, 4, 2, event_index) -- NENRD, CBUS Read event by index request to node 4 2
        tx_wait_for_node_message(16#F2#, 4, 2, ev_node_hi, event node high, ev_node_lo, event node low, ev_ev_hi, event event high, ev_ev_lo, event event low, event_index, event index) -- ENRSP, CBUS stored event response
        --
        while match(file_line, "Done") == false loop
          readline(data_file, file_line);
        end loop;
        --
        event_index := event_index + 1;
      end loop;
      --
      report("test_name: Reject request with too high event index");
      rx_data(16#72#, 4, 2, event_index) -- NENRD, CBUS Read event by index request to node 4 2
      tx_wait_for_node_message(16#6F#, 4, 2, 7, error number) -- CMDERR, CBUS error response
      --
      report("test_name: Event index too low");
      rx_data(16#72#, 4, 2, 0) -- NENRD, CBUS Read event by index request to node 4 2
      tx_wait_for_node_message(16#6F#, 4, 2, 7, error number) -- CMDERR, CBUS error response
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
