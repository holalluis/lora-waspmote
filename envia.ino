/*
  Waspmote
  Sensors temperatura (3 DS1820)
  Sensor overflow (cso) capacitiu miocrocom
  Sensor distància ultrasons maxbotix
  LoRa SX1272
*/
#include <WaspSX1272.h>
#include <WaspAES.h>

#define PIN_MICROCOM DIGITAL1       /*pin microcom*/
#define RX_ADDRESS 1                /*destination address to send packets*/
#define PASSWORD "libeliumlibelium" /*private a 16-Byte key to encrypt message*/
char * message;                     /*original message on which the algorithm will be applied*/
int8_t e;                           /*status variable*/
uint8_t encrypted_message[300];     /*encrypted message*/
uint16_t encrypted_length;          /*encrypted message's length*/

/*SETUP*/
void setup(){
  USB.ON();

  //configura microcom capacitiu detector cso
  pinMode(PIN_MICROCOM,INPUT);
  PWR.setSensorPower(SENS_3V3,SENS_ON);

  //configura lora
  sx1272.ON();
  e=sx1272.setChannel(CH_12_868);
  e=sx1272.setHeaderON();
  e=sx1272.setMode(1);
  e=sx1272.setCRC_ON();
  e=sx1272.setPower('L');
  e=sx1272.setNodeAddress(2);

  //setup end
  delay(1000);
}

/*LOOP*/
void loop(){
  //reading DS1820 temperature sensors connected to DIGITAL{4,6,8} pins
  float temp1 = Utils.readTempDS1820(DIGITAL4); //ºC
  float temp2 = Utils.readTempDS1820(DIGITAL6); //ºC
  float temp3 = Utils.readTempDS1820(DIGITAL8); //ºC
 
  //reading microcom
  bool cso_detected = digitalRead(PIN_MICROCOM); //true/false

  //construeix json string missatge

  delay(2000);
}

//send json encrypted message via lora
void send_message(uint8_t * message, uint8_t length){
  //encrypt message
  USB.print(F("Original message:"));
  USB.println(message);

  //calculate length in Bytes of the encrypted message 
  encrypted_length = AES.sizeOfBlocks(message);

  //calculate encrypted message with ECB cipher mode and PKCS5 padding. 
  AES.encrypt(AES_128, PASSWORD, message, encrypted_message, ECB, PKCS5); 

  //printing encrypted message    
  USB.print(F("Encrypted message:")); 
  AES.printMessage(encrypted_message, encrypted_length); 

  //printing encrypted message's length 
  USB.print(F("Encrypted length:")); 
  USB.println( (int)encrypted_length);

  //sending packet before ending a timeout and waiting for an ACK response  
  e=sx1272.sendPacketTimeoutACK(RX_ADDRESS, encrypted_message, encrypted_length);
  
  //check sending status
  if(e==0) {
    USB.println(F("--> Packet sent OK"));     
  } else {
    USB.println(F("--> Error sending the packet"));  
    USB.print(F("state: "));
    USB.println(e, DEC);
  } 
}
