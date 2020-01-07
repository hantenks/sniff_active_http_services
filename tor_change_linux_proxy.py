import time
import socks
import socket
import urllib2
from stem import Signal
from stem.control import Controller
controller = Controller.from_port(port = 9151)
#print(urllib2.urlopen("http://myexternalip.com/").read())
def getaddrinfo(*args):
  return [(socket.AF_INET, socket.SOCK_STREAM, 6, '', (args[0], args[1]))]

socks.setdefaultproxy(socks.PROXY_TYPE_SOCKS5, "127.0.0.1", 9150)
socket.socket = socks.socksocket
socket.getaddrinfo = getaddrinfo

def newId():
  socks.setdefaultproxy(socks.PROXY_TYPE_SOCKS5, "127.0.0.1", 9150)
  socket.socket = socks.socksocket
  socket.getaddrinfo = getaddrinfo
  print("before :: ", urllib2.urlopen("http://myip.dnsomatic.com/").read())
  controller.authenticate()
  controller.signal(Signal.NEWNYM)
  controller.signal(Signal.HUP)
  print("after :: ", urllib2.urlopen("http://myip.dnsomatic.com/").read())
    

for i in range(0, 5):
  print "case "+str(i+1)
  newId()     #changes are reflected with any browser that uses the 9150 socks port
  #time.sleep(10)    #insert time to sleep
controller.close()