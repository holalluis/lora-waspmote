#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
Configuració connexió serial del gateway a l'ordinador on estigui connectat
'''

'''serial port depending on OS'''
#port='COM1'                         #windows
#port='/dev/tty.usbserial-AI03NPY0'  #macosx
port='/dev/ttyUSB0'                 #linux

'''other parameters'''
baudrate = 38400 #9600 14400 19200 28800 38400 57600 115200
bytesize = 8     #8
parity   = 'N'   #none even
stopbits = 1     #1
timeout  = 1     #1
xonxoff  = False #False
rtscts   = False #False
dsrdtr   = False #False
