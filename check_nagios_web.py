#!/usr/bin/python
#
# Check if there any unhandale critical alerts in the Nagios web interface
# Felipe Ferreira Dez/2016
# v. 1.0

import pycurl
import re
import cStringIO
from bs4 import BeautifulSoup


### VARS

buf = cStringIO.StringIO()
user="cuser"
password="CACA!"
tmpfile="/tmp/check_nagios.tmp"
url="http://server-nagios/cgi-bin/nagios3/status.cgi?host=all&servicestatustypes=16&hoststatustypes=3&serviceprops=42&sorttype=1&sortoption=2&sorttype=2&sortoption=3"
count=0
strmsg=""
regx=r'CPU|Memoria|Archive|Disk|svil'


### FUNCTIONS

def filter(filetmp):
## VARS
 matches = []
 td_body=""
 global count
 global strmsg
 count=0
 f = open(filetmp, 'r')
 html_doc = f.read()
 f.close()
 soup = BeautifulSoup(html_doc, 'html.parser')
 for td in soup.findAll('td', attrs={'class':'statusBGCRITICAL'}):
  for td_body in td.findAll('td', attrs={'align':'left'}):
   href = td_body.a['href']
   href = href.split("=", 4)
   host = href[-2]
   host = host.split("&",1)
   host = str(host[0])
   service = str(href[-1])
   hostservice = host + service

   if not any(re.findall(regx, service, re.IGNORECASE)):
    if hostservice not in matches:
     matches.append(hostservice)
     count += 1
     strmsg += host + " " + service + " "
     #print  service


### MAIN
c = pycurl.Curl()
c.setopt(pycurl.CONNECTTIMEOUT, 8)
c.setopt(pycurl.SSL_VERIFYPEER, False)
### DEBUG MODE
#c.setopt(c.VERBOSE, True)
c.setopt(pycurl.HTTPAUTH, pycurl.HTTPAUTH_BASIC)
c.setopt(c.FAILONERROR, True)
c.setopt(c.HTTPHEADER, ['Accept: text/html', 'Accept-Charset: UTF-8'])
c.setopt(pycurl.USERPWD, "%s:%s" % (user, password))
c.setopt(pycurl.WRITEFUNCTION, buf.write)
c.setopt(pycurl.URL, "%s" % (url))

#DEBUG
#print("Connection to " + url + "with user: " + user + " and password: " + password)
#print("Saved at " + tmpfile)

f = open(tmpfile, 'w')
try:
 c.perform()
 f.write(buf.getvalue())
 buf.close()
 f.close()

except pycurl.error, error:
 errno, errstr = error
 print 'An error occurred: ', errstr
 exit(2)

filter(tmpfile)

if count != 0:
 textmsg = "CRITICAL - Found " + str(count) + " errors " + strmsg + "|count=" + str(count)
 print(textmsg)
 exit(2)
else:
 textmsg = "CRITICAL - Found " + str(count) + " errors " + strmsg
 print("OK - No critical errors found on Fastweb Nagios|count=" + str(count))
 exit(0)

exit(0)
