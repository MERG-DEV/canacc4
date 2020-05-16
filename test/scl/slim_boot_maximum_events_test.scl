configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 88 ms;
      report("slim_boot_maximum_events_test: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  slim_boot_maximum_events_test: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    begin
      report("slim_boot_maximum_events_test: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- DOLEARN off
      RA5 <= '1'; -- UNLEARN off
      --
      wait until RB7 == '1'; -- Booted into SLiM
      report("slim_boot_maximum_events_test: Green LED (SLiM) on");
      --
      report("slim_boot_maximum_events_test: Long on 0x0102,0x0201");
      RXB0D0 <= 16#90#;    -- ACON, CBUS accessory on
      RXB0D1 <= 1;         -- NN high
      RXB0D2 <= 2;         -- NN low
      RXB0D3 <= 1;
      RXB0D4 <= 128;
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      wait until PORTC != 0;
      if PORTC == 32 then
        report("slim_boot_maximum_events_test: Trigger 3A");
      else
        report("slim_boot_maximum_events_test: Wrong output");
        test_state := fail;
      end if;
      --
      if test_state == pass then
        report("slim_boot_maximum_events_test: PASS");
      else
        report("slim_boot_maximum_events_test: FAIL");
      end if;          
      PC <= 0;
      wait;
    end process slim_boot_maximum_events_test;
end testbench;
