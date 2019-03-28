/*
  Waspmote llegeix:
    1. Sensors temperatura (3 DS1820)
    2. Sensor overflow (cso) capacitiu miocrocom
    3. Sensor distància ultrasons maxbotix
  Després envia les lectures via LoRa SX1272 (libelium)
  Es reben els paquets a gateway que també té un SX1272, i es llegeixen per USB
  serial (veure codi carpeta "gateway").
*/
#include<WaspSX1272.h>
#include<WaspAES.h>

/*****************/
/* CONFIGURATION */
/*****************/
#define SLEEP_INTERVAL_DRY  "00:00:01:00"      /*deep sleep interval (dry weather)*/
#define SLEEP_INTERVAL_RAIN "00:00:01:00"      /*deep sleep interval when it is raining*/
#define NUM_LOOPS_DRY       10                 /*numero lectures seguides abans de dormir SLEEP_INTERVAL_DRY*/
#define NUM_LOOPS_RAIN      3                  /*numero lectures seguides abans de dormir SLEEP_INTERVAL_RAIN*/
#define POWER               'L'                /*LoRa emission energy: Low(L) High(H) Max(M)*/
#define RX_ADDRESS          1                  /*destination address (lora gateway) to send packets*/
#define MODE                1                  /*lora setMode*/
#define MSG_LENGTH          200                /*max length missatge json in bytes*/
#define PASSWORD            "libeliumlibelium" /*private a 16-Byte key to encrypt message*/
#define PIN_MICROCOM        DIGITAL1           /*pin microcom (cso detection)*/
#define PIN_T1              DIGITAL4           /*pin sensor temperatura 1*/
#define PIN_T2              DIGITAL6           /*pin sensor temperatura 2*/
#define PIN_T3              DIGITAL8           /*pin sensor temperatura 3*/
#define MB_READINGS         10                 /*maxbotix readings each loop and averaged*/
#define TIMEOUT             1000               /*ms maxbotix serial read timeout*/
int            channel            = NULL;      /*depends on wasp_id*/
bool           debug              = 1;         /*usb debugging*/
unsigned short node_address;                   /*each node must have different address*/
char           wasp_id[5];                     /*waspmote id (4 chars)*/
bool           chargeState        = false;     /*is battery charging?*/
unsigned int   paquets_enviats    = 0;         /*number of sent packets (tx)*/
unsigned int   paquets_rebuts     = 0;         /*number of ackd packets (rx)*/
unsigned short numero_loop_actual = 0;         /*current loop number before deep sleep*/
bool           its_raining        = false;     /*it is raining?*/

void setup(){
  //get battery charging state
  chargeState = PWR.getChargingState();

  //get wasp id
  Utils.readSerialID();
  snprintf(wasp_id, 10, "%.2x%.2x", _serial_id[0], _serial_id[1]);

  //init USB and show waspmote id
  if(debug){
    USB.ON();
    USB.print(F("Waspmote id: "));
    USB.println(wasp_id);
    //reading time
    //USB.println(F("Date[dow,YY/MM/DD,hh:mm:ss]"));
    //USB.println(RTC.getTime());
  }

  //config microcom capacitiu detector cso overflows
  pinMode(PIN_MICROCOM,INPUT);

  //config maxbotix sensor ultrasons distance (nivell)
  Utils.setMuxAux1();
  beginSerial(9600,1);

  //init power pins 
  PWR.setSensorPower(SENS_5V,  SENS_ON);
  PWR.setSensorPower(SENS_3V3, SENS_ON);

  //setup lora chip sx1272
  lora_setup();

  //show sleep duration
  if(debug){
    USB.println(F("--------------------------------"));
    USB.print(F("SLEEP_INTERVAL_DRY:  "));USB.println(SLEEP_INTERVAL_DRY);
    USB.print(F("SLEEP_INTERVAL_RAIN: "));USB.println(SLEEP_INTERVAL_RAIN);
    USB.println(F("--------------------------------"));
  }
  delay(1000);
}

