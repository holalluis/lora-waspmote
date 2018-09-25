#-*- coding: utf-8 -*-

import time

def processa(rebut):
  '''
    handle lora message received
  '''
  now=time.strftime("%c")
  print(now,rebut)

  '''
  Comunicació serial amb Waspmote SX1272 (gateway)
  handle output of received messages by the gateway USB
  '''
  '''SPEC'''
  # pas 0: comprova length > 0
  # pas 1: comprova byte 0 == \x01
  # pas 2: comprova byte n == \x04
  # pas 3: comprova byte n-1 i n-2 == checksum
  # pas 3: comprova byte n-3 i n-4 == \r\n
  # pas 4: agafa bytes 1 a n-3 = missatge
  # pas 5: processa missatge
  # implementa una manera d'identificar cada node emissor (clau pública/clau privada compartida)
  # crea estructura de missatge
  # data, temperatura, etc: parlar amb fèlix
