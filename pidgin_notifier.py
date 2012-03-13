#!/usr/bin/env python

import dbus, gobject
from dbus.mainloop.glib import DBusGMainLoop

def my_func(account, sender, message, conversation, flags):
    if bus.pidginbus.PurpleConversationHasFocus(conversation) == 0:
        # send a message to the mpd_console
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.connect(('localhost', 12345))
        sock.send("foo")

dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus()
obj = bus.get_object("im.pidgin.purple.PurpleService", "/im/pidgin/purple/PurpleObject")
bus.pidginbus = dbus.Interface(obj, "im.pidgin.purple.PurpleInterface")
bus.add_signal_receiver(my_func,
                        dbus_interface="im.pidgin.purple.PurpleInterface",
                        signal_name="ReceivedImMsg")

loop = gobject.MainLoop()
loop.run()

