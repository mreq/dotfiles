import sublime
import sublime_plugin

class GitDeleteBranch(sublime_plugin.EventListener):
    def on_activated(self, view):
        (row, col) = view.rowcol(view.selection[0].begin())
        point = view.text_point(row, col)
        point_scope = view.scope_name(point)
        if 'text.git-status' in point_scope:
            # Enter insert mode
            view.run_command('_enter_insert_mode')
