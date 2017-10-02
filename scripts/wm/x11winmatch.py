#!/usr/bin/env python3
from Xlib import display, X, Xatom
import time
import os

class X11WinWatch:
	def __init__(self):
		self.display = display.Display()
		self.root = self.display.screen().root
		self.root.change_attributes(event_mask=(X.PropertyChangeMask))
		self.ACTIVE = self.display.intern_atom("_NET_ACTIVE_WINDOW")
		self.display.flush()

		self.activeWindow = self.root.get_full_property(self.ACTIVE, 0).value[0]
		self.doActiveWindow()
		self.run()

	def doActiveWindow(self):
		active = self.root.get_full_property(self.ACTIVE, 0).value[0]
		if active != self.activeWindow:
			# Window changed
			self.activeWindow = active
			os.system('~/scripts/wm/on_window_change.sh ' + str(active))

	def run(self):
		while 1:
			while self.display.pending_events():
				e = self.display.next_event()
				if e.type == X.PropertyNotify:
					self.doActiveWindow()
			time.sleep(0.1)

X11WinWatch()
