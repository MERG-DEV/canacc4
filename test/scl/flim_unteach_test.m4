include(common.inc)dnl
define(test_name, flim_unteach_test)dnl
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
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Check available event space");
      RXB0D0 <= 16#56#;    -- NNEVN, CBUS request available event space
      RXB0D1 <= 4;         -- NN high
      RXB0D2 <= 2;         -- NN low
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1';
      if TXB1D0 != 16#70# then -- EVLNF, CBUS available event space response
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
      if TXB1D3 != 123 then
        report("test_name: Sent wrong available event space");
        test_state := fail;
      end if;
      --
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Check number of stored events");
      RXB0D0 <= 16#58#;    -- RQEVN, CBUS request number of stored events
      RXB0D1 <= 4;         -- NN high
      RXB0D2 <= 2;         -- NN low
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1';
      if TXB1D0 != 16#74# then -- NNEVN, CBUS number of stored events response
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
      if TXB1D3 != 5 then
        report("test_name: Sent wrong number of stored events");
        test_state := fail;
      end if;
      --
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Enter learn mode");
      RXB0D0 <= 16#53#;    -- NNLRN, CBUS enter learn mode
      RXB0D1 <= 4;         -- NN high
      RXB0D2 <= 2;         -- NN low
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
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
        wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
        if RXB0CON.RXFUL != '0' then
          wait until RXB0CON.RXFUL == '0';
        end if;
        readline(event_file, report_line);
        report(report_line);
        read(event_file, RXB0D0, 1); -- Ignore event type from data file
        RXB0D0 <= 16#95#;            -- EVULN, CBUS unlearn event
        read(event_file, RXB0D1, 1);
        read(event_file, RXB0D2, 1);
        read(event_file, RXB0D3, 1);
        read(event_file, RXB0D4, 1);
        RXB0CON.RXFUL <= '1';
        RXB0DLC.DLC3 <= '1';
        CANSTAT <= 16#0C#;
        PIR3.RXB0IF <= '1';
        --
        TXB1CON.TXREQ <= '0';
        wait until TXB1CON.TXREQ == '1';
        if TXB1D0 != 16#59# then -- WRACK, CBUS write acknowledge response
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
      --
      end loop;
      --
      file_close(event_file);
      --
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Exit learn mode");
      RXB0D0 <= 16#54#;    -- NNULN, exit learn mode
      RXB0D1 <= 4;         -- NN high
      RXB0D2 <= 2;         -- NN low
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Do not unlearn event");
      RXB0D0 <= 16#95#;            -- EVULN, CBUS unlearn event
      RXB0D1 <= 1;         -- NN high
      RXB0D2 <= 2;         -- NN low
      RXB0D3 <= 2;
      RXB0D4 <= 4;
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
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
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Recheck available event space");
      RXB0D0 <= 16#56#;    -- NNEVN, CBUS request available event space
      RXB0D1 <= 4;         -- NN high
      RXB0D2 <= 2;         -- NN low
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1';
      if TXB1D0 != 16#70# then -- EVLNF, CBUS available event space response
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
      if TXB1D3 != 125 then
        report("test_name: Sent wrong available event space");
        test_state := fail;
      end if;
      --
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Recheck number of stored events");
      RXB0D0 <= 16#58#;    -- RQEVN, CBUS request number of stored events
      RXB0D1 <= 4;         -- NN high
      RXB0D2 <= 2;         -- NN low
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1';
      if TXB1D0 != 16#74# then -- NNEVN, CBUS number of stored events response
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
      if TXB1D3 != 3 then
        report("test_name: Sent wrong number of stored events");
        test_state := fail;
      end if;
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
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      report("test_name: Check events");
      while endfile(event_file) == false loop
        if RXB0CON.RXFUL != '0' then
          wait until RXB0CON.RXFUL == '0';
        end if;
        readline(event_file, report_line);
        report(report_line);
        read(event_file, RXB0D0, 1);
        read(event_file, RXB0D1, 1);
        read(event_file, RXB0D2, 1);
        read(event_file, RXB0D3, 1);
        read(event_file, RXB0D4, 1);
        RXB0CON.RXFUL <= '1';
        RXB0DLC.DLC3 <= '1';
        CANSTAT <= 16#0C#;
        PIR3.RXB0IF <= '1';
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
      if test_state == pass then
        report("test_name: PASS");
      else
        report("test_name: FAIL");
      end if;          
      PC <= 0;
      wait;
    end process test_name;
end testbench;
