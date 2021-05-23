import sublime_plugin
import os, json

class GenerateProjectCommand(sublime_plugin.WindowCommand):
    def run(self):
        pwd = self.window.folders()[0]
        os.chdir(pwd)

        project_name = os.path.basename(pwd)

        if project_name[0] is '.':
            project_name = project_name[1:]

        project = {
            'name': project_name,
            'folders': [{ 'path': pwd }],
        }

        project_file = pwd + '/' + project_name + '.sublime-project'

        if not os.path.isfile(project_file):
            with open(project_file, 'w') as f:
                f.write(json.dumps(project, indent = 2))
                f.close()
