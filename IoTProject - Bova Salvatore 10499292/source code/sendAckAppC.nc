/**
 *  Configuration file for wiring of sendAckC module to other common 
 *  components needed for proper functioning
 *
 *  @author Luca Pietro Borsani
 */

#include "sendAck.h"

configuration sendAckAppC {}

implementation {

  components MainC, sendAckC as App;
  components new TimerMilliC();
  components new TimerMilliC() as timer2;
  components new TimerMilliC() as timer3;
  components new TimerMilliC() as timer4;
  components new TimerMilliC() as timer5;
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  components RandomMlcgC;
  components ActiveMessageC;
  
  components SerialActiveMessageC as AM;

  //Boot interface
  App.Boot -> MainC.Boot;
  
  //Send and Receive interfaces
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.SerialSplitControl -> AM;
  App.AMSerialSend -> AM.AMSend[AM_SERIAL_MSG];
  
  //Interfaces to access package fields
  App.AMPacket -> AMSenderC;
  App.Packet -> AMSenderC;
  App.PacketAcknowledgements->ActiveMessageC;
  App.SerialPacket -> AM;
  
  //Radio Control
  App.SplitControl -> ActiveMessageC;

  //Timer interface
  App.garbageTimer -> TimerMilliC;
  App.truckTimer -> timer2;
  App.toTruckTimer -> timer3;
  App.binTimer -> timer4;
  App.waitTimer -> timer5;

  
  //Random component
  App.valueTimer -> RandomMlcgC;
  App.valueUnits -> RandomMlcgC;
  App.SeedInit -> RandomMlcgC;

}

