/*
 * llegir temperatura pins 4 6 8
 */

float t = 0; //temperatura

void llegeix(int pin,int num){
 t=Utils.readTempDS1820(pin);
 USB.print(F("Pin "));
 USB.print(num);
 USB.print(F(": DS1820 temperatura: "));
 USB.print(temp);
 USB.println(F(" degrees"));
 delay(1000);
}

void setup(){USB.ON();}

void loop(){
 //reading the DS1820 temperature sensor
 llegeix(DIGITAL4, 4); //twmp3
 llegeix(DIGITAL6, 6); //temp2
 llegeix(DIGITAL8, 8); //temp1
}
