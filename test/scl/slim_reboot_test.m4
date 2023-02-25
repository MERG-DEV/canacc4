include(common.inc)dnl
define(test_name, slim_reboot_test)dnl
configuration for "PIC18F2480" is
  shared label    _CANInit;
  shared label    _CANMain;
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 902 ms;
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
      --
      wait until RB7 == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      report("test_name: Reboot request addressed to node 0x0402");
      RXB0D0 <= 16#5C#; -- BOOTM, CBUS bootload mode request
      RXB0D1 <= 4;      -- NN high
      RXB0D2 <= 2;      -- NN low
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      wait until RB7 == '0' for 6 ms; -- Wait for LED output reset on reboot
      if RB7 == '0' then
        report("test_name: Unexpected reboot");
        test_state := fail;
      end if;
      --
      wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Reboot request addressed to node 0x0400");
      RXB0D0 <= 16#5C#; -- BOOTM, CBUS bootload mode request
      RXB0D1 <= 4;      -- NN high
      RXB0D2 <= 0;      -- NN low
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      wait until RB7 == '0' for 6 ms; -- Wait for LED output reset on reboot
      if RB7 == '0' then
        report("test_name: Unexpected reboot");
        test_state := fail;
      end if;
      --
      wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Reboot request addressed to node 0x0002");
      RXB0D0 <= 16#5C#; -- BOOTM, CBUS bootload mode request
      RXB0D1 <= 0;      -- NN high
      RXB0D2 <= 2;      -- NN low
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      wait until RB7 == '0' for 6 ms; -- Wait for LED output reset on reboot
      if RB7 == '0' then
        report("test_name: Unexpected reboot");
        test_state := fail;
      end if;
      --
      wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Reboot request addressed to node 0x0000");
      RXB0D0 <= 16#5C#; -- BOOTM, CBUS bootload mode request
      RXB0D1 <= 0;      -- NN high
      RXB0D2 <= 0;      -- NN low
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      wait until RB7 == '0'; -- Wait for LED output reset on reboot
      report("test_name: Reboot");
      --
      wait until PC == 0;
      PC <= _CANInit;
      --
      wait until PC == _CANMain;
      report("test_name: Reached _CANMain, in bootloader");
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
