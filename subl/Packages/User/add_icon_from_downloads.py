import sublime
import sublime_plugin
import subprocess
import os
import fileinput
import shutil
import re

class AddIconFromDownloads(sublime_plugin.WindowCommand):
	def run(self):
		a = subprocess.check_output('ls -t *.svg', shell=True, cwd=os.path.expanduser("~/Downloads"))
		icon_names = bytes.decode(a).splitlines()

		def select_icon(i):
			if i != -1:
				icon_name = icon_names[i]

				for folder_name in self.window.folders():
					icons_folder = folder_name + "/data/icons/regular"

					if not os.path.isdir(icons_folder):
						icons_folder = folder_name + "/data/icons"

					if not os.path.isdir(icons_folder):
						self.window.status_message("AddIconFromDownloads: Not a folder! " + icons_folder)
						return

					icon_path = os.path.expanduser("~/Downloads/" + icon_name)

					with fileinput.FileInput(icon_path, inplace=True, backup='.bak') as file:
						for line in file:
							print(re.sub("(fill|stroke)=[\"'](?!none)[^\"']+[\"']", "\\1=\"currentColor\"", line), end='')

					target_path = icons_folder + "/" + icon_name
					shutil.move(icon_path, target_path)

					self.window.status_message('Added icon to: ' + target_path)
					self.window.open_file(target_path)

					# 	target_dir = os.path.expanduser('~/work/') + target
					# 	target_path = target_dir + file_name.replace(folder_name, '')
					# 	target_dirpath = os.path.dirname(target_path)
					# 	subprocess.call(['mkdir', '-p', target_dirpath])
					# 	subprocess.call(['cp', file_name, target_path])
					# 	subprocess.call(['touch', target_dir])
					# 	self.window.status_message('Copied to: ' + target)
					# 	return
					# else:
					# 	pass

		self.window.show_quick_panel(icon_names, select_icon)
