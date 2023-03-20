define(test_name, flim_modify_test)dnl
include(common.inc)dnl
include(data_file.inc)dnl
include(rx_tx.inc)dnl
include(io.inc)dnl
include(hardware.inc)dnl
include(cbusdefs.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(31811)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state     : test_result;
    file     data_file      : text;
    variable file_stat      : file_open_status;
    variable file_line      : string;
    variable pulse_report : string;
    variable pulse_val    : integer;
    begin
      report("test_name: START");
      test_state := pass;
      setup_button <= '1'; -- Setup button not pressed
      dolearn_switch <= '1'; -- Learn off
      unlearn_switch <= '1'; -- Unlearn off
      --
      wait until flim_led == '1'; -- Booted into FLiM
      report("test_name: Yellow LED (FLiM) on");
      --
      rx_data(OPC_NNLRN, 4, 2) -- NNLRN, CBUS enter learn mode to node 4 2
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      --
      report("test_name: Modify events");
      data_file_open(modify.dat)
      --
      while endfile(data_file) == false loop
        data_file_report_line
        --
        rx_wait_if_not_ready
        RXB0D0 <= OPC_EVLRN;    -- EVLRN, CBUS learn event
        read(data_file, RXB0D1, 1);
        read(data_file, RXB0D2, 1);
        read(data_file, RXB0D3, 1);
        read(data_file, RXB0D4, 1);
        read(data_file, RXB0D5, 1);
        read(data_file, RXB0D6, 1);
        rx_frame(7)
        tx_wait_for_node_message(OPC_WRACK, 4, 2) -- WRACK, CBUS write acknowledge response node 4 2
        --
        readline(data_file, file_line);
        while match(file_line, "Done") == false loop
          data_file_read(pulse_val)
          --
          output_wait_for_pulse(PORTC, pulse_val, file_line)
          --
          readline(data_file, file_line);
        end loop;
        --
        output_check_no_pulse(PORTC, 1005)
      end loop;
      --
      file_close(data_file);
      --
      report("test_name: Exit learn mode");
      rx_data(OPC_NNULN, 4, 2) -- NNULN, CBUS exit learn mode to node 4 2
      --
      rx_data(OPC_NNEVN, 4, 2) -- NNEVN, CBUS request available event space, node 4 2
      tx_wait_for_node_message(OPC_EVNLF, 4, 2, 123, available event space) -- EVLNF, CBUS available event space response
      --
      report("test_name: Check number of stored events");
      rx_data(OPC_RQEVN, 4, 2) -- RQEVN, CBUS request number of stored events to node 4 2
      tx_wait_for_node_message(OPC_NUMEV, 4, 2, 5, number of stored events) -- NUMEV, CBUS number of stored event response node 4 2
      --
      report("test_name: Check modified events");
      data_file_open(modified_events.dat)
      --
      while endfile(data_file) == false loop
        data_file_report_line
        rx_wait_if_not_ready
        rx_data_file_event
        --
        output_wait_for_data_file_pulse(PORTC)
        --
        output_check_no_pulse(PORTC, 1005)
      end loop;
      --
      file_close(data_file);
      --
      end_test
    end process test_name;
end testbench;
