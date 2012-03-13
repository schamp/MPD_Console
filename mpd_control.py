#!/usr/bin/env python

import re
import serial
import threading
import time

import SocketServer

from subprocess import Popen, PIPE

class ThreadedUDPRequestHandler(SocketServer.BaseRequestHandler):
   def handle(self):
       self.server.commander.ack_command("0000FF")

class ThreadedUDPServer(SocketServer.ThreadingMixIn, SocketServer.UDPServer):
   def setCommander(self, commander):
       self.commander = commander

class Commander():
   def __init__(self, port, rate, debug = False):
       self.port = port
       self.rate = rate
       self.debug = debug
       self.reconnect()
       self.ack_command()
       self.clear_color()

   def reconnect(self):
       keep_trying = True
       while keep_trying:
           try:
               keep_trying = False
               self.s = serial.Serial(self.port, self.rate)
               print "Successfully connected!"
           except serial.SerialException as e:
               print "Exception: %s" % e
               print "Trying again..."
               keep_trying = True
               time.sleep(1)

   def run(self):
       while 1:
           input = self.s.readline().strip()
#            print "got command: ", input
           cmd, arg = input[0], input[1:]
#            print "cmd, arg: ", cmd, arg
           if cmd == 'T':
               self.handle_button(arg)
               self.ack_command()
           elif cmd == 'A':
               self.set_volume(arg)
               self.ack_command()
#            else:
#                self.nack_command()

   def run_command(self, cmd):
       if self.debug:
           print cmd
       output = Popen(cmd, shell=True, stdout=PIPE).communicate()[0].rstrip()
       if self.debug:
           print output
       return output

   def prev(self):
       self.run_command('mpc prev')

   def toggle(self):
       status = self.run_command('mpc status')
       if re.search('\[playing\]', status):
           self.run_command('mpc pause')
       else:
           self.run_command('mpc play')

   def next(self):
       self.run_command('mpc next')

   def lock(self):
       self.run_command('mpc pause')
       self.run_command('gnome-screensaver-command --lock')

   def handle_button(self, arg):
       arg = int(arg)
       if arg == 0:
           pass
       elif arg == 1:
           self.prev()
       elif arg == 2:
           self.toggle()
       elif arg == 4:
           self.next()
       elif arg == 8:
           self.lock()

   def ack_command(self, color = '00FF00'):
       self.s.write('L%s\n' % color)
       threading.Timer(0.5, Commander.clear_color, [self]).start()

   def nack_command(self, color = 'FF0000'):
       self.s.write('L%s\n' % color)
       threading.Timer(0.5, Commander.clear_color, [self]).start()

   def clear_color(self):
       self.s.write('L000000\n')

   def set_volume(self, vol):
       self.run_command('mpc volume %s' % vol)


if __name__ == "__main__":

   c = Commander('/dev/ttyUSB0', 9600)

   server = ThreadedUDPServer(('localhost', 12345), ThreadedUDPRequestHandler)
   server.setCommander(c)
   server_thread = threading.Thread(target=server.serve_forever)
   server_thread.setDaemon(True)
   server_thread.start()

   while 1:
       try:
           c.run()
       except serial.SerialException as e:
           print "serial handler aborted: %s" % e
           print "restarting..."
           c.reconnect()

   server_thread.shutdown()

