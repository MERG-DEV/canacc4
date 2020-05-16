configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 65 ms;
      report("slim_read_events_test: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  slim_read_events_test: process is
    type test_result is (pass, fail);
    variable test_state  : test_result;
    file     event_file  : text;
    variable file_stat   : file_open_status;
    variable file_line   : string;
    variable node_hi     : integer;
    variable node_lo     : integer;
    variable event_hi    : integer;
    variable event_lo    : integer;
    variable ev_index    : integer;
    begin
      report("slim_read_events_test: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- Learn off
      RA5 <= '1'; -- Unlearn off
      --
      wait until RB7 == '1'; -- Booted into SLiM
      report("slim_read_events_test: Green LED (SLiM) on");
      --
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("slim_read_events_test: Enter learn mode");
      RXB0D0 <= 16#53#;    -- NNLRN, CBUS enter learn mode
      RXB0D1 <= 4;         -- NN high
      RXB0D2 <= 2;         -- NN low
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      report("slim_read_events_test: Read events");
      file_open(file_stat, event_file, "./data/stored_events.dat", read_mode);
      if file_stat != open_ok then
        report("slim_read_events_test: Failed to open event data file");
        report("slim_read_events_test: FAIL");
        PC <= 0;
        wait;
      end if;
      --
      while endfile(event_file) == false loop
        readline(event_file, file_line);
        report(file_line);
        --
        readline(event_file, file_line);
        read(file_line, node_hi);
        readline(event_file, file_line);
        read(file_line, node_lo);
        readline(event_file, file_line);
        read(file_line, event_hi);
        readline(event_file, file_line);
        read(file_line, event_lo);
        --
        readline(event_file, file_line);
        while match(file_line, "Done") == false loop
          wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
          report(file_line);
          RXB0D0 <= 16#B2#; -- REQEV, CBUS Read event variable request
          RXB0D1 <= node_hi;
          RXB0D2 <= node_lo;
          RXB0D3 <= event_hi;
          RXB0D4 <= event_lo;
          read(file_line, ev_index);
          RXB0D5 <= ev_index;
          RXB0CON.RXFUL <= '1';
          RXB0DLC.DLC3 <= '1';
          CANSTAT <= 16#0C#;
          PIR3.RXB0IF <= '1';
          --
          TXB1CON.TXREQ <= '0';
          wait until TXB1CON.TXREQ == '1' for 2 ms; -- Test if response sent
          if TXB1CON.TXREQ == '1' then
            report("slim_read_events_test: Unexpected response");
            test_state := fail;
          end if;
          --
          readline(event_file, file_line);
          readline(event_file, file_line);
        end loop;
      end loop;
      --
      if test_state == pass then
        report("slim_read_events_test: PASS");
      else
        report("slim_read_events_test: FAIL");
      end if;          
      PC <= 0;
      wait;
    end process slim_read_events_test;
end testbench;
