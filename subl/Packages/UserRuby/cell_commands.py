import sublime
import sublime_plugin
import re
import subprocess

# because recursion is painfully slow
namespaces = '(' + '(?:\w+/?)?' * 5 + ')'


def get_cell_name(window):
    view = window.active_view()
    path = view.file_name()

    results = re.search(
        '(?:app|source)/cells/' + namespaces + '/\w+\.(slim|sass|coffee)',
        path)
    if results:
        return results.group(1)
    else:
        results = re.search('(?:app|source)/cells/' + namespaces + '_cell\.rb',
                            path)
        if results:
            return results.group(1)
        else:
            results = re.search('test/cells/' + namespaces + '_cell_test\.rb',
                                path)
            if results:
                return results.group(1)
            else:
                results = re.search(
                    'app/models/' + namespaces + '/atom/' + namespaces +
                    '\.rb', path)
                if results:
                    return results.group(1) + '/atom/' + results.group(2)

    return None


def create_view(window, extension):
    cell_name = get_cell_name(window)

    if cell_name is None:
        return window.status_message('Not a cell view.')

    cell_base_name = cell_name.split('/').pop()

    path = window.active_view().file_name()
    if '_cell.rb' in path:
        new_path = re.sub('/_cell.rb', '/' + cell_name + '.' + extension, path)
    else:
        new_path = re.sub('/\w+\.slim', '/' + cell_base_name + '.' + extension,
                          path)

    window.open_file(new_path)


def clear_sprockets_cache(window):
    subprocess.call('rm -r tmp/cache/assets/sprockets/*', shell=True)


class CellCreateSass(sublime_plugin.WindowCommand):
    def run(self):
        create_view(self.window, 'sass')
        clear_sprockets_cache(self.window)


class CellCreateCoffee(sublime_plugin.WindowCommand):
    def run(self):
        create_view(self.window, 'coffee')


class CellOpen(sublime_plugin.WindowCommand):
    def run(self, target):
        cell_name = get_cell_name(self.window)

        if cell_name:
            cell_base_name = cell_name.split('/').pop()

            if target == 'ruby':
                pattern = '(app|source)/cells/' + cell_name + '_cell\.rb'
            elif target == 'slim':
                pattern = '(app|source)/cells/' + cell_name + '/show\.slim'
            elif target == 'sass':
                pattern = '(app|source)/cells/' + cell_name + '/' + cell_base_name + '\.sass'
            elif target == 'coffee':
                pattern = '(app|source)/cells/' + cell_name + '/' + cell_base_name + '\.coffee'
            elif target == 'test':
                pattern = 'test/cells/' + cell_name + '_cell_test\.rb'
            else:
                return self.window.status_message('Not a valid target.')
        else:
            return self.window.status_message('No ' + target + '.')

        pwd = self.window.folders()[0]

        try:
            files = subprocess.check_output(
                'rg --files ' + pwd + ' | rg "' + pattern + '" ',
                shell=True).decode('utf-8').split('\n')
            files.remove('')
        except subprocess.CalledProcessError as e:
            return self.window.status_message('No ' + target + '.')

        for file in files:
            if file:
                self.window.open_file(file)
