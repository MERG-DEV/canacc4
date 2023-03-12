changecom(--)dnl
changequote({,})dnl
define(processor_type, PIC18F2480)dnl
define(stop_test,
       PC <= 0;
       wait;)dnl
define(end_test,
       if test_state == pass then
         report("test_name: PASS");
       else
         report("test_name: FAIL");
       end if;
       stop_test)dnl
define(timeout_process,
       test_timeout: process is
         begin
           wait for $1 ms;
           report("test_name: TIMEOUT");
           report(PC); -- Crashes simulator, MDB will report current source line
           stop_test
         end process test_timeout;)dnl
