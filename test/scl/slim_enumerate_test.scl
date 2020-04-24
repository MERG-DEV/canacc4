configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 1654 ms;
      report("slim_enumerate_test: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  slim_enumerate_test: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    variable test_sidl : integer;
    begin
      report("slim_enumerate_test: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- DOLEARN off
      RA5 <= '1'; -- UNLEARN off
      --
      wait until RB7 == '1'; -- Booted into SLiM
      report("slim_enumerate_test: Green LED (SLiM) on");
      --
      report("slim_enumerate_test: Request enumerate");
      RXB0D0 <= 16#5D#; -- CBUS enumerate request
      RXB0D1 <= 0;      -- NN high
      RXB0D2 <= 0;      -- NN low
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1' for 776 ms; -- Test if response sent
      if TXB1CON.TXREQ == '1' then
        report("slim_enumerate_test: Unexpected response");
        test_state := fail;
      end if;
      --
      if test_state == pass then
        report("slim_enumerate_test: PASS");
      else
        report("slim_enumerate_test: FAIL");
      end if;          
      PC <= 0;
      wait;
    end process slim_enumerate_test;
end testbench;
