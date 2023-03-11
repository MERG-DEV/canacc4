define(test_name, slim_read_events_test)dnl
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
      wait for 65 ms;
      report("test_name: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state  : test_result;
    file     data_file  : text;
    variable file_stat   : file_open_status;
    variable file_line   : string;
    variable node_hi     : integer;
    variable node_lo     : integer;
    variable event_hi    : integer;
    variable event_lo    : integer;
    variable ev_index    : integer;
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
      report("test_name: Enter learn mode");
      rx_data(16#53#, 4, 2) -- NNLRN, CBUS enter learn mode, node 4 2
      --
      report("test_name: Read events");
      data_file_open(stored_events.dat)
      --
      while endfile(data_file) == false loop
        data_file_report_line
        --
        readline(data_file, file_line);
        read(file_line, node_hi);
        readline(data_file, file_line);
        read(file_line, node_lo);
        readline(data_file, file_line);
        read(file_line, event_hi);
        readline(data_file, file_line);
        read(file_line, event_lo);
        --
        readline(data_file, file_line);
        while match(file_line, "Done") == false loop
          report(file_line);
          read(file_line, ev_index);
          rx_data(16#B2#;, node_hi, node_lo, event_hi, event_lo, ev_index) -- REQEV, CBUS Read event variable request
          tx_check_no_message(2)
          --
          readline(data_file, file_line);
          readline(data_file, file_line);
        end loop;
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
