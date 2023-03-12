define(test_name, bootload_test)dnl
include(common.inc)dnl
configuration for "processor_type" is
  shared label    _CANMain;
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(1)
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    begin
      report("test_name: START");
      test_state := pass;
      --
      wait until PC == _CANMain;
      report("test_name: Reached _CANMain");
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
