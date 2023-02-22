define(check_tx_can_id,
       if TXB1SIDH != $2 then
         report("test_name: Incorrect $1 CAN Id SIDH");
         test_state := fail;
       end if;
       if TXB1SIDL != $3 then
         report("test_name: Incorrect $1 CAN Id SIDL");
         test_state := fail;
       end if;)dnl
define(tx_ready,
       TXB1CON.TXREQ <= '0';
       wait until TXB1CON.TXREQ == '1';)dnl
define(tx_rtr,
       tx_ready()
       if TXB1DLC.TXRTR == '1' then
         report("test_name: RTR request");
       else
         report("test_name: not RTR request");
         test_state := fail;
       end if;)dnl
define(rx_frame,
       RXB0CON.RXFUL <= '1';
       CANSTAT <= 16#0C#;
       PIR3.RXB0IF <= '1';)dnl
define(rx_ready,
       if RXB0CON.RXFUL != '0' then
         wait until RXB0CON.RXFUL == '0';
       end if;)dnl
define(rx_sid,
       rx_ready()
       RXB0SIDH <= $1;
       RXB0SIDL <= $2;
       RXB0DLC <= 0;
       rx_frame())dnl
define(rx_2_data,
       rx_ready()
       RXB0D0 <= $1;
       RXB0D1 <= $2;
       RXB0D2 <= $3;
       RXB0DLC.DLC3 <= '1';
       rx_frame())dnl
define(rx_1_data,
       rx_2_data($1, $2, 0))dnl
define(rx_0_data,
       rx_1_data($1, 0))dnl
