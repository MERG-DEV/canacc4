include(common.inc)dnl
define(test_name, flim_learn_test)dnl
include(rx_tx.inc)dnl
configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 23964 ms;
      report("test_name: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state   : test_result;
    file     event_file   : text;
    variable file_stat    : file_open_status;
    variable file_line    : string;
    variable report_line  : string;
    variable trigger_line : string;
    variable trigger_val  : integer;
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
      file_open(file_stat, event_file, "./data/learn.dat", read_mode);
      if file_stat != open_ok then
        report("test_name: Failed to open learn data file");
        report("test_name: FAIL");
        PC <= 0;
        wait;
      end if;
      --
      while endfile(event_file) == false loop
        readline(event_file, report_line);
        report(report_line);
        --
        readline(event_file, trigger_line);
        read(trigger_line, RB0);
        readline(event_file, trigger_line);
        read(trigger_line, RB1);
        readline(event_file, trigger_line);
        read(trigger_line, RB5);

        rx_wait_if_not_ready
        read(event_file, RXB0D0, 1);
        read(event_file, RXB0D1, 1);
        read(event_file, RXB0D2, 1);
        read(event_file, RXB0D3, 1);
        read(event_file, RXB0D4, 1);
        rx_frame(5)
        --
        readline(event_file, report_line);
        while match(report_line, "Done") == false loop
          readline(event_file, report_line);
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
      file_close(event_file);
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
      file_open(file_stat, event_file, "./data/learnt_events.dat", read_mode);
      if file_stat != open_ok then
        report("test_name: Failed to open event data file");
        report("test_name: FAIL");
        PC <= 0;
        wait;
      end if;
      --
      while endfile(event_file) == false loop
        readline(event_file, file_line);
        report(file_line);
        rx_wait_if_not_ready
        read(event_file, RXB0D0, 1);
        read(event_file, RXB0D1, 1);
        read(event_file, RXB0D2, 1);
        read(event_file, RXB0D3, 1);
        read(event_file, RXB0D4, 1);
        rx_frame(5)
        --
        readline(event_file, file_line);
        while match(file_line, "Done") == false loop
          readline(event_file, file_line);
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
