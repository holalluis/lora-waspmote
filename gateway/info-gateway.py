#-*- coding: utf-8 -*-
'''
  Comunicació serial amb Waspmote SX1272 (gateway)
  http://www.libelium.com/development/waspmote/documentation/lora-gateway-tutorial/
'''
import serial
import config as c # see "config.py" (local)

#nova connexió serial
ser          = serial.Serial()
ser.port     = c.port
ser.baudrate = c.baudrate
ser.bytesize = c.bytesize
ser.parity   = c.parity
ser.stopbits = c.stopbits
ser.timeout  = c.timeout
ser.open()

#envia query al gateway
def query(trama):
  print('query =>',trama)
  #write
  ser.write(bytearray(trama)+'\n')
  '''
    tests
    query('\x01\x52\x45\x41\x44\x0D\x0A\x32\x41\x33\x31\x04')
    ('respota =>', '\x01INFO#FREC:CH_12_868;ADDR:1;BW:BW_125;CR:CR_5;SF:SF_12;SNR:0;RSSI:-109;RSSI_PACKET:119;VER:0.13\r\n250C\x04')
  '''

#envia query al gateway
query('\x01READ\x0D\x0A\x32\x41\x33\x31\x04')
