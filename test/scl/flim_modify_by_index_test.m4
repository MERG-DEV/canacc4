define(test_name, flim_modify_by_index_test)dnl
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
      wait for 33372 ms;
      report("test_name: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state   : test_result;
    file     data_file   : text;
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
      rx_data(16#53#, 4, 2) -- NNLRN, CBUS enter learn mode to node 4 2
      --
      report("test_name: Modify events");
     data_file_open(modify_indexed.dat)
      --
      while endfile(data_file) == false loop
        readline(data_file, report_line);
        report(report_line);
        --
        rx_wait_if_not_ready
        RXB0D0 <= 16#F5#;    -- EVLRNI, CBUS learn by index event
        read(data_file, RXB0D1, 1);
        read(data_file, RXB0D2, 1);
        read(data_file, RXB0D3, 1);
        read(data_file, RXB0D4, 1);
        read(data_file, RXB0D5, 1);
        read(data_file, RXB0D6, 1);
        read(data_file, RXB0D7, 1);
        rx_frame(8)
        --
        -- CANACC4 does not implement learn by index so no WRACK expected
        --TXB1CON.TXREQ <= '0';
        --wait until TXB1CON.TXREQ == '1';
        --if TXB1D0 != 16#59# then -- WRACK, CBUS write acknowledge response
        --  report("test_name: Sent wrong response");
        --  test_state := fail;
        --end if;
        --if TXB1D1 != 4 then
        --  report("test_name: Sent wrong Node Number (high)");
        --  test_state := fail;
        --end if;
        --if TXB1D2 != 2 then
        --  report("test_name: Sent wrong Node Number (low)");
        --  test_state := fail;
        --end if;
        tx_check_no_message(776) -- Test if unexpectedresponse sent
        --
        readline(data_file, report_line);
        while match(report_line, "Done") == false loop
          readline(data_file, trigger_line);
          read(trigger_line, trigger_val);
          --
          wait until PORTC != 0 for 1005 ms;
          if PORTC != 0 then
            report("test_name: Unexpected trigger");
            test_state := fail;
            wait until PORTC == 0;
          end if;
          --
          readline(data_file, report_line);
        end loop;
        --
      end loop;
      --
      file_close(data_file);
      --
      report("test_name: Exit learn mode");
      rx_data(16#54#, 4, 2) -- NNULN, CBUS exit learn mode to node 4 2
      --
      rx_data(16#56#, 4, 2) -- NNEVN, CBUS request available event space, node 4 2
      tx_wait_for_node_message(16#70#, 4, 2, 123, available event space) -- EVLNF, CBUS available event space response
      --
      report("test_name: Check number of stored events");
      rx_data(16#58#, 4, 2) -- RQEVN, CBUS request number of stored events to node 4 2
      tx_wait_for_node_message(16#74#, 4, 2, 5, number of stored events) -- NUMEV, CBUS number of stored event response node 4 2
      --
      report("test_name: Check events");
      -- CANACC4 does not implement learn by index so events are unmodified
      -- file_open(file_stat, data_file, "./data/index_modified_events.dat", read_mode);
      data_file_open(learnt_events.dat)
      --
      while endfile(data_file) == false loop
        readline(data_file, report_line);
        report(report_line);
        rx_wait_if_not_ready
        rx_data_file_event
        --
        readline(data_file, report_line);
        while match(report_line, "Done") == false loop
          readline(data_file, trigger_line);
          read(trigger_line, trigger_val);
          --
          wait until PORTC != 0;
          if PORTC == trigger_val then
            report(report_line);
         else
            report("test_name: Wrong output");
            test_state := fail;
          end if;
          wait until PORTC == 0;
          --
          readline(data_file, report_line);
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
      if test_state == pass then
        report("test_name: PASS");
      else
        report("test_name: FAIL");
      end if;
      PC <= 0;
      wait;
    end process test_name;
end testbench;
