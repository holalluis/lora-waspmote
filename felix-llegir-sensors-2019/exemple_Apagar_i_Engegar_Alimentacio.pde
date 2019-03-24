void setup() {
  // put your setup code here, to run once:
}

void loop() {
  // put your main code here, to run repeatedly:
  PWR.setSensorPower(SENS_3V3,SENS_ON);
  delay(1000);

  PWR.setSensorPower(SENS_3V3,SENS_OFF);
  delay(1000);
}
