/*
 * --- [SX_02a] - TX LoRa ---
 * This example shows how to configure the semtech module in LoRa 
 * mode and then send packets with plain-text payloads
 * http://www.libelium.com/development/waspmote/examples/sx-02a-tx-lora/
 */

//library to transmit with sx1272
#include <WaspSX1272.h>

//define the destination address to send packets
uint8_t rx_address=1;

//status variable
int8_t e;

void setup(){
  //init USB port
  USB.ON();

  //init sx1272 module
  sx1272.ON();

  //select frequency channel
  e=sx1272.setChannel(CH_12_868);
  USB.print(F("Setting Channel.\t state ")); 
  USB.println(e);

  //select implicit (off) or explicit (on) header mode
  e=sx1272.setHeaderON();
  USB.print(F("Setting Header.\t\t state "));  
  USB.println(e); 

  //select mode: from 1 to 10
  e=sx1272.setMode(1);  
  USB.print(F("Setting Mode.\t\t state "));
  USB.println(e);  

  //select CRC on or off
  e=sx1272.setCRC_ON();
  USB.print(F("Setting CRC.\t\t\t state "));
  USB.println(e);  

  //select output power (Max, High or Low)
  e=sx1272.setPower('L');
  USB.print(F("Setting Power.\t\t state "));  
  USB.println(e); 

  //select the node address value: from 2 to 255
  e=sx1272.setNodeAddress(2);
  USB.print(F("Setting Node Address.\t state "));
  USB.println(e);
  USB.println();
  
  //setup end
  delay(1000);
}

void loop(){
  //send packet before timeout
  e=sx1272.sendPacketTimeout(rx_address,"This_is_a_new_message");

  //check sending status
  if(e==0){
    USB.println(F("Packet sent OK"));     
  }else{
    USB.println(F("Error sending the packet"));  
    USB.print(F("state: "));
    USB.println(e, DEC);
  } 

  //loop end
  delay(2500); 
} 
