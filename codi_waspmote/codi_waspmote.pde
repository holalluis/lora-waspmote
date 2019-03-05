/*
  Waspmote llegeix:
    Sensors temperatura (3 DS1820)
    Sensor overflow (cso) capacitiu miocrocom
    Sensor distància ultrasons maxbotix
  I envia les lectures via:
    LoRa SX1272 (libelium)

  TODO 1: afegir la data waspmote amb RTC
  TODO 3: variar sleep interval a sleep interval rain si es detecta cso
  TODO 4: implementar timeout pel send lora message
  TODO 5: guardar temperatura cada 2 min quan plou
  TODO 6: debug only if battery is charging
*/

#include<WaspSX1272.h>
#include<WaspAES.h>

#define SLEEP_INTERVAL_DRY  "00:00:05:00"      /*deep sleep interval (dry weather)*/
#define SLEEP_INTERVAL_RAIN "00:00:01:00"      /*deep sleep interval when it is raining*/
#define NUM_LOOPS_DRY       1                  /*numero lectures seguides abans de dormir SLEEP_INTERVAL_DRY*/
#define NUM_LOOPS_RAIN      10                 /*numero lectures seguides abans de dormir SLEEP_INTERVAL_RAIN*/
#define POWER               'L'                /*LoRa emission energy: Low(L) High(H) Max(M)*/
#define PIN_MICROCOM        DIGITAL1           /*pin microcom (cso detection)*/
#define PIN_T1              DIGITAL4           /*pin sensor temperatura 1*/
#define PIN_T2              DIGITAL6           /*pin sensor temperatura 2*/
#define PIN_T3              DIGITAL8           /*pin sensor temperatura 3*/
#define TIMEOUT             3000               /*ms maxbotix serial read timeout*/
#define MSG_LENGTH          200                /*max length missatge json in bytes*/
#define PASSWORD            "libeliumlibelium" /*private a 16-Byte key to encrypt message*/
#define RX_ADDRESS          1                  /*destination address (lora gateway) to send packets*/

bool         debug              = false;       /*usb debugging*/
bool         chargeState        = false;       /*is battery charging?*/
unsigned int paquets_enviats    = 0;           /*number of sent packets*/
unsigned int numero_loop_actual = 0;           /*current loop number before deep sleep*/
bool         its_raining        = false;       /*it is raining?*/
char         wasp_id[17];                      /*wasp id*/

void setup(){
  //decide if debug is true or false according to chargeState
  //get charging state and current
  chargeState = PWR.getChargingState();
  debug = chargeState;

  //get wasp id
  Utils.readSerialID();
  snprintf(
    wasp_id, 16, "%x%x%x%x%x%x%x%x",
    _serial_id[0], _serial_id[1], _serial_id[2], _serial_id[3],
    _serial_id[4], _serial_id[5], _serial_id[6], _serial_id[7]
  );

  //inicia USB i mostra id waspmote
  if(debug){
    USB.ON();
    USB.print(F("Waspmote id: "));
    USB.println(wasp_id);
  }

  //configura microcom capacitiu detector cso
  pinMode(PIN_MICROCOM,INPUT);

  //inicia pins alimentació
  PWR.setSensorPower(SENS_5V,SENS_ON);
  PWR.setSensorPower(SENS_3V3,SENS_ON);

  //configura maxbotix sensor distància ultrasons
  Utils.setMuxAux1();
  beginSerial(9600,1);

  //LoRa configuration
  sx1272.ON();
  int8_t e; //status
  e=sx1272.setChannel(CH_12_868); if(debug){USB.print("set channel: ");     USB.println(e);} //frequency channel
  e=sx1272.setHeaderON();         if(debug){USB.print("set header on: ");   USB.println(e);} //implicit or explicit header mode
  e=sx1272.setMode(1);            if(debug){USB.print("set mode 1: ");      USB.println(e);} //mode: from 1 to 10
  e=sx1272.setCRC_ON();           if(debug){USB.print("set crc on: ");      USB.println(e);} //CRC on or off
  e=sx1272.setPower(POWER);       if(debug){USB.print("set power: ");       USB.println(e);} //output power (Max, High or Low)
  e=sx1272.setNodeAddress(2);     if(debug){USB.print("set node address: ");USB.println(e);} //the node address value: from 2 to 255

  //end setup
  if(debug) USB.println(F("------------------------------"));
  delay(1000);
}

