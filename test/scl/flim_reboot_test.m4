define(test_name, flim_reboot_test)dnl
configuration for "processor_type" is
  shared label    _CANInit;
  shared label    _CANMain;
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(28)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    begin
      report("test_name: START");
      test_state := pass;
      setup_button <= '1'; -- Setup button not pressed
      --
      wait until flim_led == '1'; -- Booted into FLiM
      report("test_name: Yellow LED (FLiM) on");
      --
      report("test_name: Ignore request addressed to Node 00");
      rx_data(OPC_BOOT, 0, 0) -- BOOTM, CBUS bootload mode request, node 0 0
      wait until flim_led == '0' for 6 ms; -- Wait for LED output reset on reboot
      if flim_led == '0' then
        report("test_name: Unexpected reboot");
        test_state := fail;
      end if;
      --
      report("test_name: Ignore request addressed to Node 0x40");
      rx_data(OPC_BOOT, 4, 0) -- BOOTM, CBUS bootload mode request, node 0 0
      wait until flim_led == '0' for 6 ms; -- Wait for LED output reset on reboot
      if flim_led == '0' then
        report("test_name: Unexpected reboot");
        test_state := fail;
      end if;
      --
      report("test_name: Ignore request addressed to Node 0x02");
      rx_data(OPC_BOOT, 0, 2) -- BOOTM, CBUS bootload mode request, node 0 0
      wait until flim_led == '0' for 6 ms; -- Wait for LED output reset on reboot
      if flim_led == '0' then
        report("test_name: Unexpected reboot");
        test_state := fail;
      end if;
      --
      report("test_name: Reboot request");
      rx_data(OPC_BOOT, 4, 2) -- BOOTM, CBUS bootload mode request, node 4 2
      wait until flim_led == '0'; -- Wait for LED output reset on reboot
      report("test_name: Rebooting");
      --
      wait until PC == 0;
      PC <= _CANInit; -- Avoid MDB breakpoint @0x0
      --
      wait until PC == _CANMain;
      report("test_name: Reached _CANMain, in bootloader");
      --
      end_test
    end process test_name;
end testbench;
