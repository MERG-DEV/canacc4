configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 3 ms;
      report("flim_rtr_test: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  flim_rtr_test: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    variable test_sidl : integer;
    begin
      report("flim_rtr_test: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- DOLEARN off
      RA5 <= '1'; -- UNLEARN off
      --
      wait until RB6 == '1'; -- Booted into FLiM
      report("flim_rtr_test: Yellow LED (FLiM) on");
      --
      report("flim_rtr_test: Receive RTR");
      RXB0CON.RXFUL <= '1';
      RXB0DLC.RXRTR <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB2CON.TXREQ <= '0';
      wait until TXB2CON.TXREQ == '1';
      if TXB2SIDH != 16#B1# then
        report("flim_rtr_test: Incorrect SIDH");
        test_state := fail;
      end if;
      if TXB2SIDL != 16#80# then
        report("flim_rtr_test: Incorrect SIDL");
        test_state := fail;
      end if;
      if TXB2DLC != 0 then
        report("flim_rtr_test: Incorrect data length");
        test_state := fail;
      end if;
      --
      if test_state == pass then
        report("flim_rtr_test: PASS");
      else
        report("flim_rtr_test: FAIL");
      end if;          
      PC <= 0;
      wait;
    end process flim_rtr_test;
end testbench;
