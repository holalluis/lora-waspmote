/*
 * --- [SX_02a] - TX LoRa ---
 * http://www.libelium.com/development/waspmote/examples/sx-02a-tx-lora/
 * shield lora envia un paquet encriptat al gateway
 */
#include <WaspSX1272.h>
#include <WaspAES.h>

//destination address to send packets
uint8_t rx_address=1;

//private a 16-Byte key to encrypt message  
char password[] = "libeliumlibelium"; 

//original message on which the algorithm will be applied 
char message[] = "Hello, this is a test";

//status variable
int8_t e;

//encrypted message 
uint8_t encrypted_message[300]; 

//encrypted message's length
uint16_t encrypted_length;

void setup(){
  USB.ON();
  sx1272.ON();
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

  //encrypt message
  USB.print(F("Original message:"));
  USB.println(message);

  //calculate length in Bytes of the encrypted message 
  encrypted_length = AES.sizeOfBlocks(message);

  //calculate encrypted message with ECB cipher mode and PKCS5 padding. 
  AES.encrypt(  AES_128
    , password
    , message
    , encrypted_message
    , ECB
    , PKCS5); 

  //printing encrypted message    
  USB.print(F("Encrypted message:")); 
  AES.printMessage(encrypted_message, encrypted_length); 

  //printing encrypted message's length 
  USB.print(F("Encrypted length:")); 
  USB.println( (int)encrypted_length);

  //sending packet before ending a timeout and waiting for an ACK response  
  e=sx1272.sendPacketTimeoutACK(rx_address, encrypted_message, encrypted_length);
  
  // 2.2. Check sending status
  if(e==0) {
    USB.println(F("--> Packet sent OK"));     
  } else {
    USB.println(F("--> Error sending the packet"));  
    USB.print(F("state: "));
    USB.println(e, DEC);
  } 

  USB.println();
  delay(2000);
}

