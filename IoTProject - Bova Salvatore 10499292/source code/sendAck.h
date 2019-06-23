/**
 *  @author Luca Pietro Borsani
 */

#ifndef SENDACK_H
#define SENDACK_H

typedef nx_struct serial_msg {
  nx_uint16_t sample_value;
  nx_uint16_t node_id;
} serial_msg_t;

//payload of the msg
typedef nx_struct my_msg {
	nx_uint8_t msg_type; //request or response
	nx_uint16_t node_id;
	nx_uint16_t node_receiver;
	nx_uint16_t node_x;
	nx_uint16_t node_y;
	nx_uint16_t tot_garbage;
} my_msg_t;


#define BT 1 //bin to truck message (ALERT MSG REQUEST)
#define TB 2 //truck to bin message (ALERT MSG RESPONSE)
#define BB 3 //bin to bin messagge (a bin asks help to the other, MOVE MSG REQUEST)
#define BBR 4 //bin to bin message (the bin answered the help request, MOVE MSG RESPONSE)
#define BBG 5 //bin to bin message (the bin send its garbabe to who answered)

enum{
AM_MY_MSG = 6,
};

enum {
AM_SERIAL_MSG = 0x89,
};

#endif
