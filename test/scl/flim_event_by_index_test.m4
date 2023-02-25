include(common.inc)dnl
define(test_name, flim_event_by_index_test)dnl
include(rx_tx.inc)dnl
configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
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
    variable line_val    : integer;
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
      tx_wait_for_ready(776)
      if TXB1CON.TXREQ == '1' then
        report("test_name: Unexpected response");
        test_state := fail;
      end if;
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
        wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
        rx_data(16#72#, 4, 2, event_index) -- NENRD, CBUS Read event by index request to node 4 2
        --
        tx_wait_for_ready
        if TXB1D0 != 16#F2# then -- ENRSP, CBUS stored event response
          report("test_name: Sent wrong response");
          test_state := fail;
        end if;
        if TXB1D1 != 4 then
          report("test_name: Sent wrong Node Number (high)");
          test_state := fail;
        end if;
        if TXB1D2 != 2 then
          report("test_name: Sent wrong Node Number (low)");
          test_state := fail;
        end if;
        readline(event_file, file_line);
        read(file_line, line_val);
        if TXB1D3 != line_val then
          report("test_name: Sent wrong Event Node Number (high)");
          test_state := fail;
        end if;
        readline(event_file, file_line);
        read(file_line, line_val);
        if TXB1D4 != line_val then
          report("test_name: Sent wrong Event Node Number (low)");
          test_state := fail;
        end if;
        readline(event_file, file_line);
        read(file_line, line_val);
        if TXB1D5 != line_val then
          report("test_name: Sent wrong Event Number (high)");
          test_state := fail;
        end if;
        readline(event_file, file_line);
        read(file_line, line_val);
        if TXB1D6 != line_val then
          report("test_name: Sent wrong Event Number (low)");
          test_state := fail;
        end if;
        if TXB1D7 != event_index then
          report("test_name: Sent wrong Event Index");
          test_state := fail;
        end if;
        --
        while match(file_line, "Done") == false loop
          readline(event_file, file_line);
        end loop;
        --
        event_index := event_index + 1;
      end loop;
      --
      wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
      report("test_name: Reject request with too high event index");
      rx_data(16#72#, 4, 2, event_index) -- NENRD, CBUS Read event by index request to node 4 2
      --
      tx_wait_for_ready
      if TXB1D0 != 16#6F# then -- CMDERR, CBUS error response
        report("test_name: Sent wrong response");
        test_state := fail;
      end if;
      if TXB1D1 != 4 then
        report("test_name: Sent wrong Node Number (high)");
        test_state := fail;
      end if;
      if TXB1D2 != 2 then
        report("test_name: Sent wrong Node Number (low)");
        test_state := fail;
      end if;
      if TXB1D3 != 7 then -- Invalid event index
        report("test_name: Sent wrong error number");
        test_state := fail;
      end if;
      --
      wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Event index too low");
      rx_data(16#72#, 4, 2, 0) -- NENRD, CBUS Read event by index request to node 4 2
      --
      tx_wait_for_ready
      if TXB1D0 != 16#6F# then -- CMDERR, CBUS error response
        report("test_name: Sent wrong response");
        test_state := fail;
      end if;
      if TXB1D1 != 4 then
        report("test_name: Sent wrong Node Number (high)");
        test_state := fail;
      end if;
      if TXB1D2 != 2 then
        report("test_name: Sent wrong Node Number (low)");
        test_state := fail;
      end if;
      if TXB1D3 != 7 then -- Invalid event index
        report("test_name: Sent wrong error number");
        test_state := fail;
      end if;
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
