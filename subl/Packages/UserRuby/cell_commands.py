import sublime
import sublime_plugin
import re
import subprocess

namespaces = '(?:\w+/)*'
with_namespaces = '(\w+/)*'

def get_cell_name(window, include_namespaces = True):
    view = window.active_view()
    path = view.file_name()

    namespace_part = with_namespaces if include_namespaces else namespaces

    results = re.search('(app|source)/cells/' + namespace_part + '(\w+)/.+\.(slim|sass|coffee)', path)
    if results:
        if include_namespaces:
            return results.group(2) + results.group(3)
        else:
            return results.group(2)
    else:
        results = re.search('(app|source)/cells/' + namespace_part + '(\w+)_cell\.rb', path)
        if results:
            if include_namespaces:
                return results.group(2) + results.group(3)
            else:
                return results.group(2)
        else:
            results = re.search('test/cells/' + namespace_part + '(\w+)_cell_test\.rb', path)
            if results:
                if include_namespaces:
                    return results.group(1) + results.group(2)
                else:
                    return results.group(1)

    return None

def create_view(window, extension):
    cell_name = get_cell_name(window, False)

    if cell_name is None:
        return window.status_message('Not a cell view.')

    path = window.active_view().file_name()
    new_path = re.sub('/\w+\.slim', '/' + cell_name + '.' + extension, path)

    window.open_file(new_path)

def clear_sprockets_cache(window):
    subprocess.call('rm -r tmp/cache/assets/sprockets/*', shell = True)

class CellCreateSass(sublime_plugin.WindowCommand):
    def run(self):
        create_view(self.window, 'sass')
        clear_sprockets_cache(self.window)

class CellCreateCoffee(sublime_plugin.WindowCommand):
    def run(self):
        create_view(self.window, 'coffee')

class CellOpenAll(sublime_plugin.WindowCommand):
    def run(self):
        cell_name = get_cell_name(self.window)
        pwd = self.window.folders()[0]
        files = subprocess.check_output('rg --files ' + pwd + ' | rg "(app|source)/cells/' + namespaces + cell_name + '(_cell\.rb|/.+)" ', shell = True).decode('utf-8').split('\n')
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

        pattern = '(app|source)/cells/' + namespaces + pattern
        pwd = self.window.folders()[0]

        try:
            files = subprocess.check_output('rg --files ' + pwd + ' | rg "' + pattern + '" ', shell = True).decode('utf-8').split('\n')
            files.remove('')
        except subprocess.CalledProcessError as e:
            return self.window.status_message('No ' + target + '.')

        for file in files:
            if file:
                self.window.open_file(file)
