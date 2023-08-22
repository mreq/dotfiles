import re
import os.path
import sublime
import time

# because recursion is painfully slow
namespaces = '(' + '(?:\w+/?)?' * 7 + ')'

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

def get_controller_name(window):
    view = window.active_view()
    path = view.file_name()
    results = re.search('controllers/(.+_controller)(?:_test)?\.rb', path)
    if results and results.group(1):
        return results.group(1)
    else:
        return None

def get_component_name(window):
    view = window.active_view()
    path = view.file_name()
    results = re.search('components/(.+_component)(?:_test)?\.(rb|slim|sass|js)', path)
    if results and results.group(1):
        return results.group(1)
    else:
        return None

def create_view(window, extension, alt_extension = None):
    name = get_cell_name(window)

    if name is None:
        name = get_component_name(window)

        if name is None:
            return window.status_message('Not a cell/component view.')

    base_name = name.split('/').pop()

    source_view = window.active_view()
    path = source_view.file_name()
    new_path = None

    for ext in [alt_extension, extension]:
        if ext:
            if '_cell.rb' in path:
                new_path = re.sub('_cell.rb', '/' + base_name + '.' + ext,
                                  path)
            elif '_component.' in path:
                new_path = re.sub(base_name + '\.\w+', base_name + '.' + ext,
                                  path)
            else:
                new_path = re.sub('/\w+\.slim', '/' + base_name + '.' + ext,
                                  path)

            if os.path.isfile(new_path):
                return window.open_file(new_path)

    if new_path:
        layout = window.layout()
        if len(layout['cols']) == 2:
          window.run_command("create_pane", { "direction": "right", "give_focus": True })
        else:
          window.run_command("travel_to_pane", { "direction": "right", "create_new_if_necessary": False })

        new_view = window.open_file(new_path)

        if ext is 'sass' or ext is 'scss':
            class_name = None

            if path.endswith('.slim'):
                first_line = source_view.substr(source_view.line(0))
                if '[' not in first_line:
                    if len(re.findall('\.', first_line)) == 1:
                        class_name = first_line  + "\n  "

            if not class_name:
                class_name = re.sub(r"[\/_]", "-", re.sub(r"^(\w)\w+\/", ".\\1/", name)) + "\n  "

            def append():
                new_view.run_command("append", { "characters": class_name })
                new_view.sel().clear()
                new_view.sel().add(sublime.Region(len(class_name)))
                new_view.run_command("nv_enter_insert_mode")

            sublime.set_timeout(append, 0)
