#-*- coding: utf-8 -*-
''' handle lora message received '''
import time
import post as p # see 'post.py'
from Crypto.Cipher import AES

def processa(raw):
  '''
    "raw": bytes object (encrypted)
  '''
  print(time.strftime("%c"),"|",len(raw),"bytes received |",end=' ');

  #remove \r\n bytes at the end
  if raw[-1]==10 and raw[-2]==13: raw=raw[0:len(raw)-2];

  '''decrypt raw message'''
  try:
    key="libeliumlibelium";
    decrypted=AES.new(key,AES.MODE_ECB).decrypt(raw);
  except Exception as e:
    print(e);
    decrypted="{error:true}";

  #remove AES padding bytes: "{json_string}u0001u0001u0005u0003"
  #find the closing '}' brace
  #remove padding bytes only if last byte is not '}' (0x7d)
  if decrypted[-1] != ord('}'):
    decrypted = decrypted[0:decrypted.find(1+ord('}'))];

  #send decrypted message to remote server
  p.post(decrypted.decode('utf-8'))

def test():
  #hello this is a test
  raw = b"\xa6\x0fM1\xaf'h\x01+\x86\xdd\xd5U\xb5\x1e%\x1a\xefj\xe8\x86\x03\t\x11\x01\xf7\x1cq\xa8\xc0\x18\x84\r\n"
  processa(raw)
#test()
