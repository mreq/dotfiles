import sublime
import sublime_plugin
import shutil
import re
import os

class MoveOpenFiles(sublime_plugin.WindowCommand):
    def run(self):
        view = self.window.active_view()

        default = re.sub(r'.*/(?:app|test)/cells/(.*)(?:_cell)(?:_test)\.rb', r'\1', view.file_name())

        self.window.show_input_panel("From:", default, lambda user_input_from: self.select_to(user_input_from), None, None)

    def select_to(self, user_input_from):
        self.window.show_input_panel('Change "' + user_input_from + '" to:', user_input_from, lambda user_input_to: self.perform(user_input_from, user_input_to), None, None)

    def perform(self, user_input_from, user_input_to):
        for view in self.window.views():
            old_filename = view.file_name()
            new_filename = old_filename.replace(user_input_from, user_input_to)
            self.fileMove(view, old_filename, new_filename)

    # adopted and modified from
    # https://github.com/wulftone/sublime-text-quick-file-move/blob/master/QuickFileMove.py
    def fileMove(self, view, old_file, new_file):
        try:
            shutil.move(old_file, new_file)
        except IOError as e:
            if e.errno == 2:  # No such file or directory (on new_file)
                new_dir = os.path.dirname(new_file)
                os.makedirs(new_dir)
                shutil.move(old_file, new_file)
            else:
                raise e
        except Exception as e:
            raise e

        if old_file.endswith(".py"):
            try:
                os.remove(old_file + "c")
            except:
                pass

        if os.access(new_file, os.R_OK):  # Can read new file
            view.set_scratch(True)
            view.close()
        else:
            sublime.error_message("Error: Can not read new file: " + new_file)
