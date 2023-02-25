include(common.inc)dnl
define(test_name, slim_learn_short_no_space_test)dnl
configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 333 ms;
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
      wait until RB7 == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      -- Learn events for output 3
      RB4 <= '0'; -- Learn on
      RB0 <= '0'; -- Sel 0 on
      RB1 <= '1'; -- Sel 1 off
      RB5 <= '1'; -- Polarity normal, On event => A, Off event => B
      --
      report("test_name: Short On 0x0102, 0x0180");
      RXB0D0 <= 16#98#;    -- ACON, CBUS accessory short on
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
      wait until PORTC == 0;
      --
      if TXB1CON.TXREQ == '1' then
        report("test_name: Unexpected message");
        test_state := fail;
      end if;
      --
      report("test_name: Learnt 128 events");
      --
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Short On 0x0102, 0x0181");
      RXB0D0 <= 16#98#;    -- ACON, CBUS accessory short on
      RXB0D1 <= 1;         -- NN high
      RXB0D2 <= 2;         -- NN low
      RXB0D3 <= 2;
      RXB0D4 <= 129;
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      report("test_name: Awaiting CMDERR");
      wait until TXB1CON.TXREQ == '1';
      if TXB1D0 != 16#6F# then -- CMDERR, CBUS error response
        report("test_name: Sent wrong response");
        test_state := fail;
      end if;
      if TXB1D1 != 0 then
        report("test_name: Sent wrong Node Number (high)");
        test_state := fail;
      end if;
      if TXB1D2 != 0 then
        report("test_name: Sent wrong Node Number (low)");
        test_state := fail;
      end if;
      if TXB1D3 != 4 then -- No event space left
        report("test_name: Sent wrong error number");
        test_state := fail;
      end if;
      --
      -- FIXME yellow LED should flash
      --if RB6 == '0' then
      --  wait until RB6 == '1';
      --end if;
      --wait until RB6 == '1';
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
