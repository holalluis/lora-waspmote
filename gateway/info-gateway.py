#-*- coding: utf-8 -*-
'''
  Configuració lora gateway serial amb Waspmote SX1272 (gateway)
  http://www.libelium.com/development/waspmote/documentation/lora-gateway-tutorial/

  summary:
    READ: get current setup of the module
    SET: set new conf for the module
    DATA: send data from the module to a waspmote
'''
import config as c # (local)
import libscrc     # calculate crc16 modbus
import glob
import serial
import sys

def serial_ports():
  """ Lists serial port names
    :raises EnvironmentError:
      On unsupported or unknown platforms
    :returns:
      A list of the serial ports available on the system
  """
  if sys.platform.startswith('win'):
    ports = ['COM%s' % (i + 1) for i in range(256)]
  elif sys.platform.startswith('linux') or sys.platform.startswith('cygwin'):
    # this excludes your current terminal "/dev/tty"
    ports = glob.glob('/dev/tty[A-Za-z]*')
  elif sys.platform.startswith('darwin'):
    ports = glob.glob('/dev/tty.*')
  else:
    raise EnvironmentError('Unsupported platform')

  result = []
  for port in ports:
    try:
      s = serial.Serial(port)
      s.close()
      result.append(port)
    except (OSError, serial.SerialException):
      pass
  return result

#connexions serial per cada gateway
serial_connections = []
#for port in ['/dev/ttyUSB0','/dev/ttyUSB1']:
#for port in serial_ports():
for port in ['/dev/ttyUSB1']:
  ser          = serial.Serial()
  ser.port     = port
  ser.baudrate = c.baudrate
  ser.bytesize = c.bytesize
  ser.parity   = c.parity
  ser.stopbits = c.stopbits
  ser.timeout  = c.timeout
  ser.open()
  serial_connections.append(ser)

#envia query al gateway
def query(comanda,ser):
  '''
    estructura:
    [SOH=0x01][COMANDA][CR=0x0d][LF=0x0a][CRC16][EOT=0x04]
  '''
  #trama start
  trama = bytearray()
  trama.append(0x01) #SOH byte
  for ch in comanda: trama.append(ord(ch))
  trama.append(0x0d) #CR byte
  trama.append(0x0a) #LF byte
  crc = hex(libscrc.modbus(comanda.encode()))[2:] #remove '0x' string
  for ch in crc: trama.append(ord(ch.upper()))
  trama.append(0x04) #EOT byte
  trama.append(0x0a) #LF
  #trama end

  print('query =>',trama)
  #write
  ser.flush()
  ser.write(trama)
  print('resposta =>',ser.readlines())

#query READ: get current setup of the module
def query_read(ser): query("READ",ser)
# ('respota =>', '\x01INFO#FREC:CH_12_868;ADDR:1;BW:BW_125;CR:CR_5;SF:SF_12;SNR:0;RSSI:-109;RSSI_PACKET:119;VER:0.13\r\n250C\x04')

#query SET: set new conf for the module
def query_set(ser): query("SET#FREC:CH_10_868;ADDR:1;BW:BW_125;CR:CR_5;SF:SF_12",ser)

'''TESTS'''
#query("SET#FREC:CH_10_868;ADDR:1;BW:BW_125;CR:CR_5;SF:SF_12",ser)
#query("SET#FREC:CH_11_868;ADDR:1;BW:BW_125;CR:CR_5;SF:SF_12",ser)
for ser in serial_connections:
  print(ser.port)
  query_read(ser)
  query_read(ser)
  query_read(ser)
  query_read(ser)
  query("SET#FREC:CH_11_868;ADDR:1;BW:BW_125;CR:CR_5;SF:SF_12",ser)
