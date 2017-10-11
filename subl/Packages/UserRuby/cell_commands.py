import sublime
import sublime_plugin
import re
import subprocess

namespaces = '(?:\w+/)*'

def get_cell_name(window):
    view = window.active_view()
    path = view.file_name()

    try:
        return re.search('app/cells/' + namespaces + '(\w+)/.+\.slim', path).group(1)
    except (IndexError, AttributeError):
        return re.search('app/cells/' + namespaces + '(\w+)_cell\.rb', path).group(1)
    except (IndexError, AttributeError):
        return None

def create_view(window, extension):
    cell_name = get_cell_name(window)

    if cell_name is None:
        return window.status_message('Not a cell view.')

    path = window.active_view().file_name()
    new_path = re.sub('/\w+\.slim', '/' + cell_name + '.' + extension, path)

    window.open_file(new_path)

class CellCreateSass(sublime_plugin.WindowCommand):
    def run(self):
        create_view(self.window, 'sass')

class CellCreateCoffee(sublime_plugin.WindowCommand):
    def run(self):
        create_view(self.window, 'coffee')

class CellOpenAll(sublime_plugin.WindowCommand):
    def run(self):
        cell_name = get_cell_name(self.window)
        pwd = self.window.folders()[0]
        files = subprocess.check_output('pt --follow -g="app/cells/' + namespaces + cell_name + '(_cell\.rb|/.+)" ' + pwd, shell = True).decode('utf-8').split('\n')
        for file in files:
            if file:
                self.window.open_file(file)

class CellOpen(sublime_plugin.WindowCommand):
    def run(self, target):
        cell_name = get_cell_name(self.window)

        if target == 'ruby':
            pattern = cell_name + '_cell\.rb'
        elif target == 'slim':
            pattern = cell_name + '/show\.slim'
        elif target == 'sass':
            pattern = cell_name + '/' + cell_name + '\.sass'
        elif target == 'coffee':
            pattern = cell_name + '/' + cell_name + '\.coffee'
        else:
            return self.window.status_message('Not a valid target.')

        pattern = 'app/cells/' + namespaces + pattern
        pwd = self.window.folders()[0]
        files = subprocess.check_output('pt --follow -g="' + pattern + '" ' + pwd, shell = True).decode('utf-8').split('\n')
        files.remove('')

        if len(files) == 0:
            return self.window.status_message('No ' + target + '.')

        for file in files:
            if file:
                self.window.open_file(file)
