define(data_file_open,
       file_open(file_stat, data_file, "./data/$1", read_mode);
       if file_stat != open_ok then
         report("test_name: Failed to open unlearn $1");
         report("test_name: FAIL");
         PC <= 0;
         wait;
       end if;)dnl
define(data_file_report_line,
       readline(data_file, file_line);
       report(file_line);)dnl
define(data_file_read,
       readline(data_file, file_line);
       read(file_line, $1);)dnl
