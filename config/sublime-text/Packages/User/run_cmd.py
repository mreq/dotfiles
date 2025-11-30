import os
import sublime_plugin


class RunCmd(sublime_plugin.WindowCommand):
    def run(self, cmd):
        if not isinstance(cmd, list):
            cmd = [cmd]
        cmds = cmd
        pwd = self.window.folders()[0]
        os.chdir(pwd)
        for cmd in cmds:
            if "$file_name" in cmd:
                view = self.window.active_view()
                cmd = cmd.replace("$file_name", view.file_name())
            if "$file_dir" in cmd:
                view = self.window.active_view()
                cmd = cmd.replace("$file_dir", os.path.split(view.file_name())[0])
            if "$selected_text" in cmd:
                view = self.window.active_view()
                cmd = cmd.replace("$selected_text", view.substr(view.sel()[0]))
            if "$project_dir" in cmd:
                cmd = cmd.replace("$project_dir", pwd)
            print("Running custom command:", cmd)
            os.system(cmd + " &")
