include(common.inc)dnl
define(test_name, slim_teach_test)dnl
configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 2661 ms;
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
      wait until RB7 == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Enter learn mode");
      RXB0D0 <= 16#53#;    -- NNLRN, CBUS enter learn mode
      RXB0D1 <= 0;         -- NN high
      RXB0D2 <= 0;         -- NN low
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Teach long 0x0102,0x0402");
      RXB0D0 <= 16#D2#;    -- EVLRN, CBUS learn event
      RXB0D1 <= 1;         -- NN high
      RXB0D2 <= 2;         -- NN low
      RXB0D3 <= 4;
      RXB0D4 <= 2;
      RXB0D5 <= 1;         -- Event variable index, triggers
      RXB0D6 <= 4;         -- Event variable value, trigger 3A
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1' for 776 ms; -- Test if response sent
      if TXB1CON.TXREQ == '1' then
        report("test_name: Unexpected response");
        test_state := fail;
      end if;
      --
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Exit learn mode");
      RXB0D0 <= 16#54#;    -- NNULN, exit learn mode
      RXB0D1 <= 0;         -- NN high
      RXB0D2 <= 0;         -- NN low
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Test long on 0x0102,0x0402");
      RXB0D0 <= 16#90#;  -- ACON, CBUS long on
      RXB0D1 <= 1;       -- NN high
      RXB0D2 <= 2;       -- NN low
      RXB0D3 <= 4;       -- Event number high
      RXB0D4 <= 2;       -- Event number low
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      wait until PORTC != 0 for 1005 ms;
      if PORTC != 0 then
        report("test_name: Unexpected trigger");
        test_state := fail;
        wait until PORTC == 0;
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
