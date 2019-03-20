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

#nova connexió serial
ser = serial.Serial();
ser.port     = c.port;
ser.baudrate = c.baudrate;
ser.bytesize = c.bytesize;
ser.parity   = c.parity;
ser.stopbits = c.stopbits;
ser.timeout  = c.timeout;
ser.open();
ser.flush();

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
  print('Escoltant',ser.port);
  try:
    while True:
      if(ser.in_waiting):
        rebut = None;
        try:
          #read gateway input buffer
          rebut = readline(ser);
          p.processa(rebut);
        except Exception as e:
          print(rebut)
          print(e);
      else:
        time.sleep(5); #wait input buffer being filled
  except Exception as ee:
    print("ee");
    print(ee);

#listen serial port
listen()
