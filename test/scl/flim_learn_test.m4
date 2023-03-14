define(test_name, flim_learn_test)dnl
include(common.inc)dnl
include(data_file.inc)dnl
include(rx_tx.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(23964)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state  : test_result;
    file     data_file   : text;
    variable file_stat   : file_open_status;
    variable file_line   : string;
    variable pulse_val : integer;
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
      RB4 <= '0';
      report("test_name: Learn switch on");
      --
      report("test_name: Do not learn events");
      data_file_open(learn.dat)
      --
      while endfile(data_file) == false loop
        data_file_report_line
        --
        readline(data_file, file_line);
        read(file_line, RB0);
        readline(data_file, file_line);
        read(file_line, RB1);
        readline(data_file, file_line);
        read(file_line, RB5);

        rx_wait_if_not_ready
        rx_data_file_event
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
      file_close(data_file);
      --
      RB4 <= '1'; -- Learn off
      report("test_name: Learn switch off");
      --
      rx_data(16#56#, 4, 2) -- NNEVN, CBUS request available event space, node 4 2
      tx_wait_for_node_message(16#70#, 4, 2, 128, available event space) -- EVLNF, CBUS available event space response
      --
      report("test_name: Check number of stored events");
      rx_data(16#58#, 4, 2) -- RQEVN, CBUS request number of stored events to node 4 2
      tx_wait_for_node_message(16#74#, 4, 2, 0, number of stored events) -- NUMEV, CBUS number of stored event response node 4 2
      --
      report("test_name: Check events were not learnt");
      data_file_open(learnt_events.dat)
      --
      while endfile(data_file) == false loop
        data_file_report_line
        rx_wait_if_not_ready
        rx_data_file_event
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
      end_test
    end process test_name;
end testbench;
