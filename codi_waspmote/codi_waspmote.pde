/*
  Waspmote llegeix:
    Sensors temperatura (3 DS1820)
    Sensor overflow (cso) capacitiu miocrocom
    Sensor distància ultrasons maxbotix
  I envia les lectures via:
    LoRa SX1272 (libelium)

  TODO 1: afegir la data waspmote amb RTC
  TODO 2: enlloc de fer una sola lectura (loop), fes-ne 10 i després adormir 10 min
  TODO 3: variar sleep interval a sleep interval rain si es detecta cso
  TODO 4: implementar timeout pel send lora message
  TODO 5: guardar temperatura cada 2 min quan plou
 
*/
#include<WaspSX1272.h>
#include<WaspAES.h>

#define DEBUG               true               /*usb debugging*/
#define SLEEP_INTERVAL_DRY  "00:00:00:10"      /*deep sleep interval (dry weather)*/
#define SLEEP_INTERVAL_RAIN "00:00:00:01"      /*deep sleep interval when it is raining*/
#define NUM_LOOPS_DRY       10                 /*numero de loops fets abans de dormir*/
#define NUM_LOOPS_RAIN      60                 /*numero de loops fets abans de dormir*/

#define POWER               'L'                /*LoRa emission energy: Low(L) High(H) Max(M)*/
#define WASPMOTE_ID         1                  /*peñíscola waspmote identification (x of 5)*/
#define PIN_MICROCOM        DIGITAL1           /*pin microcom (cso detection)*/
#define PIN_T1              DIGITAL4           /*pin sensor temperatura 1*/
#define PIN_T2              DIGITAL6           /*pin sensor temperatura 2*/
#define PIN_T3              DIGITAL8           /*pin sensor temperatura 3*/
#define TIMEOUT             1000               /*maxbotix serial read timeout*/
#define MSG_LENGTH          200                /*max length missatge json*/
#define PASSWORD            "libeliumlibelium" /*private a 16-Byte key to encrypt message*/
#define RX_ADDRESS          1                  /*destination address (lora gateway) to send packets*/

unsigned int paquets_enviats = 0;
unsigned int numero_loop_actual = 0;

void setup(){
  RTC.setTime()

  //inicia USB i mostra id waspmote
  if(DEBUG){
    USB.ON();
    USB.print(F("Waspmote id: "));
    USB.println(WASPMOTE_ID);
  }

  //configura microcom capacitiu detector cso
  pinMode(PIN_MICROCOM,INPUT);

  //inicia pins alimentació
  PWR.setSensorPower(SENS_3V3,SENS_ON);
  PWR.setSensorPower(SENS_5V,SENS_ON);

  //configura maxbotix sensor distància ultrasons
  Utils.setMuxAux1();
  beginSerial(9600,1);

  //LoRa configuration
  sx1272.ON();
  int8_t e; //status
  e=sx1272.setChannel(CH_12_868); if(DEBUG){USB.print("set channel: ");     USB.println(e);} //frequency channel
  e=sx1272.setHeaderON();         if(DEBUG){USB.print("set header on: ");   USB.println(e);} //implicit or explicit header mode
  e=sx1272.setMode(1);            if(DEBUG){USB.print("set mode 1: ");      USB.println(e);} //mode: from 1 to 10
  e=sx1272.setCRC_ON();           if(DEBUG){USB.print("set crc on: ");      USB.println(e);} //CRC on or off
  e=sx1272.setPower(POWER);       if(DEBUG){USB.print("set power: ");       USB.println(e);} //output power (Max, High or Low)
  e=sx1272.setNodeAddress(2);     if(DEBUG){USB.print("set node address: ");USB.println(e);} //the node address value: from 2 to 255

  delay(1000);
}