void loop(){
  //read battery level
  int   battery = PWR.getBatteryLevel(); //%
  float volts   = PWR.getBatteryVolts(); //V

  if(debug){
    //show remaining battery level
    USB.print(F("Battery Level: "));
    USB.print(battery);
    USB.print(F(" %"));

    //show battery Volts
    USB.print(F(" | Battery (Volts): "));
    USB.print(volts);
    USB.println(F(" V"));

    //show battery charging state. This is valid for both USB and Solar panel
    //if any of those ports are used the charging state will be true
    USB.print(F("Battery charging state: "));
    if(chargeState){
      USB.println(F("Battery is charging"));
    }else{
      USB.println(F("Battery is not charging"));
    }
  }

  //read DS1820 temperature (ºC)
  if(debug) USB.print(F("Reading temperature (ºC)... "));
  float temp1 = Utils.readTempDS1820(PIN_T1); if(debug){ USB.print(  temp1); USB.print(", "); }
  float temp2 = Utils.readTempDS1820(PIN_T2); if(debug){ USB.print(  temp2); USB.print(", "); }
  float temp3 = Utils.readTempDS1820(PIN_T3); if(debug){ USB.println(temp3); }
 
  //read microcom overflow detector
  if(debug) USB.print(F("Reading cso overflows (true/false)..."));
  bool cso_detected = digitalRead(PIN_MICROCOM); //true/false overflow
  its_raining = cso_detected;

  if(debug){
    USB.println(cso_detected);
    if(its_raining){
      USB.println(F("[IT IS RAINING (or microcom sensor unplugged)]"));
    }else{
      USB.println(F("[IT IS NOT RAINING]"));
    }
  }

  //read maxbotix distance sensor n times
  if(debug) USB.println(F("Reading distance (cm)..."));

  unsigned short distances[15]; //read the distance 15 times
  for(int i=0;i<15;i++){
    distances[i]=0;
    unsigned long timeout = millis();
    while(distances[i]==0){
      if(millis()-timeout > TIMEOUT) break;
      distances[i] = readSensorSerial();
    }
    if(debug){ 
      USB.print(distances[i]);
      USB.print(i<14?",":": ");
    }
  }

  //readings done: switch off power
  PWR.setSensorPower(SENS_3V3,SENS_OFF);
  PWR.setSensorPower(SENS_5V,SENS_OFF);

  //compute distances measured average
  unsigned short distance = computeAverage(distances,15);
  if(debug) USB.println(distance);

  //construct string json with all readings done so far
  char message[MSG_LENGTH];
  construct_json_message(
    message, 
    temp1, temp2, temp3, cso_detected, distance,
    battery, volts
  );

  //send string json to gateway via lora
  lora_send_message(message);

  //add 1 to current loop counter
  numero_loop_actual++;

  if(debug){
    USB.print("loop before deep sleep: ");
    USB.print(numero_loop_actual);
    USB.print("/");
    USB.println(its_raining ? NUM_LOOPS_RAIN : NUM_LOOPS_DRY);
    USB.println(F("============================="));
  }

  //check if we can start deep sleep
  if(
    numero_loop_actual >= (its_raining ? NUM_LOOPS_RAIN : NUM_LOOPS_DRY)
  ){
    //start deep sleep
    if(debug){
      USB.print(F("Entering deep sleep... "));
      USB.println(its_raining ? SLEEP_INTERVAL_RAIN : SLEEP_INTERVAL_DRY);
    }
    numero_loop_actual = 0;
    PWR.deepSleep( 
      its_raining ? SLEEP_INTERVAL_RAIN : SLEEP_INTERVAL_DRY, 
      RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF
    );
    if(debug){
      USB.println(F("wake up!"));
      USB.println();
    }
  }

  //call setup() to switch on power
  setup();
}

