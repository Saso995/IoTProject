/**

 *  Source file for implementation of module sendAckC in which

 *  the node 1 send a request to node 2 until it receives a response.

 *  The reply message contains a reading from the Fake Sensor.

 *

 *  @author Luca Pietro Borsani

 */



#include "sendAck.h"
#include "Timer.h"

module sendAckC {
//interface that we use
  uses {
	interface Boot; //always here and it's the starting point
	//for turn on the radio
    	interface SplitControl;
    	//timer needed
    	interface Timer<TMilli> as garbageTimer; //when it fired new garbage it's generated
    	interface Timer<TMilli> as truckTimer;   //when it fired the truck arrives to the bin
    	interface Timer<TMilli> as toTruckTimer; //when it fired a msg it's send to the truck
    	interface Timer<TMilli> as binTimer;	// when it fired the bins send their availability to collect other's garbage
    	interface Timer<TMilli> as waitTimer;	//time that a bin waits to receive availability responses from the others
	interface Random as valueTimer;		//random value to generate the time between two garbage
	interface Random as valueUnits;		//random value to generate the quantity of garbage
	interface ParameterInit<uint16_t> as SeedInit; //seed to randomize differently all the values
	//interfaces for communications
	interface AMPacket; 
	interface Packet;
	interface PacketAcknowledgements;
    	interface AMSend;
    	interface Receive; 	
    	interface AMSend as AMSerialSend;
    	interface Packet as SerialPacket;
	interface SplitControl as SerialSplitControl;
  }
} implementation {
  uint8_t rec_id;	//id of a node that receives a msg
  message_t packet;
  uint8_t capacity = 0; //capacity of the bins 
  uint8_t garbage = 0;  //quantity of garbage to put in a bin
  uint8_t x;		//position of a node
  uint8_t y;		//position of a node
  uint8_t distance;	//value of the distance between node
  uint8_t minDistance = 100000; //value usued to decide which bin it's the closest to another
  uint8_t normal_status = 0;	//if 0 a bin can receive garbage from the other, 1 it cannot
  uint8_t randomTimer;		//containts the random value of the timers
  uint8_t drop = 0;		//flag to allow the bin truck to drop a message if it's already moving to a bin
  uint8_t mess_type = 0;	//value that contains the type of the message send/received
  uint8_t closestNeighbour = 0;	//closest available bin to another that has to send its garbage

  task void fillBin();		
  task void callTruck();
  task void truckArrived();
  task void sendMoveMsg();
  task void sendAvailability();
  task void sendGarbage();

  //***************** Bin sends request to other bins ********************//

  task void sendMoveMsg() {

  	my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
  	mess->msg_type = BB;
  	mess->node_id = TOS_NODE_ID;	

	if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t)) == SUCCESS){
	  dbg("radio_send", "Packet passed to lower layer successfully!\n");
	  dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
	  dbg_clear("radio_pack","\t Destination: %hhu \n", call AMPacket.destination( &packet ) );
	  
      	  call waitTimer.startOneShot( 2000 );
      }
  }

  
  //***************** Truck arrives and sends messagge to bin ********************//
  task void truckArrived() {
  	
	my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
  	mess->msg_type = TB;
  	mess->node_receiver = rec_id;
  	//set a flag informing the receiver that the message must be acknoledge
	call PacketAcknowledgements.requestAck( &packet );
	if(call AMSend.send(rec_id,&packet,sizeof(my_msg_t)) == SUCCESS){
		dbg("radio_send", "Packet passed to lower layer successfully!\n"); 
      	}
	drop = 0;
   }

  
  //***************** Bin sends request to truck ********************//

  task void callTruck() {

	//prepare a msg
	my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_type = BT;
	mess->node_id = TOS_NODE_ID;
	mess->node_x = x;
	mess->node_y = y;

	dbg("radio_send", "Try to send a request to the truck at time %s \n", sim_time_string());

	//1 is the unicast address of the truck
	if(call AMSend.send(1,&packet,sizeof(my_msg_t)) == SUCCESS){
	  dbg("radio_send", "Packet passed to lower layer successfully!\n");
	  dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	  dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
	  dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
	  dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
	  dbg_clear("radio_pack","\t\t Payload \n" );
	  dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
	  dbg_clear("radio_pack", "\t\t node_id: %hhu \n", mess->node_id);
	  dbg_clear("radio_pack", "\t\t position x of the node: %hhu \n", mess->node_x);
	  dbg_clear("radio_pack", "\t\t position y of the node: %hhu \n", mess->node_y);
	  dbg_clear("radio_send", "\n ");
	  dbg_clear("radio_pack", "\n");
      }
 } 

 

   //***************** Bin sends its availability to another bin that asks help ********************//

  task void sendAvailability() {

	//prepare a msg
	my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_type = BBR;
	mess->node_id = TOS_NODE_ID;
	mess->node_x = x;
	mess->node_y = y;
  
	//rec_id is the unicast address of the bin that asked help

	if(call AMSend.send(rec_id,&packet,sizeof(my_msg_t)) == SUCCESS){
	  dbg("radio_send", "Packet passed to lower layer successfully!\n");
	  dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	  dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
	  dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
	  dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
	  dbg_clear("radio_pack","\t\t Payload \n" );
	  dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
	  dbg_clear("radio_pack", "\t\t node_id: %hhu \n", mess->node_id);
	  dbg_clear("radio_pack", "\t\t position x of the node: %hhu \n", mess->node_x);
	  dbg_clear("radio_pack", "\t\t position y of the node: %hhu \n", mess->node_y);
	  dbg_clear("radio_send", "\n ");
	  dbg_clear("radio_pack", "\n");
      }
 } 

  

   //***************** Task to fill the bin ********************//

  task void fillBin() {

	dbg("role", "Somebody threw away %d units!\n", garbage );
	if (capacity + garbage< 85){
		normal_status = 0;
		capacity += garbage;
		dbg("role", "Inside me there are: %d units\n", capacity );
	}
	else if ((capacity + garbage) >= 85 && (capacity + garbage) < 100){
		normal_status = 1;
		capacity += garbage;
		dbg("role","Inside me (%d) there are %d units, I can still collect stuff but I will be full soon... Let's call the truck!\n",TOS_NODE_ID, capacity);
		//codice per inviare messaggio al truck
		call toTruckTimer.startPeriodic( 5000 );
	}
	else {
		dbg("role","I can't collect anymore stuff :( I have to send it to my neighbors...\n");
		//codice per inviare ai vicini
		post sendMoveMsg();
	}

	//after someone put stuff inside the bin, the timer for the next filling restart with a new random value
	randomTimer = (call valueTimer.rand16() %30)+1; 
  	dbg("role","My new random timer is: %d\n", randomTimer);
	call garbageTimer.startOneShot( randomTimer * 1000 );		
 }  

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	call SerialSplitControl.start();
	call SplitControl.start(); //start the random timer for the garbage
  }



  //***************** SplitControl interface ********************//

  event void SerialSplitControl.startDone(error_t err){}

  event void SplitControl.startDone(error_t err){
    if(err == SUCCESS) {
    	//code to set position of all the nodes:
    	//se si vuole compilare con make micaz o make telosb si deve rimuovere "sim_time_string()" lo uso per avere valori random diversi ad ogni esecuzione
	call SeedInit.init(TOS_NODE_ID+sim_time_string()); 
	x = (call valueTimer.rand16() % 100);
	y = (call valueTimer.rand16() % 100);
	dbg("role","I'm node %d, my position is x = %d , y = %d\n", TOS_NODE_ID, x, y);
	//the bin node start to fill themselves except for node 1 that is the truck 
	if ( TOS_NODE_ID != 1 ) {
	  randomTimer = (call valueTimer.rand16() %30)+1;
	  dbg("role","I'm node %d: my first random timer is: %d\n", TOS_NODE_ID , randomTimer);
	  call garbageTimer.startOneShot( randomTimer * 1000 );
	}
    }
    else{
	call SplitControl.start();

    }
  }

  event void SerialSplitControl.stopDone(error_t err){}  

  event void SplitControl.stopDone(error_t err){}

  void sendSerialPacket(uint8_t v){
      serial_msg_t* cm = (serial_msg_t*)call SerialPacket.getPayload(&packet, sizeof(serial_msg_t));
      if (cm == NULL) {return;}
      if (call SerialPacket.maxPayloadLength() < sizeof(serial_msg_t)) {
	return;
      }

      cm->sample_value = v;
      cm->node_id = TOS_NODE_ID;
      
      if (call AMSerialSend.send(AM_BROADCAST_ADDR, &packet, sizeof(serial_msg_t)) == SUCCESS) {
	dbg("role","Serial Packet sent...\n");
      }
}


  //***************** garbageTimer interface ********************//

  event void garbageTimer.fired() {
  	sendSerialPacket(1);
  	dbg("role","I'm node %d: my random timer fired at %s\n", TOS_NODE_ID, sim_time_string());
  	garbage = (call valueUnits.rand16() %10)+1;
  	post fillBin();	
  }

  

  //***************** truckTimer interface ********************//

  event void truckTimer.fired() {
  	sendSerialPacket(30+rec_id);
  	dbg("role","I'm the truck and I arrived at bin %d at time %s\n",rec_id, sim_time_string());
  	post truckArrived();
  }

  //***************** toTruckTimer interface ********************//

  event void toTruckTimer.fired() {
  	sendSerialPacket(2);
  	post callTruck();
  }

  

  //***************** binTimer interface ********************//

  event void binTimer.fired() {
  	post sendAvailability();
  }

  

  //***************** waitTimer interface ********************//

  event void waitTimer.fired() {
  	sendSerialPacket(4);
  	post sendGarbage();
  }

  //********************* AMSend interface ****************//

  event void AMSerialSend.sendDone(message_t* buf,error_t err) {}

  event void AMSend.sendDone(message_t* buf,error_t err) {
    if(&packet == buf && err == SUCCESS ) {
	dbg("radio_send", "Packet sent to node");
	if (TOS_NODE_ID != 1){
		dbg_clear("radio_ack", "(ack not needed)");
	}
	else{
		//check if ack is received
		if ( call PacketAcknowledgements.wasAcked( buf ) ) {
	  	dbg_clear("radio_ack", " %d and ack received", rec_id);
		} else {
	  	dbg_clear("radio_ack", "but ack was not received");
		}
	}
	dbg_clear("radio_send", " at time %s \n", sim_time_string());
    }
  }



  //***************************** Receive interface *****************//

  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	my_msg_t* mess=(my_msg_t*)payload;
	mess_type = mess -> msg_type;
		
	if (mess_type == BT && TOS_NODE_ID == 1){
		if ( drop == 0 ) {
			rec_id = mess->node_id;
			dbg("radio_rec","Message received from bin %d at time %s \n",rec_id, sim_time_string());
			dbg("radio_rec","Computing distance... \n");
			distance = sqrt(pow((mess->node_x - x),2) + pow((mess->node_y - y),2));
			dbg("radio_rec","distance: %d\n", distance);
			call truckTimer.startOneShot( distance * 1000 );	
			drop = 1;
			x = mess -> node_x;
			y = mess -> node_y;
		}
		else {
			dbg("radio_rec","Message dropped... at time %s \n", sim_time_string());
		}
	}
	else if (mess_type == TB && TOS_NODE_ID == mess->node_receiver){
		call toTruckTimer.stop();
		capacity = 0;
	}
	else if (mess_type == BB && TOS_NODE_ID != 1){
		if(normal_status == 0){
			call binTimer.startOneShot( 1500 );
			rec_id = mess->node_id;
			dbg("radio_rec","REQUEST FOR HELP RECEIVED\n");
		}
	}
	else if (mess_type == BBR && TOS_NODE_ID != 1){
		distance = sqrt(pow((mess->node_x - x),2) + pow((mess->node_y - y),2));
		if (minDistance > distance){
			closestNeighbour = mess->node_id;
			minDistance = distance;
		}
	 }
	else if (mess_type == BBG && TOS_NODE_ID != 1){
		garbage = mess->tot_garbage;
		dbg("radio_rec","NODE: %d received: %d... at time %s \n",TOS_NODE_ID, garbage, sim_time_string());
		post fillBin();
	}
    return buf;
  }


  //***************** Task to send garbage to another the bin ********************//

  task void sendGarbage(){
  	my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
 	if (closestNeighbour == 0){
 		dbg("radio_rec","No one is available, I have to drop the garbage\n");	
 	}
 	else{
 		dbg("radio_rec","I'm sending my garbage to %d\n", closestNeighbour);	
		mess->msg_type = BBG;
		mess->node_id = TOS_NODE_ID;
		mess->tot_garbage = garbage;
		dbg("radio_send", "Try to send a request to the truck at time %s \n", sim_time_string());

		//closestNeighbour is the unicast address of the bin closest
		if(call AMSend.send(closestNeighbour,&packet,sizeof(my_msg_t)) == SUCCESS){
	 		dbg("radio_send", "Packet passed to lower layer successfully!\n");
	  		dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	  		dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
	  		dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
	  		dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
	  		dbg_clear("radio_pack","\t\t Payload \n" );
	  		dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
	  		dbg_clear("radio_pack", "\t\t garbage sent: %hhu \n", mess->tot_garbage);
	  		closestNeighbour = 0;
      		}
 	}
  }
}


