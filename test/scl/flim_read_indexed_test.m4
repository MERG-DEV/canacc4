include(common.inc)dnl
define(test_name, flim_read_indexed_test)dnl
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
    variable event_index    : integer;
    file     event_file     : text;
    variable file_stat      : file_open_status;
    variable file_line      : string;
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
      file_open(file_stat, event_file, "./data/stored_events.dat", read_mode);
      if file_stat != open_ok then
        report("test_name: Failed to open event data file");
        report("test_name: FAIL");
        PC <= 0;
        wait;
      end if;
      --
      report("test_name: Read events");
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
          RXB0D0 <= 16#9C#; -- REVAL, CBUS Indexed read event variable request
          RXB0D1 <= 4;
          RXB0D2 <= 2;
          RXB0D3 <= event_index;
          read(file_line, variable_index);
          RXB0D4 <= variable_index;
          RXB0CON.RXFUL <= '1';
          RXB0DLC.DLC3 <= '1';
          CANSTAT <= 16#0C#;
          PIR3.RXB0IF <= '1';
          --
          TXB1CON.TXREQ <= '0';
          wait until TXB1CON.TXREQ == '1';
          if TXB1D0 != 16#B5# then -- NEVAL, CBUS Indexed event variable response
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
          if TXB1D3 != event_index then
            report("test_name: Sent wrong Event Index");
            test_state := fail;
          end if;
          if TXB1D4 != variable_index then
            report("test_name: Sent wrong Event Variable Index");
            test_state := fail;
          end if;
          readline(event_file, file_line);
          read(file_line, variable_value);
          if TXB1D5 != variable_value then
            report("test_name: Sent wrong Event Variable value");
            test_state := fail;
          end if;
          --
          readline(event_file, file_line);
        end loop;
          event_index := event_index + 1;
      end loop;
      --
      event_index := event_index - 1;
      wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Event Variable index too low");
      RXB0D0 <= 16#9C#; -- REVAL, CBUS Indexed read event variable request
      RXB0D1 <= 4;
      RXB0D2 <= 2;
      RXB0D3 <= event_index;
      RXB0D4 <= 0;         -- Event variable index, out of range
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1';
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
      if TXB1D3 != 6 then -- Invalid event variable index
        report("test_name: Sent wrong error number");
        test_state := fail;
      end if;
      --
      wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Event Variable index too high");
      RXB0D0 <= 16#9C#; -- REVAL, CBUS Indexed read event variable request
      RXB0D1 <= 4;
      RXB0D2 <= 2;
      RXB0D3 <= event_index;
      RXB0D4 <= 3;         -- Event variable index, out of range
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1';
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
      if TXB1D3 != 6 then -- Invalid event variable index
        report("test_name: Sent wrong error number");
        test_state := fail;
      end if;
      --
      wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Event index too high");
      RXB0D0 <= 16#9C#; -- REVAL, CBUS Indexed read event variable request
      RXB0D1 <= 4;
      RXB0D2 <= 2;
      RXB0D3 <= event_index + 1;
      RXB0D4 <= 1;
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1';
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
      RXB0D0 <= 16#9C#; -- REVAL, CBUS Indexed read event variable request
      RXB0D1 <= 4;
      RXB0D2 <= 2;
      RXB0D3 <= 0;
      RXB0D4 <= 1;
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1';
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
