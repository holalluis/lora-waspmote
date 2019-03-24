//maxbotix: sensor nivell. Envia caràcters ascii per exemple "12 " en cm Serial.read()
WaspUART UART;

void setup() {
  USB.ON();
  USB.println(F("Lectura Sensor GS3"));
  PWR.setSensorPower(SENS_5V,SENS_ON); //my sensor need this voltatge
  UART.setBaudrate(9600);
  UART.setUART(1);
  UART.beginUART();
  Utils.setMuxAux1();                                                                                   
  delay(2000);
}

void loop() {
  USB.println("Conecte Sensor");
  delay(500);
  if(serialAvailable(1)){
    UART.readBuffer(28);
    USB.println(UART._buffer,UART._length);
  }
 delay(5000);
}
