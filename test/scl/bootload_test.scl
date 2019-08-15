configuration for "PIC18F2480" is
  shared label    _CANMain;
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 1 ms;
      report("bootload_test: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
  bootload_test: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    begin
      report("bootload_test: START");
      test_state := pass;
      --
      wait until PC == _CANMain;
      report("bootload_test: Reached _CANMain");
      --
      if test_state == pass then
        report("bootload_test: PASS");
      else
        report("bootload_test: FAIL");
      end if;
      PC <= 0;
      wait;
    end process bootload_test;
end testbench;
