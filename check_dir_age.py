#!/bin/python
# check directory modified date if not from today or yesterday throw CRITICAL

import os
import time
from datetime import datetime
import sys

### VARS
today = datetime.today()
err = 0
msg = ""
tday = 1

if len(sys.argv) < 2:
 print "UNKOWN - Missing argument for  directory to check, and days threashold"
 exit(3)


### MAIN
for dir in sys.argv[1:]:

 if os.path.exists(dir):
  date_last_backup = time.ctime(max(os.stat(root).st_mtime for root,_,_ in os.walk(dir)))
  date_last_backup = datetime.strptime(date_last_backup, "%a %b %d %H:%M:%S %Y")
 #print("TODAY:  " + str(today))
 #print("BACKUP: " + str(date_last_backup))
  diff = today - date_last_backup
  msg += dir + " " + str(diff.days)
  if diff.days > tday:
   err += err

 else:
  print "UNKNOWN - Directory " + dir + " not found"
  exit(3)

if err == 0:
 print "OK - Directorys are updated, " + msg
 exit(0)

else:
 print "CRITICAL - " + msg
 exit(2)
