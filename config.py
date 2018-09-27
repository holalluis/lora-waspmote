#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
Configuració connexió serial del gateway a l'ordinador on estigui connectat

exemple:
  import config as c
  ser=serial.Serial()
  ser.port=c.port
'''

'''serial port'''
#ser.port='COM1'                   #windows
#ser.port='/dev/ttyUSB0'           #linux
port='/dev/tty.usbserial-AI03NPY0' #macosx

'''other parameters'''
baudrate = 38400 #9600 14400 19200 28800 38400 57600 115200
bytesize = 8     #8
parity   = 'N'   #none even
stopbits = 1     #1
timeout  = 1     #1
xonxoff  = False
rtscts   = False
dsrdtr   = False

