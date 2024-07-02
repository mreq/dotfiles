import sublime
import sublime_plugin
import re

class InsertComponentBemClassName(sublime_plugin.WindowCommand):
	def run(self):
		file_name = self.window.active_view().file_name()
		if not file_name:
			return self.window.status_message('No active project view.')

		if not "app/components" in file_name:
			return self.window.status_message('Not in app/components.')

		component_path = re.sub(r'^(.*app/components/)(.*)(_component\.\w+)$', r'\2', file_name)
		component_path = re.sub(r'^(\w)\w*/(.*)', r'\1/\2', component_path)
		component_path = re.sub(r'[_/]', r'-', component_path)

		print(component_path)
