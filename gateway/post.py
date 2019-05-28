''' post a json string to remote server '''
import requests

def post(rebut):
  print("Post data: ",end='')
  r = requests.post(
    'http://lora.h2793818.stratoserver.net/post.php',
    {'data':rebut});
  print(r.status_code,end="")
  print(" |",rebut);
  return r.status_code
