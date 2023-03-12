define(test_name, slim_modify_by_index_test)dnl
include(common.inc)dnl
include(data_file.inc)dnl
include(rx_tx.inc)dnl
include(io.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(30371)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state     : test_result;
    file     data_file      : text;
    variable file_stat      : file_open_status;
    variable file_line      : string;
    variable trigger_report : string;
    variable trigger_val    : integer;
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
      rx_data(16#53#, 4, 2) -- NNLRN, CBUS enter learn mode, node 4, 2
      --
      data_file_open(modify_indexed.dat)
      --
      report("test_name: Modify events");
      while endfile(data_file) == false loop
        rx_wait_if_not_ready
        data_file_report_line
        --
        RXB0D0 <= 16#F5#;    -- EVLRNI, CBUS learn by index event
        read(data_file, RXB0D1, 1);
        read(data_file, RXB0D2, 1);
        read(data_file, RXB0D3, 1);
        read(data_file, RXB0D4, 1);
        read(data_file, RXB0D5, 1);
        read(data_file, RXB0D6, 1);
        read(data_file, RXB0D7, 1);
        rx_frame(8)
        tx_check_no_message(776)
        --
          wait until PORTC != 0 for 1005 ms;
          if PORTC != 0 then
            report("test_name: Unexpected trigger");
            test_state := fail;
            wait until PORTC == 0;
          end if;
        --
        while match(file_line, "Done") == false loop
          readline(data_file, file_line);
        end loop;
      end loop;
      --
      file_close(data_file);
      --
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Exit learn mode");
      rx_data(16#54#, 4, 2) -- NNULN, exit learn mode, node 4, 2
      --
      data_file_open(learnt_events.dat)
      --
      report("test_name: Check events are unchanged");
      while endfile(data_file) == false loop
        rx_wait_if_not_ready
        data_file_report_line
        rx_data_file_event
        --
        output_wait_for_data_file_pulse
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
      end_test
    end process test_name;
end testbench;
