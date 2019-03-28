#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
Configuració connexió serial del gateway a l'ordinador on estigui connectat
'''

'''serial port'''
#el port s'especifica com a paràmetre quan es crida l'script 'escolta.py'
'''
  port='/dev/ttyUSB1'                #linux
  port='COM1'                        #windows
  port='/dev/tty.usbserial-AI03NPY0' #macosx
'''

'''altres paràmetres connexió serial'''
baudrate = 38400 #9600 14400 19200 28800 38400 57600 115200
bytesize = 8     #8
parity   = 'N'   #none even
stopbits = 1     #1
timeout  = 1     #1
xonxoff  = False #False
rtscts   = False #False
dsrdtr   = False #False
