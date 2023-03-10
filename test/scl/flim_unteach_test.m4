define(test_name, flim_unteach_test)dnl
include(common.inc)dnl
configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 25000 ms;
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
      report("test_name: Check available event space");
      rx_data(16#56#, 4, 2) -- NNEVN, CBUS request available event space to node 4 2
      tx_wait_for_node_message(16#70#, 4, 2, 123, available event space) -- EVLNF, CBUS available event space response node 4 2
      --
      report("test_name: Check number of stored events");
      rx_data(16#58#, 4, 2) -- RQEVN, CBUS request number of stored events to node 4 2
      tx_wait_for_node_message(16#74#, 4, 2, 5, number of stored events) -- EVLNF, CBUS available event space response node 4 2
      --
      report("test_name: Enter learn mode");
      rx_data(16#53#, 4, 2) -- NNLRN, CBUS enter learn mode to node 4 2
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      --
      file_open(file_stat, event_file, "./data/unlearn.dat", read_mode);
      if file_stat != open_ok then
        report("test_name: Failed to open unlearn data file");
        report("test_name: FAIL");
        PC <= 0;
        wait;
      end if;
      --
      report("test_name: Unlearn events");
      while endfile(event_file) == false loop
        rx_wait_if_not_ready
        readline(event_file, report_line);
        report(report_line);
        read(event_file, RXB0D0, 1); -- Ignore event type from data file
        RXB0D0 <= 16#95#;            -- EVULN, CBUS unlearn event
        read(event_file, RXB0D1, 1);
        read(event_file, RXB0D2, 1);
        read(event_file, RXB0D3, 1);
        read(event_file, RXB0D4, 1);
        rx_frame(5)
        tx_wait_for_node_message(16#59#, 4, 2) -- WRACK, CBUS write acknowledge response node 4 2
      --
      end loop;
      --
      file_close(event_file);
      --
      report("test_name: Exit learn mode");
      rx_data(16#54#, 4, 2) -- NNULN, CBUS exit learn mode to node 4 2
      --
      report("test_name: Do not unlearn event");
      rx_data(16#95#, 1, 2, 2, 4) -- EVULN, CBUS unlearn event, node 1 2, event 2 4
      --
      -- FIXME SHould reject request as not in learn mode
      --TXB1CON.TXREQ <= '0';
      --wait until TXB1CON.TXREQ == '1';
      --if TXB1D0 != 16#6F# then -- CMDERR, CBUS error response
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
      --if TXB1D3 != 2 then -- Not in learn event mode
      --  report("test_name: Sent wrong error number");
      --  test_state := fail;
      --end if;
      --
      report("test_name: Recheck available event space");
      rx_data(16#56#, 4, 2) -- NNEVN, CBUS request available event space to node 4 2
      tx_wait_for_node_message(16#70#, 4, 2, 125, available event space) -- EVLNF, CBUS available event space response node 4 2
      --
      report("test_name: Recheck number of stored events");
      rx_data(16#58#, 4, 2) -- RQEVN, CBUS request number of stored events to node 4 2
      tx_wait_for_node_message(16#74#, 4, 2, 3, number of stored events) -- EVLNF, CBUS available event space response node 4 2
      --
      file_open(file_stat, event_file, "./data/remaining_events.dat", read_mode);
      if file_stat != open_ok then
        report("test_name: Failed to open event data file");
        report("test_name: FAIL");
        PC <= 0;
        wait;
      end if;
      --
      report("test_name: Check events");
      while endfile(event_file) == false loop
        rx_wait_if_not_ready
        readline(event_file, report_line);
        report(report_line);
        read(event_file, RXB0D0, 1);
        read(event_file, RXB0D1, 1);
        read(event_file, RXB0D2, 1);
        read(event_file, RXB0D3, 1);
        read(event_file, RXB0D4, 1);
        rx_frame(5)
        --
        readline(event_file, report_line);
        while match(report_line, "Done") == false loop
          readline(event_file, trigger_line);
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
      if test_state == pass then
        report("test_name: PASS");
      else
        report("test_name: FAIL");
      end if;
      PC <= 0;
      wait;
    end process test_name;
end testbench;