void loop(){
  //read battery level
  int   battery = PWR.getBatteryLevel(); //%
  float volts   = PWR.getBatteryVolts(); //V
  if(DEBUG){
    //show remaining battery level
    USB.print(F("Battery Level: "));
    USB.print(battery);
    USB.print(F(" %"));

    //show battery Volts
    USB.print(F(" | Battery (Volts): "));
    USB.print(volts);
    USB.println(F(" V"));

    //get charging state and current
    bool chargeState = PWR.getChargingState();

    //show battery charging state. This is valid for both USB and Solar panel
    //if any of those ports are used the charging state will be true
    USB.print(F("Battery charging state: "));
    if(chargeState){
      USB.println(F("Battery is charging"));
    }else{
      USB.println(F("Battery is not charging"));
    }
    USB.println(F("----------"));
  }

  //reading DS1820 temperature (ºC)
  if(DEBUG) USB.println(F("Reading temperature (ºC)..."));
  float temp1 = Utils.readTempDS1820(PIN_T1); if(DEBUG) USB.println(temp1);
  float temp2 = Utils.readTempDS1820(PIN_T2); if(DEBUG) USB.println(temp2);
  float temp3 = Utils.readTempDS1820(PIN_T3); if(DEBUG) USB.println(temp3);
 
  //read microcom overflow detector
  if(DEBUG) USB.println(F("Reading cso overflows (true/false)..."));
  bool cso_detected = digitalRead(PIN_MICROCOM); //true/false overflow
  if(DEBUG) USB.println(cso_detected);

  //read maxbotix distance sensor
  if(DEBUG) USB.println(F("Reading distance (cm)..."));
  int distance = readSensorSerial();
  if(DEBUG) USB.println(distance);
  if(DEBUG) USB.println(F("----------"));

  //construeix string json amb les dades llegides dels sensors
  char message[MSG_LENGTH];
  construct_json_message(
    message, 
    temp1, temp2, temp3, cso_detected, distance,
    battery, volts
  );

  //augmenta nombre paquets enviats (diferent de paquets rebuts gateway)
  paquets_enviats++;

  //envia string json al gateway via lora
  lora_send_message(message);

  //apaga alimentació
  PWR.setSensorPower(SENS_3V3,SENS_OFF);
  PWR.setSensorPower(SENS_5V,SENS_OFF);

  //compta el numero de loop actual
  numero_loop_actual++;

  //si no plou, dorm SLEEP_INTERVAL_DRY TODO
  if(numero_loop_actual >= NUM_LOOPS_DRY){
    //deep sleep
    if(DEBUG){
      USB.print(F("Entering deep sleep... "));
      USB.println(SLEEP_INTERVAL_DRY);
    }
    PWR.deepSleep(SLEEP_INTERVAL_DRY, RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
  }

  //wake up and reexecute setup() (necessary after deep sleep)
  if(DEBUG){
    USB.println(F("============================= "));
    USB.println(F("wake up!"));
  }
  setup();
}

//read maxbotix distance sensor
int readSensorSerial() {
  char buffer[5]; //5 bytes for "R000\0"
  serialFlush(1);

  //wait for incoming 'R' character or timeout
  int timeout = millis();
  while(!serialAvailable(1) || serialRead(1) != 'R'){
    if(millis()-timeout > TIMEOUT) break;
  }

  //read the range
  for(int i=0; i<4; i++){
    while(!serialAvailable(1)){
      if(millis()-timeout > TIMEOUT) break;
    }
    buffer[i]=serialRead(1);
  }
  buffer[4]='\0'; //add string terminating character
  return atoi(buffer);
}

//construct json string message
void construct_json_message( 
  char *message,
  float temp1, float temp2, float temp3, bool cso_detected, int distance,
  int battery, float volts
  ){
  //use dtostrf() to convert from float to string:
  //'1' refers to minimum width
  //'3' refers to number of decimals
  char t1[10]; dtostrf(temp1,1,3,t1);
  char t2[10]; dtostrf(temp2,1,3,t2);
  char t3[10]; dtostrf(temp3,1,3,t3);
  char vv[10]; dtostrf(volts,1,3,vv);

  //estructura json: {waspmote_id,temp1,temp2,temp3,cso_detected,distance}
  snprintf( message, MSG_LENGTH,
    "{waspmote_id:%d, t1:%s, t2:%s, t3:%s, cso_detected:%d, distance:%d, battery:%d, volts:%s, packets_sent:%d}", 
    WASPMOTE_ID,
    t1, t2, t3, cso_detected, distance,
    battery, vv,
    paquets_enviats
  );

  //make sure message length is multiple of 16 (for AES)
  while(strlen(message)%16 !=0){
    message = strcat(message," ");
  }
}

//encrypt and send message via lora
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
  if(DEBUG){ USB.println(F("Sending data via LoRa...")); }
  int8_t e;
  e = sx1272.sendPacketTimeoutACK(RX_ADDRESS, encrypted_message, encrypted_length);
  
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

  //retry if sending packet fails
  int retry=0;
  if(e!=0 && retry<10){
    if(DEBUG){ USB.println(F("Retry sending...")); }
    e = sx1272.sendPacketTimeoutACK(RX_ADDRESS, encrypted_message, encrypted_length);
    retry++;
  }
}
