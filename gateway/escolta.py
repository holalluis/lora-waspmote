#-*- coding: utf-8 -*-
'''
  Comunicació serial Waspmote SX1272 (gateway)
  http://www.libelium.com/development/waspmote/documentation/lora-gateway-tutorial/
  TLDR: Continuously listen serial port and handle output, i.e packets sent by lora transmitter
'''
import time
import serial
import io
import config            as c # see 'config.py'
import processa_missatge as p # see 'processa_missatge.py'
import sys

print(sys.argv)
#serial port ie. /dev/ttyUSB0
port = sys.argv[1]

#nova connexió serial
ser = serial.Serial();
ser.port     = port;
ser.baudrate = c.baudrate;
ser.bytesize = c.bytesize;
ser.parity   = c.parity;
ser.stopbits = c.stopbits;
ser.timeout  = c.timeout;
ser.open();
ser.flush();
print(ser)

#print lora channel TODO

#custom readline for custom EOF
def readline(a_serial, eol=b'\r\n'):
  leneol = len(eol)
  line = bytearray()
  while True:
    c = a_serial.read(1)
    if c:
      line += c
      if line[-leneol:] == eol: break
    else:
      break
  return bytes(line)

#listen function
def listen():
  try:
    while True:
      if(ser.in_waiting):
        rebut = None;
        try:
          #read input buffer gateway
          rebut=readline(ser);
          p.processa(rebut);
        except Exception as e:
          pass
      else:
        time.sleep(5); #wait input buffer being filled
  except Exception as e:
    pass

#listen serial port forever
while True: listen()
