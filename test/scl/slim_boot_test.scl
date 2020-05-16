configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 16958 ms;
      report("slim_boot_test: TIMEOUT");
      if RB6 == '1' then
        report("slim_boot_test: Yellow LED (FLiM) on");
      end if;
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  slim_boot_test: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    file     event_file : text;
    variable file_stat  : file_open_status;
    variable file_line  : string;
    begin
      report("slim_boot_test: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- DOLEARN off
      RA5 <= '1'; -- UNLEARN off
      --
      wait until RB7 == '1'; -- Booted into SLiM
      report("slim_boot_test: Green LED (SLiM) on");
      --
      file_open(file_stat, event_file, "./data/learnt_events.dat", read_mode);
      if file_stat != open_ok then
        report("slim_boot_test: Failed to open event data file");
        report("slim_boot_test: FAIL");
        PC <= 0;
        wait;
      end if;
      --
      report("slim_boot_test: Check events");
      while endfile(event_file) == false loop
        if RXB0CON.RXFUL != '0' then
          wait until RXB0CON.RXFUL == '0';
        end if;
        readline(event_file, file_line);
        report(file_line);
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
        while match(file_line, "Done") == false loop
          readline(event_file, file_line);
        end loop;
        --
        wait until PORTC != 0 for 1005 ms;
        if PORTC != 0 then
          report("slim_boot_test: Unexpected trigger");
          test_state := fail;
          wait until PORTC == 0;
        end if;
      end loop;
      --
      if RB6 == '1' then
        report("slim_boot_test: Yellow LED (FLiM) on");
        test_state := fail;
      end if;
      --
      if test_state == pass then
        report("slim_boot_test: PASS");
      else
        report("slim_boot_test: FAIL");
      end if;          
      PC <= 0;
      wait;
    end process slim_boot_test;
end testbench;
