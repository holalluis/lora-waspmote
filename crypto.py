import base64

def encode(key, string):
  enc = []
  for i in range(len(string)):
    key_c = key[i % len(key)]
    enc_c = chr((ord(string[i]) + ord(key_c)) % 256)
    enc.append(enc_c)
  return base64.urlsafe_b64encode("".join(enc).encode()).decode()

def decode(key, enc):
  dec = []
  enc = base64.urlsafe_b64decode(enc).decode()
  for i in range(len(enc)):
    key_c = key[i % len(key)]
    dec_c = chr((256 + ord(enc[i]) - ord(key_c)) % 256)
    dec.append(dec_c)
  return "".join(dec)

'''tests'''
key="lamevacntrasenya" #ha de ser 16 chars/bytes (128 bits)
missatge_original="hola em dic lluis"
missatge_encriptat=encode(key, missatge_original)
missatge_desencriptat=decode(key, missatge_encriptat)
print(key)
print(missatge_original)
print(missatge_encriptat)
print(missatge_desencriptat)
