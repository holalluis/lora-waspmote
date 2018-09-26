'''
post a json string to a server
'''
import requests
import json

#json string to sent
data={"example key":"example value"};

#convert json object to string
data=json.dumps(data);

#do the request
print("Posting data...");
r=requests.post('http://lora.h2793818.stratoserver.net/post.php',{'data':data});

#print result
print(r.status_code);
print(r.text);
