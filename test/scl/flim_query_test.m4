include(common.inc)dnl
define(test_name, flim_query_test)dnl
configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 777 ms;
      report("test_name: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
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
      report("test_name: Query Node");
      RXB0D0 <= 16#0D#; -- QNN, CBUS Query node request
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      wait until TXB1CON.TXREQ == '1';
      if TXB1D0 != 16#B6# then -- PNN, CBUS Query node response
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
      if TXB1D3 != 165 then
        report("test_name: Sent wrong manufacturer id");
        test_state := fail;
      end if;
      if TXB1D4 != 8 then
        report("test_name: Sent wrong module id");
        test_state := fail;
      end if;
      if TXB1D5 != 13 then
        report("test_name: Sent wrong flags");
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
