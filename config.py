#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
Edita aquest arxiu per configurar la connexió serial

exemple:
  import config as c
  ser = serial.Serial()
  ser.port=c.port
'''

'''port'''
#ser.port='COM1'                   #windows
#ser.port='/dev/ttyUSB0'           #linux
port='/dev/tty.usbserial-AI03NPY0' #macosx

'''other parameters'''
baudrate=38400 #9600, 14400, 19200, 28800, 38400, 57600, or 115200
bytesize=8
parity='N' #none
stopbits=1
timeout=1
xonxoff=False
rtscts=False
dsrdtr=False

