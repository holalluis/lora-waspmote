'''
  post a json string to remote server
'''
import requests
import json

def post(rebut):
  #convert input to string
  try:
    rebut=json.dumps(rebut); #string
  except Exception as e:
    print(e);

  #post string to server "data" field
  print("Posting data... ",end='');
  r=requests.post('http://lora.h2793818.stratoserver.net/post.php',{'data':rebut});

  #log info 
  #print(rebut);
  print(r.status_code);
  #print(r.text); #resultat html
  return;
  
def test():
  #json string rebut del gateway
  rebut={
    "test":True,
    "id_sensor":1,
    "datetime":"2018-09-01 00:00",
    "temperatura1":15,
    "temperatura2":20,
    "temperatura3":25,
    "nivell":10,
    "overflow":0,
  };
  post(rebut)
#test()
