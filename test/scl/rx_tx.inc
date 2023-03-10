define(tx_check_data,
       if $1 != $2 then
         report("test_name: Tx wrong $3");
         test_state := fail;
       end if;)dnl
define(tx_test_data,
       {ifelse( $2, {}, {--}, tx_check_data($1,  $2,   $3))})dnl
define(tx2_wait_if_not_ready,
       if TXB2CON.TXREQ == '0' then
         {ifelse($1, {}, report("test_name: Awaiting Tx2");, report("test_name: Awaiting Tx2 for $1 ms");)}
         {ifelse($1, {},   wait until TXB2CON.TXREQ == '1';,   wait until TXB2CON.TXREQ == '1' for $1 ms;)}
       end if;
       if TXB2CON.TXREQ == '1' then
         report("test_name: Tx2");
         TXB2CON.TXREQ <= '0';
       else
         {ifelse($1, {},   report("test_name: No Tx2");,   report("test_name: No Tx2 in $1 ms");)}
       end if;)dnl
define(tx_wait_for_rtr_response,
       tx2_wait_if_not_ready
       report("test_name: RTR response sent");
       {tx_check_data(TXB2SIDH,  $1,   RTR SIDH)}
       {tx_check_data(TXB2SIDL,  $2,   RTR SIDL)}
       {tx_check_data(TXB2DLC,    0,   RTR data length)})dnl
define(tx_check_no_rtr_response,
       {tx2_wait_if_not_ready($1)}
       if TXB2CON.TXREQ == '1' then
         report("test_name: Unexpected RTR response sent");
         test_state := fail;
       else
         report("test_name: No RTR response sent in $1 ms");
       end if;)dnl
define(tx_wait_if_not_ready,
       if TXB1CON.TXREQ == '0' then
         {ifelse($1, {}, report("test_name: Awaiting Tx");, report("test_name: Awaiting Tx for $1 ms");)}
         {ifelse($1, {}, wait until TXB1CON.TXREQ == '1';, wait until TXB1CON.TXREQ == '1' for $1 ms;)}
       end if;
       if TXB1CON.TXREQ == '1' then
         report("test_name: Tx");
         TXB1CON.TXREQ <= '0';
       else
         {ifelse($1, {}, report("test_name: No Tx");, report("test_name: No Tx in $1 ms");)}
       end if;)dnl
define(tx_wait_for_message,
       tx_wait_if_not_ready
       {tx_test_data(TXB1D0,  $1,   $2)}
       {tx_test_data(TXB1D1,  $3,   $4)}
       {tx_test_data(TXB1D2,  $5,   $6)}
       {tx_test_data(TXB1D3,  $7,   $8)}
       {tx_test_data(TXB1D4,  $9,  $10)}
       {tx_test_data(TXB1D5, $11,  $12)}
       {tx_test_data(TXB1D6, $13,  $14)}
       {tx_test_data(TXB1D7, $15,  $16)})dnl
define(tx_wait_for_node_message,
       {tx_wait_for_message($1, opcode, $2, Node Number (high), $3, Node Number (low), $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)})dnl
define(tx_wait_for_cmderr_message,
       {tx_wait_for_message(16#6F#, opcode, $1, Node Number (high), $2, Node Number (low), $3, error number)})dnl
define(tx_check_no_message,
       {ifelse($1, {}, {--}, tx_wait_if_not_ready($1))}
       if TXB1CON.TXREQ == '1' then
         report("test_name: Unexpected message sent");
         test_state := fail;
         TXB1CON.TXREQ <= '0';
       else
         {ifelse($1, {}, report("test_name: No message sent");, report("test_name: No message sent in $1 ms");)}
       end if;)dnl
define(tx_rtr,
       tx_wait_if_not_ready
       if TXB1DLC.TXRTR == '1' then
         report("test_name: RTR request");
       else
         report("test_name: not RTR request");
         test_state := fail;
       end if;)dnl
define(tx_check_can_id,
       if TXB1SIDH != $2 then
         report("test_name: Incorrect $1 CAN Id SIDH");
         test_state := fail;
       end if;
       if TXB1SIDL != $3 then
         report("test_name: Incorrect $1 CAN Id SIDL");
         test_state := fail;
       end if;)dnl
define(tx_can_id,
       tx_wait_if_not_ready
       tx_check_can_id($1, $2, $3))dnl
define(rx_wait_if_not_ready,
       if RXB0CON.RXFUL != '0' then
         report("test_name: Waiting to Rx");
         wait until RXB0CON.RXFUL == '0';
         report("test_name: Ready to Rx");
       end if;)dnl
define(rx_frame,
       RXB0DLC <= 16#0$1#;
       RXB0CON.RXFUL <= '1';
       CANSTAT <= 16#0C#;
       PIR3.RXB0IF <= '1';
       report("test_name: Rx");)dnl
define(rx_rtr,
       rx_wait_if_not_ready
       rx_frame(40))dnl
define(rx_sid,
       rx_wait_if_not_ready
       RXB0SIDH <= $1;
       RXB0SIDL <= $2;
       rx_frame(0))dnl
define(rx_load_data,
       {ifelse($2, {}, $1 <= 0;, $1 <= $2;)})dnl
define(rx_data,
       rx_wait_if_not_ready
       {rx_load_data(RXB0D0, $1)}
       {rx_load_data(RXB0D1, $2)}
       {rx_load_data(RXB0D2, $3)}
       {rx_load_data(RXB0D3, $4)}
       {rx_load_data(RXB0D4, $5)}
       {rx_load_data(RXB0D5, $6)}
       {rx_load_data(RXB0D6, $7)}
       {rx_load_data(RXB0D7, $8)}
       {rx_frame($#)})dnl
define(rxb1_wait_if_not_ready,
       if RXB1CON.RXFUL != '0' then
         report("test_name: Waiting to RxB1");
         wait until RXB1CON.RXFUL == '0';
         report("test_name: Ready to RxB1");
       end if;)dnl
define(rxb1_frame,
       RXB1DLC <= 16#0$1#;
       RXB1CON.RXFUL <= '1';
       CANSTAT <= 16#0A#;
       PIR3.RXB1IF <= '1';
       report("test_name: RxB1");)dnl
define(rxb1_data,
       rxb1_wait_if_not_ready
       {rx_load_data(RXB1D0, $1)}
       {rx_load_data(RXB1D1, $2)}
       {rx_load_data(RXB1D2, $3)}
       {rx_load_data(RXB1D3, $4)}
       {rx_load_data(RXB1D4, $5)}
       {rx_load_data(RXB1D5, $6)}
       {rx_load_data(RXB1D6, $7)}
       {rx_load_data(RXB1D7, $8)}
       {rxb1_frame($#)})dnl
