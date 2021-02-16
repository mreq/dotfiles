import sublime
import sublime_plugin
import re
import subprocess

class BracketWrapper(sublime_plugin.WindowCommand):
    def run(self, target):
        cell_name = ruby_cell_utils.get_cell_name(self.window)

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
            controller_name = ruby_cell_utils.get_controller_name(self.window)
            if controller_name:
                if target == 'slim':
                    pattern = 'app/controllers/' + controller_name + '\.rb'
                elif target == 'test':
                    pattern = 'test/controllers/' + controller_name + '_test\.rb'
                else:
                    return self.window.status_message('Not a valid target.')
            else:
                return self.window.status_message('Not a cell/controller.')

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