void lora_setup(){
  sx1272.ON();
  int8_t e=-1; //sx1272 status

  /*
    868 MHz channels (8):
      CH_10_868 CH_11_868 CH_12_868 CH_13_868 
      CH_14_868 CH_15_868 CH_16_868 CH_17_868
  */
  while(e!=0){
    /*
      wasp_id | channel
      --------+----------
    */
    if     (strcmp(wasp_id,"2f76")==0) e=sx1272.setChannel(CH_10_868);
    else if(strcmp(wasp_id,"6d31")==0) e=sx1272.setChannel(CH_11_868);
    else if(strcmp(wasp_id,"272b")==0) e=sx1272.setChannel(CH_12_868);
    else if(strcmp(wasp_id,"5e0a")==0) e=sx1272.setChannel(CH_13_868);
    else if(strcmp(wasp_id,"5f83")==0) e=sx1272.setChannel(CH_14_868);

    if(debug){
      switch(sx1272._channel){
        case CH_10_868: USB.print(F("set channel CH_10_868: ")); break;
        case CH_11_868: USB.print(F("set channel CH_11_868: ")); break;
        case CH_12_868: USB.print(F("set channel CH_12_868: ")); break;
        case CH_13_868: USB.print(F("set channel CH_13_868: ")); break;
        case CH_14_868: USB.print(F("set channel CH_14_868: ")); break;
        case CH_15_868: USB.print(F("set channel CH_15_868: ")); break;
        case CH_16_868: USB.print(F("set channel CH_16_868: ")); break;
        case CH_17_868: USB.print(F("set channel CH_17_868: ")); break;
        default: 
          USB.print(F("channel error"));
          break;
      }
      USB.println(e);
    }
    if(e) delay(1000);
  }
  e=-1;

  /*set implicit or explicit header*/
  while(e!=0){
    e=sx1272.setHeaderON();
    if(debug){
      USB.print("set header on: ");
      USB.println(e);
    }
    if(e) delay(1000);
  }
  e=-1;

  /*mode: 1 to 10*/
  /*
    Mode BW CR SF Sensitivity (dB) 
      Transmission time (ms) for a 100-byte packet sent
        Transmission time (ms) for a 100-byte packet sent and ACK received
          Comments
    //--
    1  125 4/5 12 -134 4245 5781 max range, slow data rate
    2  250 4/5 12 -131 2193 3287 -
    3  125 4/5 10 -129 1208 2120 -
    4  500 4/5 12 -128 1167 2040 -
    5  250 4/5 10 -126  674 1457 -
    6  500 4/5 11 -125  715 1499 -
    7  250 4/5  9 -123  428 1145 -
    8  500 4/5  9 -120  284  970 -
    9  500 4/5  8 -117  220  890 -
    10 500 4/5  7 -114  186  848 min range, fast data rate, minimum battery impact
  */
  /**/
  while(e!=0){
    e=sx1272.setMode(MODE); //if mode is not 1, not working (?)
    if(debug){
      USB.print(F("set mode "));
      USB.print(MODE);
      USB.print(": ");
      USB.println(e);
    }
    if(e) delay(1000);
  }
  e=-1;

  /*set CRC on or off*/
  while(e!=0){
    e=sx1272.setCRC_ON();
    if(debug){
      USB.print("set crc on: ");
      USB.println(e);
    }
    if(e) delay(1000);
  }
  e=-1;

  /*set output power (Max, High or Low)*/
  while(e!=0){
    e=sx1272.setPower(POWER);
    if(debug){
      USB.print(F("set power "));
      USB.print(POWER);
      USB.print(F(":"));
      USB.println(e);
    }
    if(e) delay(1000);
  }
  e=-1;

  /*set node (sender) address value: from 2 to 255*/
  while(e!=0){
    /*
      the addresses of the devices are:
        >>> 0x27 (39)
        >>> 0x2f (47)
        >>> 0x5e (94)
        >>> 0x5f (95)
        >>> 0x6d (109)
    */
    node_address = _serial_id[0];
    e=sx1272.setNodeAddress(node_address);
    if(debug){
      USB.print(F("set node address "));
      USB.print(node_address);
      USB.print(F(" (0x"));
      USB.print(node_address,HEX);
      USB.print(F(")"));
      USB.print(F(": "));
      USB.println(e);
    }
    if(e) delay(1000);
  }
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
    USB.println(F("--------------------------------"));
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
    USB.print(cso_detected);
    if(its_raining){
      USB.println(F(" [RAINING (or microcom sensor unplugged)]"));
    }else{
      USB.println(F(" [NOT RAINING]"));
    }
  }

  //read maxbotix distance sensor n times
  if(debug) USB.println(F("Reading distance (cm)..."));

  unsigned short distances[MB_READINGS];
  for(int i=0;i<MB_READINGS;i++){
    distances[i]=0;
    unsigned long timeout = millis();
    while(distances[i]==0){
      if(millis()-timeout > TIMEOUT) break;
      distances[i] = readSensorSerial();
    }
    if(debug){ 
      USB.print(distances[i]);
      USB.print(i<MB_READINGS-1 ? ",":": ");
    }
  }

  //readings done: switch off power
  PWR.setSensorPower(SENS_3V3,SENS_OFF);
  PWR.setSensorPower(SENS_5V,SENS_OFF);

  //compute distances measured average
  unsigned short distance = computeAverage(distances,10);
  if(debug) USB.println(distance);

  //construct string json with all readings done so far
  char message[MSG_LENGTH];
  construct_json_message(
    message, 
    temp1, temp2, temp3, cso_detected, distance,
    battery, volts
  );

  //send string json to gateway via lora
  if(debug) lora_send_message(message);

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

