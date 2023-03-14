define(output_check_changed_to,
       if $1 == $2 then
         report($3);
       else
         report("test_name: Output not changed to expected value");
         test_state := fail;
       end if;)dnl
define(output_check_changed_from,
       if $1 != $2 then
         report($3);
       else
         report("test_name: Output not changed");
         test_state := fail;
       end if;)dnl
define(output_check_pulse_time,
       wait until $1 == 0 for $2 ms;
       if $1 == 0 then
         report("test_name: Pulse too short");
         test_state := fail;
       end if;)dnl
define(output_wait_for_output,
       {wait until $1 != 0;}
       {output_check_changed_to($1, $2, $3)})dnl
define(output_wait_for_pulse,
       {output_wait_for_output($1, $2, $3)}
       {ifelse($4, {}, wait until $1 == 0;, output_check_pulse_time($1, $4))})dnl
define(output_wait_for_data_file_pulse,
        readline(data_file, trigger_report);
        while match(trigger_report, "Done") == false loop
          data_file_read(trigger_val)
          {output_wait_for_pulse($1, trigger_val, trigger_report)}
          readline(data_file, trigger_report);
        end loop;)dnl
