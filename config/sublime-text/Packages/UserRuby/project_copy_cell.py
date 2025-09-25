import sublime
import sublime_plugin
import subprocess
import os

from . import ruby_cell_utils

class ProjectCopyCell(sublime_plugin.WindowCommand):
	def run(self):
		a = subprocess.check_output('ls -t ~/work', shell=True)
		projects = bytes.decode(a).splitlines()

		file_name = self.window.active_view().file_name()
		if not file_name:
			return self.window.status_message('No active project view.')

		cell_name = ruby_cell_utils.get_cell_name(self.window)

		def copy(i):
			if i != -1:
				target = projects[i]

				for folder_name in self.window.folders():
					if folder_name in file_name:
						source_name = folder_name.split('/').pop()
						b = subprocess.check_output("rg --files -g '**/" + cell_name + "*'", cwd=folder_name, shell=True)
						c = subprocess.check_output("rg --files -g '**/" + cell_name + "/**'", cwd=folder_name, shell=True)
						names = bytes.decode(b).splitlines() + bytes.decode(c).splitlines()

						for name in names:
							if 'cell' in name:
								target_dir = os.path.expanduser('~/work/') + target
								target_path = target_dir + '/' + name.replace(source_name, target)
								target_dirpath = os.path.dirname(target_path)
								subprocess.call(['mkdir', '-p', target_dirpath], cwd=folder_name)
								subprocess.call(['cp', name, target_path], cwd=folder_name)
								subprocess.call(['touch', target_dir], cwd=folder_name)

						self.window.status_message('Copied to: ' + target)
						return
					else:
						pass

		self.window.show_quick_panel(projects, copy)
