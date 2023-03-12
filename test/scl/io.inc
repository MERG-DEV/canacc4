define(output_check_pulse_time,
       wait until PORTC == 0 for $1 ms;
       if PORTC == 0 then
         report("test_name: Pulse too short");
         test_state := fail;
       end if;)dnl
define(output_check_output,
       if PORTC == $1 then
         report($2);
       else
         report("test_name: Wrong output");
         test_state := fail;
       end if;)dnl
define(output_wait_for_output,
       wait until PORTC != 0;
       {output_check_output($1, $2)})dnl
define(output_wait_for_pulse,
       {output_wait_for_output($1, $2)}
       {ifelse($3, {}, wait until PORTC == 0;, output_check_pulse_time($3))})dnl
define(output_wait_for_data_file_pulse,
        readline(data_file, trigger_report);
        while match(trigger_report, "Done") == false loop
          data_file_read(trigger_val)
          output_wait_for_pulse(trigger_val, trigger_report)
          readline(data_file, trigger_report);
        end loop;)dnl
