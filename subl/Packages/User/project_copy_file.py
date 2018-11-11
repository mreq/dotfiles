import sublime
import sublime_plugin
import subprocess
import os

class ProjectCopyFile(sublime_plugin.WindowCommand):
	def run(self):
		a = subprocess.check_output('ls -t ~/work', shell=True)
		projects = bytes.decode(a).splitlines()

		file_name = self.window.active_view().file_name()
		if not file_name:
			return self.window.status_message('No active project view.')

		def copy(i):
			if i != -1:
				target = projects[i]

				for folder_name in self.window.folders():
					if folder_name in file_name:
						target_path = os.path.expanduser('~/work/') + target + file_name.replace(folder_name, '')
						target_dirpath = os.path.dirname(target_path)
						subprocess.call(['mkdir', '-p', target_dirpath])
						subprocess.call(['cp', file_name, target_path])
						self.window.status_message('Copied to: ' + target)
						return
					else:
						pass

		self.window.show_quick_panel(projects, copy)
