#-*- coding: utf-8 -*-
''' handle lora message received '''
import time
import post as p # see 'post.py'
from Crypto.Cipher import AES
import json

def processa(raw):
  '''
    "raw": bytes object (encrypted)
  '''
  print(time.strftime("%c"),"|",len(raw),"bytes received |",end=' ')

  #remove \r\n end bytes
  if raw[-1]==10 and raw[-2]==13: raw=raw[0:len(raw)-2]

  #decrypt raw message
  try:
    key="libeliumlibelium"
    decrypted=AES.new(key,AES.MODE_ECB).decrypt(raw)
  except Exception as e:
    print(e)
    return False

  #try to parse to json the decrypted message

  #remove AES padding bytes: "{json_string}u0001u0001u0005u0003"
  #find the closing '}' brace
  #remove padding bytes only if last byte is not '}' (0x7d)
  if decrypted[-1] != ord('}'):
    decrypted = decrypted[0:decrypted.find(1+ord('}'))]

  #conversion bytes object to string
  decrypted_string = decrypted.decode('utf-8')

  #intenta parsejar a json
  try:
    decrypted_string = json.dumps(decrypted_string) #string
  except Exception as e:
    print(e);
    return False

  #send decrypted message to remote server
  post_result = p.post(decrypted_string)

  return post_result
