/*
  Waspmote llegeix:
    Sensors temperatura (3 DS1820)
    Sensor overflow (cso) capacitiu miocrocom
    Sensor distància ultrasons maxbotix
  I envia les lectures via:
    LoRa SX1272 (libelium)
*/
#include <WaspSX1272.h>
#include <WaspAES.h>

#define WASPMOTE_ID 1               /*id of waspmote*/
#define DEBUG true                  /*usb debugging*/
#define PASSWORD "libeliumlibelium" /*private a 16-Byte key to encrypt message*/
#define PIN_MICROCOM DIGITAL1       /*pin microcom*/
#define RX_ADDRESS 1                /*destination address to send packets*/
#define TIMEOUT 1000                /*maxbotix timeout serial read*/

/*SETUP*/
void setup(){
  //inicia USB i mostra id waspmote
  if(DEBUG){
    USB.ON();
    USB.print("Waspmote id: ");
    USB.println(WASPMOTE_ID);
  }

  //inicia pins alimentació
  PWR.setSensorPower(SENS_3V3,SENS_ON);
  PWR.setSensorPower(SENS_5V,SENS_ON);

  //configura microcom capacitiu detector cso
  pinMode(PIN_MICROCOM,INPUT);

  //configura lectura maxbotix
  Utils.setMuxAux1();
  beginSerial(9600,1);

  //configura lora
  sx1272.ON();
  int8_t e;//estat configuració
  e=sx1272.setChannel(CH_12_868); if(DEBUG){ USB.print("set channel: ");      USB.println(e);}
  e=sx1272.setHeaderON();         if(DEBUG){ USB.print("set header on: ");    USB.println(e);}
  e=sx1272.setMode(1);            if(DEBUG){ USB.print("set mode 1: ");       USB.println(e);}
  e=sx1272.setCRC_ON();           if(DEBUG){ USB.print("set crc on: ");       USB.println(e);}
  e=sx1272.setPower('L');         if(DEBUG){ USB.print("set power: ");        USB.println(e);}
  e=sx1272.setNodeAddress(2);     if(DEBUG){ USB.print("set node address: "); USB.println(e);}

  //setup end
  delay(1000);
}

/*LOOP*/
void loop(){
  //reading DS1820 temperature connected to DIGITAL{4,6,8} pins
  if(DEBUG){ USB.println("Reading temperature (ºC)...");}
  float temp1 = Utils.readTempDS1820(DIGITAL4); //ºC
  float temp2 = Utils.readTempDS1820(DIGITAL6); //ºC
  float temp3 = Utils.readTempDS1820(DIGITAL8); //ºC
  if(DEBUG){ 
    USB.println(temp1);
    USB.println(temp2);
    USB.println(temp3);
  }
 
  //read microcom overflow detector
  if(DEBUG){ USB.println("Reading cso overflows (0/1)..."); }
  bool cso_detected = digitalRead(PIN_MICROCOM); //true/false
  cso_detected = 1;
  if(DEBUG){ USB.println(cso_detected); }

  //read maxbotix distance sensor
  if(DEBUG){ USB.println("Reading distance (cm)..."); }
  int distance = readSensorSerial();
  if(DEBUG){ USB.println(distance); }

  //construeix json string missatge
  char message[200];
  construct_json_message(message, temp1, temp2, temp3, cso_detected, distance);

  //envia el missatge via lora
  lora_send_message(message);

  if(DEBUG) USB.println(F("=================================================="));

  delay(2000);
}

//read maxbotix distance sensor
int readSensorSerial() {
  int len=4; //length of reading is 4: "R000"
  char buffer[len+1]; //allocate 5 bytes of memory for "R000\0"
  serialFlush(1);

  //wait for incoming 'R' character or timeout
  int timeout = millis();
  while(!serialAvailable(1) || serialRead(1) != 'R'){
    if(millis()-timeout > TIMEOUT) break;
  }

  //read the range
  for(int i=0; i<len; i++){
    while(!serialAvailable(1)){
      if(millis()-timeout > TIMEOUT) break;
    }
    buffer[i]=serialRead(1);
  }
  buffer[len]='\0'; //add string terminating character
  return atoi(buffer);
}

//construeix json string missatge
void construct_json_message( char *message,
  float temp1, float temp2, float temp3, bool cso_detected, int distance){
  //use dtostrf() to convert from float to string:
  //'1' refers to minimum width
  //'3' refers to number of decimals
  char t1[10]; dtostrf(temp1,1,3,t1);
  char t2[10]; dtostrf(temp2,1,3,t2);
  char t3[10]; dtostrf(temp3,1,3,t3);

  //estructura json: {waspmote_id,temp1,temp2,temp3,cso_detected,distance}
  snprintf( message, 200,
    "{waspmote_id:%d, t1:%s, t2:%s, t3:%s, cso_detected:%d, distance:%d}", 
    WASPMOTE_ID, t1, t2, t3, cso_detected, distance
  );
}

//send json encrypted message via lora
void lora_send_message(char * message){
  //encrypt message
  if(DEBUG){
    USB.print(F("Original message:"));
    USB.println(message);
  }

  //calculate length in Bytes of the encrypted message 
  uint16_t encrypted_length = AES.sizeOfBlocks(message);

  //encrypted message
  uint8_t encrypted_message[300];

  //calculate encrypted message with ECB cipher mode and PKCS5 padding. 
  AES.encrypt(AES_128, PASSWORD, message, encrypted_message, ECB, PKCS5); 

  if(DEBUG){
    //printing encrypted message    
    USB.print(F("Encrypted message:")); 
    AES.printMessage(encrypted_message, encrypted_length); 
    //printing encrypted message's length 
    USB.print(F("Encrypted length:")); 
    USB.println( (int)encrypted_length);
  }

  //sending packet before ending a timeout and waiting for an ACK response  
  if(DEBUG){ USB.println("Sending data via LoRa..."); }
  int8_t e = sx1272.sendPacketTimeoutACK(RX_ADDRESS, encrypted_message, encrypted_length);
  
  //check sending status
  if(DEBUG){
    if(e==0){
      USB.println(F("--> Packet sent OK"));     
    }else{
      USB.println(F("--> Error sending the packet"));  
      USB.print(F("state: "));
      USB.println(e, DEC);
    } 
  }
}
