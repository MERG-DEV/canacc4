include(common.inc)dnl
define(test_name, slim_read_indexed_test)dnl
include(rx_tx.inc)dnl
configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
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
    variable event_index : integer;
    file     event_file  : text;
    variable file_stat   : file_open_status;
    variable file_line   : string;
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
        --
        -- Skip node and event numbers
        readline(event_file, file_line);
        readline(event_file, file_line);
        readline(event_file, file_line);
        readline(event_file, file_line);
        --
        readline(event_file, file_line);
        while match(file_line, "Done") == false loop
          wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
          report(file_line);
          read(file_line, ev_index);
          rx_data(16#9C#, 4, 2, event_index, ev_index) -- REVAL, CBUS Indexed read event variable request, node 4 2
          tx_check_no_response(2)
          --
          readline(event_file, file_line);
          readline(event_file, file_line);
        end loop;
          event_index := event_index + 1;
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