//compute average of distances read from maxbotix sensor
unsigned short computeAverage(unsigned short *distances, int length){
  int sum=0;
  int l = length; //l is length that can decrease if readings are 0
  for(int i=0;i<length;i++){
    if(distances[i]==0) l--;
    sum += distances[i];
  }
  return (l==0? 0 : sum/l);
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
  //char vv[6]; dtostrf(volts,1,1,vv);

  //estructura json: {wasp_id,temp1,temp2,temp3,cso_detected,distance}
  snprintf(message, MSG_LENGTH,
    "{wid:\"%s\",T:[%s,%s,%s],cso:%d,d:%d,bat:%d,pwr:\"%c\",tx:%d}", 
    wasp_id,
    t1, t2, t3, cso_detected, distance,
    battery, POWER,
    paquets_enviats++
  );

  //make sure message length is multiple of 16 (for AES)
  while(strlen(message)%16 !=0){
    message = strcat(message," ");
  }
}

//encrypt and send message via lora
void lora_send_message(char *message){
  //encrypt message
  if(debug){ USB.print(F("Paquet:")); USB.println(message); }

  //calculate length in Bytes of the encrypted message 
  uint16_t encrypted_length = AES.sizeOfBlocks(message);

  //new buffer for encrypted message
  uint8_t encrypted_message[MSG_LENGTH];

  //calculate encrypted message with ECB cipher mode and PKCS5 padding. 
  AES.encrypt(AES_128, PASSWORD, message, encrypted_message, ECB, PKCS5); 

  //print encrypted message
  /*
  if(debug){
    printing encrypted message    
    USB.print(F("Encrypted:")); 
    AES.printMessage(encrypted_message, encrypted_length); 
  }
  */

  //send packet before ending a timeout and waiting for an ACK response  
  if(debug){
    USB.print(F("Sending data (LoRa "));
    USB.print(F("RX "));
    USB.print(RX_ADDRESS);
    USB.print(F(", "));
    USB.print(encrypted_length);
    USB.println(F(" bytes)"));
  }

  //send encrypted packet via lora
  //state = 9 --> The ACK lost (no data available)
  //state = 8 --> The ACK lost
  //state = 7 --> The ACK destination incorrectly received
  //state = 6 --> The ACK source incorrectly received
  //state = 5 --> The ACK number incorrectly received
  //state = 4 --> The ACK length incorrectly received
  //state = 3 --> N-ACK received
  //state = 2 --> The command has not been executed
  //state = 1 --> There has been an error while executing the command
  //state = 0 --> The command has been executed with no errors
  int8_t e;
  e = sx1272.sendPacketTimeoutACKRetries(RX_ADDRESS, encrypted_message, encrypted_length);

  //if ACK is received
  if(e==0) paquets_rebuts++;

  //check sending status
  if(debug){
    if(e==0){ USB.println(F("--> Packet sent OK")); }
    else{
      USB.println(F("--> Error sending the packet"));  
      USB.print(F("state: "));
      USB.println(e, DEC);
    } 
  }
}
