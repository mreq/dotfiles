import os
import sublime
import sublime_plugin

class ShowOverlayFolder(sublime_plugin.WindowCommand):
    def run(self):
        window = self.window
        view = window.active_view()
        folders = window.folders()
        path = view.file_name()
        if path:
            path = path.replace(os.path.basename(path), '')
            for folder in folders:
                if folder in path:
                    path = path.replace(folder, '')[1:]
                    break
            window.run_command('show_overlay', {
                'overlay': 'goto', 'show_files': True,
                'text': path
            })
