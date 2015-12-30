import sublime
import sublime_plugin
import re

class MoveByComments(sublime_plugin.TextCommand):
	def run(self, edit, forward = True):
		(row,col) = self.view.rowcol(self.view.sel()[0].begin())

		scope_name = self.view.scope_name(self.view.sel()[0].begin())
		if 'source.css.less' in scope_name or 'source.scss' in scope_name or 'source.sass' in scope_name:
			pattern = '///////////'
		else:
			pattern = '###########'

		region = sublime.Region(0, self.view.size())
		lines = [self.view.rowcol(line.begin())[0] for line in self.view.split_by_newlines(region) if pattern in self.view.substr(line)]

		if forward:
			line = [line for line in lines if line > row]
			if len(line):
				line = line[0]
			else:
				line = len(self.view.split_by_newlines(region))
		else:
			line = [line for line in lines if line < row]
			if len(line):
				line = line[len(line)-1]
			else:
				line = 0

		pt = self.view.text_point(line, 0)

		self.view.sel().clear()
		self.view.sel().add(sublime.Region(pt))

		self.view.show(pt)
