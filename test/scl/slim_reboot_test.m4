include(common.inc)dnl
define(test_name, slim_reboot_test)dnl
include(rx_tx.inc)dnl
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
      rx_data(16#5C#, 4, 2) -- BOOTM, CBUS bootload mode request, node 4 2
      --
      wait until RB7 == '0' for 6 ms; -- Wait for LED output reset on reboot
      if RB7 == '0' then
        report("test_name: Unexpected reboot");
        test_state := fail;
      end if;
      --
      report("test_name: Reboot request addressed to node 0x0400");
      rx_data(16#5C#, 4, 0) -- BOOTM, CBUS bootload mode request, node 4 0
      --
      wait until RB7 == '0' for 6 ms; -- Wait for LED output reset on reboot
      if RB7 == '0' then
        report("test_name: Unexpected reboot");
        test_state := fail;
      end if;
      --
      report("test_name: Reboot request addressed to node 0x0002");
      rx_data(16#5C#, 0, 2) -- BOOTM, CBUS bootload mode request, node 0 2
      --
      wait until RB7 == '0' for 6 ms; -- Wait for LED output reset on reboot
      if RB7 == '0' then
        report("test_name: Unexpected reboot");
        test_state := fail;
      end if;
      --
      report("test_name: Reboot request addressed to node 0x0000");
      rx_data(16#5C#, 0, 0) -- BOOTM, CBUS bootload mode request, node 0 0
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
