#-*- coding: utf-8 -*-
import time
import post as p # see 'post.py'

def processa(rebut):
  '''
    handle lora message received
    rebut is a string in json format e.g. "{'message':'this is a new message'}\r\n"
  '''
  print(time.strftime("%c"), rebut)

  # comprova estructura del missatge 
  # TBD

  # envia el missatge rebut a la base de dades
  p.post(rebut)
