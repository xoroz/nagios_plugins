#!/bin/python3.6
#
# by Felipe Ferreira  (03/2019)
# remove ack from stale critical alerts, causing it to send again alerts and open tkt

import requests
import json
import time
import subprocess
import email.message
import smtplib
import datetime
from json2html import *

from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

now = datetime.datetime.now()

D="https://centreon.domain.local/centreon/api/"
URL=str(D) +"/index.php?action=authenticate"

params = (
    ('action', 'authenticate'),
)

files = {
    'username': (None, 'admin'),
    'password': (None, 'sQbwssdf8YpQVkxCgUy312321312dasd9rj'),
}

def sendme(payload):
 msg = email.message.Message()
 msg['Subject'] = 'PRINTER PROBLEMS'
 msg['From'] = 'report_centreon@domain.local'
 msg['To'] = 'felipe.ferreira@domain.local'

 msg.add_header('Content-Type','text/html')
 msg.set_payload(payload)

 # Send the message via local SMTP server.
 s = smtplib.SMTP('localhost')
 s.sendmail(msg['From'], [msg['To']], msg.as_string())
 s.quit()
 print("Current date and time:")
 print( now.strftime("%Y-%m-%d %H:%M"))
 print("E-mail sent")



response = requests.post(str(URL), params=params, files=files, verify=False)
if "authToken" in response.text:
  data = json.loads(response.text)
  TOKEN=data["authToken"]
# print("OK - got authtoken")
else:
  print("ERROR - could not authenticate!")
  quit()

URL=str(D) + "index.php?action=list&object=centreon_realtime_services&viewType=problems&fields=host_name,display_name,state,output,acknowledged,last_hard_state_change"

#TKT_Printers only
#URL=str(D) + "index.php?action=list&object=centreon_realtime_services&viewType=problems,servicegroup=5&fields=host_name,output"
URL=str(D) + "index.php?action=list&object=centreon_realtime_services&viewType=problems&servicegroup=5&sortType=name&order=desc&fields=host_name,output"

URLDOWN=str(D) + "index.php?object=centreon_realtime_hosts&action=list&viewType=unhandled&status=down"
URLCRITICAL=str(D) + "index.php?object=centreon_realtime_services&action=list&viewType=unhandled&status=critical"
#stauts CRITICAL does not work!



headers = {
    'Content-Type': 'application/json',
    'centreon-auth-token': TOKEN,
}

response = requests.get(str(URL), headers=headers, allow_redirects=True, verify=False)

if 200 != response.status_code: 
 print("ERROR - could not get information from " + URL)
 quit()

my_dict = json.loads(response.text)
Out=json2html.convert(json = my_dict)
sendme(Out)
quit(0)
