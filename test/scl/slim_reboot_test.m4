define(test_name, slim_reboot_test)dnl
include(common.inc)dnl
include(rx_tx.inc)dnl
include(hardware.inc)dnl
configuration for "processor_type" is
  shared label    _CANInit;
  shared label    _CANMain;
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(902)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    begin
      report("test_name: START");
      test_state := pass;
      setup_button <= '1'; -- Setup button not pressed
      --
      wait until slim_led == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      report("test_name: Reboot request addressed to node 0x0402");
      rx_data(16#5C#, 4, 2) -- BOOTM, CBUS bootload mode request, node 4 2
      --
      wait until slim_led == '0' for 6 ms; -- Wait for LED output reset on reboot
      if slim_led == '0' then
        report("test_name: Unexpected reboot");
        test_state := fail;
      end if;
      --
      report("test_name: Reboot request addressed to node 0x0400");
      rx_data(16#5C#, 4, 0) -- BOOTM, CBUS bootload mode request, node 4 0
      --
      wait until slim_led == '0' for 6 ms; -- Wait for LED output reset on reboot
      if slim_led == '0' then
        report("test_name: Unexpected reboot");
        test_state := fail;
      end if;
      --
      report("test_name: Reboot request addressed to node 0x0002");
      rx_data(16#5C#, 0, 2) -- BOOTM, CBUS bootload mode request, node 0 2
      --
      wait until slim_led == '0' for 6 ms; -- Wait for LED output reset on reboot
      if slim_led == '0' then
        report("test_name: Unexpected reboot");
        test_state := fail;
      end if;
      --
      report("test_name: Reboot request addressed to node 0x0000");
      rx_data(16#5C#, 0, 0) -- BOOTM, CBUS bootload mode request, node 0 0
      --
      wait until slim_led == '0'; -- Wait for LED output reset on reboot
      report("test_name: Reboot");
      --
      wait until PC == 0;
      PC <= _CANInit;
      --
      wait until PC == _CANMain;
      report("test_name: Reached _CANMain, in bootloader");
      --
      end_test
    end process test_name;
end testbench;
