import sublime
import sublime_plugin
import re
import subprocess

class AddSlimBemPrefix(sublime_plugin.TextCommand):
    def run(self, edit):
        line = self.view.substr(self.view.line(0))
        class_name = "." + line.split('.').pop()
        self.view.run_command("insert", { "characters": class_name + "__" })
