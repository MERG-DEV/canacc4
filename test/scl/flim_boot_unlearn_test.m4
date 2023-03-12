define(test_name, flim_boot_unlearn_test)dnl
include(common.inc)dnl
include(data_file.inc)dnl
include(rx_tx.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(23285)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state  : test_result;
    file     data_file   : text;
    variable file_stat   : file_open_status;
    variable file_line   : string;
    variable trigger_val : integer;
    begin
      report("test_name: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- DOLEARN off
      RA5 <= '0'; -- UNLEARN on
      --
      wait until RB6 == '1'; -- Booted into FLiM
      report("test_name: Yellow LED (FLiM) on");
      --
      RB5 <= '1'; -- UNLEARN off
      --
      report("test_name: Check available event space");
      rx_data(16#56#, 4, 2) -- NNEVN, CBUS request available event space to node 4 2
      tx_wait_for_node_message(16#70#, 4, 2, 123, available event space) -- EVLNF, CBUS available event space response node 4 2
      --
      report("test_name: Check number of stored events");
      rx_data(16#58#, 4, 2) -- RQEVN, CBUS request number of stored events to node 4 2
      tx_wait_for_node_message(16#74#, 4, 2, 5, number of stored events) -- EVLNF, CBUS available event space response node 4 2
      --
      report("test_name: Check events");
      data_file_open(learnt_events.dat)
      --
      while endfile(data_file) == false loop
        rx_wait_if_not_ready
        data_file_report_line
        rx_data_file_event
        --
        readline(data_file, file_line);
        while match(file_line, "Done") == false loop
          data_file_read(trigger_val)
          --
          wait until PORTC != 0;
          if PORTC == trigger_val then
            report(file_line);
         else
            report("test_name: Wrong output");
            test_state := fail;
          end if;
          wait until PORTC == 0;
          --
          readline(data_file, file_line);
        end loop;
        --
        wait until PORTC != 0 for 1005 ms;
        if PORTC != 0 then
          report("test_name: Unexpected trigger");
          test_state := fail;
          wait until PORTC == 0;
        end if;
      end loop;
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