//read maxbotix distance sensor
unsigned short readSensorSerial() {
  char buf[5]; //reserva 5 bytes "R000\0"
  serialFlush(1);

  //wait for incoming 'R' character or timeout
  unsigned long timeout = millis();
  while(!serialAvailable(1) || serialRead(1) != 'R'){
    if(millis()-timeout > TIMEOUT) break;
  }

  //read distance
  for(int i=0; i<4; i++){
    while(!serialAvailable(1)){
      if(millis()-timeout > TIMEOUT) break;
    }
    buf[i]=serialRead(1);
  }
  buf[4]='\0'; //add string terminating character
  return atoi(buf);
}

//construct json string message
void construct_json_message( 
  char *message,
  float temp1, float temp2, float temp3, bool cso_detected, unsigned short distance,
  int battery, float volts
  ){
  //use dtostrf() to convert from float to string:
  //first '1' refers to minimum width
  //second '1' refers to number of decimals
  char t1[6]; dtostrf(temp1,1,1,t1);
  char t2[6]; dtostrf(temp2,1,1,t2);
  char t3[6]; dtostrf(temp3,1,1,t3);
  char vv[6]; dtostrf(volts,1,1,vv);

  //estructura json: {waspmote_id,temp1,temp2,temp3,cso_detected,distance}
  snprintf( message, MSG_LENGTH,
    "{w_id:%s,t1:%s,t2:%s,t3:%s,cso:%d,d:%d,batt:%d,v:%s,pckts:%d}", 
    wasp_id,
    t1, t2, t3, cso_detected, distance,
    battery, vv,
    ++paquets_enviats
  );

  //make sure message length is multiple of 16 (for AES)
  while(strlen(message)%16 !=0){
    message = strcat(message," ");
  }
}

//encrypt and send message via lora
void lora_send_message(char *message){
  //encrypt message
  if(debug){
    USB.print(F("Original:")); USB.println(message);
  }

  //calculate length in Bytes of the encrypted message 
  uint16_t encrypted_length = AES.sizeOfBlocks(message);

  //encrypted message
  uint8_t encrypted_message[MSG_LENGTH];

  //calculate encrypted message with ECB cipher mode and PKCS5 padding. 
  AES.encrypt(AES_128, PASSWORD, message, encrypted_message, ECB, PKCS5); 

  //print original message and encrypted message
  if(debug){
    //printing encrypted message    
    USB.print(F("Encrypted:")); 
    AES.printMessage(encrypted_message, encrypted_length); 
  }

  //send packet before ending a timeout and waiting for an ACK response  
  if(debug){
    USB.print(F("Sending data via LoRa... "));
    USB.print((int)encrypted_length);
    USB.println(" bytes");
  }

  //send encrypted packet via lora
  int8_t e;
  e = sx1272.sendPacketTimeoutACK(RX_ADDRESS, encrypted_message, encrypted_length);
  
  //check sending status
  if(debug){
    if(e==0){
      USB.println(F("--> Packet sent OK"));     
    }else{
      USB.println(F("--> Error sending the packet"));  
      USB.print(F("state: "));
      USB.println(e, DEC);
    } 
  }

  //retry if sending packet fails
  unsigned short retry=0;
  while(e!=0 && retry<10){
    if(debug){ USB.println(F("Retry sending...")); }
    e = sx1272.sendPacketTimeoutACK(RX_ADDRESS, encrypted_message, encrypted_length);
    if(debug){
      if(e==0){
        USB.println(F("--> Packet sent OK (during retry)"));
      }else{
        USB.print(F("state: "));
        USB.println(e, DEC);
      }
    }
    retry++;
  }
}

//compute average of distances read
unsigned short computeAverage(unsigned short *distances, int length){
  int sum=0;
  int l = length; //l is length that can decrease if readings are 0
  for(int i=0;i<length;i++){
    if(distances[i]==0) l--;
    sum += distances[i];
  }
  if(length==0) return 0;
  else          return sum/l;
}
