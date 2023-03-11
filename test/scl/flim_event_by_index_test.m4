define(test_name, flim_event_by_index_test)dnl
include(common.inc)dnl
include(rx_tx.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  test_timeout: process is
    begin
      wait for 789 ms;
      report("test_name: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state  : test_result;
    variable event_index : integer;
    file     event_file  : text;
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
      file_open(file_stat, event_file, "./data/stored_events.dat", read_mode);
      if file_stat != open_ok then
        report("test_name: Failed to open event data file");
        report("test_name: FAIL");
        PC <= 0;
        wait;
      end if;
      --
      event_index := 1;
      while endfile(event_file) == false loop
        readline(event_file, file_line);
        report(file_line);
        readline(event_file, file_line);
        read(file_line, ev_node_hi);
        readline(event_file, file_line);
        read(file_line, ev_node_lo);
        readline(event_file, file_line);
        read(file_line, ev_ev_hi);
        readline(event_file, file_line);
        read(file_line, ev_ev_lo);
        --
        rx_data(16#72#, 4, 2, event_index) -- NENRD, CBUS Read event by index request to node 4 2
        tx_wait_for_node_message(16#F2#, 4, 2, ev_node_hi, event node high, ev_node_lo, event node low, ev_ev_hi, event event high, ev_ev_lo, event event low, event_index, event index) -- ENRSP, CBUS stored event response
        --
        while match(file_line, "Done") == false loop
          readline(event_file, file_line);
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
