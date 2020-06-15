import re

# because recursion is painfully slow
namespaces = '(' + '(?:\w+/?)?' * 6 + ')'

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
    results = re.search('controllers/(.+_controller)(?:_test)?.rb', path)
    if results and results.group(1):
        return results.group(1)
    else:
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
