#-*- coding: utf-8 -*-
'''
Comunicació serial amb Waspmote SX1272 (gateway)
Continuously listen serial port and handle output

http://www.libelium.com/development/waspmote/documentation/lora-gateway-tutorial/
'''
import serial
import time

#nova connexió serial
ser=serial.Serial()
#ser.port='COM1'                       #windows
#ser.port='/dev/ttyUSB0'               #linux
ser.port='/dev/tty.usbserial-AI03NPY0' #macosx
ser.baudrate=38400
ser.bytesize=8
ser.parity='N'
ser.stopbits=1
ser.timeout=1
ser.open()

#funció listen
def listen():
  print('Escoltant a',ser.port)
  try:
    while True:
      lines=ser.readlines()
      if len(lines):
        rebut=''.join(str(line) for line in lines)
        now=time.strftime("%c")
        print(now,rebut)
  except KeyboardInterrupt: pass # do cleanup here
  
#listen serial port
listen()
