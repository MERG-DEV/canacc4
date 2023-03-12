define(test_name, slim_read_indexed_test)dnl
include(common.inc)dnl
include(data_file.inc)dnl
include(rx_tx.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(65)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state  : test_result;
    variable event_index : integer;
    file     data_file  : text;
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
      data_file_open(stored_events.dat)
      --
      event_index := 1;
      while endfile(data_file) == false loop
        data_file_report_line
        --
        -- Skip node and event numbers
        readline(data_file, file_line);
        readline(data_file, file_line);
        readline(data_file, file_line);
        readline(data_file, file_line);
        --
        readline(data_file, file_line);
        while match(file_line, "Done") == false loop
          report(file_line);
          read(file_line, ev_index);
          rx_data(16#9C#, 4, 2, event_index, ev_index) -- REVAL, CBUS Indexed read event variable request, node 4 2
          tx_check_no_message(2)
          --
          readline(data_file, file_line);
          readline(data_file, file_line);
        end loop;
          event_index := event_index + 1;
      end loop;
      --
      end_test
    end process test_name;
end testbench;
