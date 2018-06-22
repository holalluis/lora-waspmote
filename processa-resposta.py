#-*- coding: utf-8 -*-
'''
  Comunicació serial amb Waspmote SX1272 (gateway)
  handle output of received messages by the gateway USB
'''

#exemple de resposta
resposta=bytearray('\x01INFO#FREC:CH_12_868;ADDR:1;BW:BW_125;CR:CR_5;SF:SF_12;SNR:0;RSSI:-109;RSSI_PACKET:119;VER:0.13\r\n250C\x04')

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
