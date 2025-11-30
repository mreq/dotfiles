import sublime
import sublime_plugin
import subprocess
from operator import itemgetter


class GitGoToFileFromStatus(sublime_plugin.WindowCommand):

    def run(self):
        cwd = self.window.folders()[0]
        output = subprocess.check_output("git status --porcelain", shell=True, cwd=cwd)

        files = []
        lines = output.decode("utf8").strip().split("\n")

        if len(lines) == 1 and lines[0] == "":
            self.window.status_message("No git changes to go to.")
            return

        for line in lines:
            if not line.startswith(" D"):
                annotation = line[:3].strip()
                file_name = line[3:].replace('"', "").strip()
                file_path = cwd + "/" + file_name

                modified_date_output = subprocess.check_output(
                    'stat -c %y $file "' + file_name + '"', shell=True, cwd=cwd
                )

                modified_date = modified_date_output.decode("utf8").strip()
                basename = file_name.split("/")[-1]
                quick_panel_item = sublime.QuickPanelItem(
                    basename, file_name, annotation
                )

                files.append(
                    {
                        "modified_date": modified_date,
                        "quick_panel_item": quick_panel_item,
                        "file_path": file_path,
                        "file_name": file_name,
                    }
                )

        sorted_files = sorted(files, key=itemgetter("modified_date"), reverse=True)

        def select_file_name_index(i):
            if i != -1:
                self.window.open_file(sorted_files[i]["file_path"])

        quick_panel_items = [item["quick_panel_item"] for item in sorted_files]

        self.window.show_quick_panel(quick_panel_items, select_file_name_index)
