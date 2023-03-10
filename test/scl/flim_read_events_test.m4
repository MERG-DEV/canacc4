include(common.inc)dnl
define(test_name, flim_read_events_test)dnl
include(rx_tx.inc)dnl
configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 25 ms;
      report("test_name: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state     : test_result;
    file     event_file     : text;
    variable file_stat      : file_open_status;
    variable file_line      : string;
    variable node_hi        : integer;
    variable node_lo        : integer;
    variable event_hi       : integer;
    variable event_lo       : integer;
    variable variable_index : integer;
    variable variable_value : integer;
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
      rx_data(16#53#, 4, 2) -- NNLRN, CBUS enter learn mode to node 4 2
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      --
      file_open(file_stat, event_file, "./data/stored_events.dat", read_mode);
      if file_stat != open_ok then
        report("test_name: Failed to open event data file");
        report("test_name: FAIL");
        PC <= 0;
        wait;
      end if;
      --
      report("test_name: Read events");
      while endfile(event_file) == false loop
        readline(event_file, file_line);
        report(file_line);
        --
        readline(event_file, file_line);
        read(file_line, node_hi);
        readline(event_file, file_line);
        read(file_line, node_lo);
        readline(event_file, file_line);
        read(file_line, event_hi);
        readline(event_file, file_line);
        read(file_line, event_lo);
        --
        readline(event_file, file_line);
        while match(file_line, "Done") == false loop
          report(file_line);
          read(file_line, variable_index);
          rx_data(16#B2#, node_hi, node_lo, event_hi, event_lo, variable_index) -- REQEV, CBUS Read event variable request
          readline(event_file, file_line);
          read(file_line, variable_value);
          tx_wait_for_message(16#D3#, opcode, node_hi, node high, node_lo, node low, event_hi, event high, event_lo, event low, variable_index, event variable index, variable_value, event variable value) -- EVANS, CBUS event variable response
          --
          readline(event_file, file_line);
        end loop;
      end loop;
      --
      report("test_name: Event Variable index too low");
      rx_data(16#B2#, node_hi, node_lo, event_hi, event_lo, 0) -- REQEV, CBUS Read event variable request
      tx_wait_for_cmderr_message(4, 2, 6) -- CMDERR, CBUS error response, node 4 2, Invalid event variable index
      --
      report("test_name: Event Variable index too high");
      rx_data(16#B2#, node_hi, node_lo, event_hi, event_lo, 3) -- REQEV, CBUS Read event variable request
      tx_wait_for_cmderr_message(4, 2, 6) -- CMDERR, CBUS error response, node 4 2, Invalid event variable index
      --
      report("test_name: Read unknown event");
      rx_data(16#B2#, 9, 8, 7, 6, 1) -- REQEV, CBUS Read event variable request
      tx_wait_for_cmderr_message(4, 2, 5) -- CMDERR, CBUS error response, node 4 2, unknown event
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
