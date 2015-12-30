import sublime
import sublime_plugin
import subprocess

class GitDeleteBranch(sublime_plugin.WindowCommand):
  def run(self):
    view = self.window.active_view()
    cmd = 'cd ' + self.window.folders()[0] + '; git branch | cut -c 3-'
    a = subprocess.check_output(cmd, shell=True)
    branches = bytes.decode(a).splitlines()
    targetBranch = ''
    def doDelete(i):
      global targetBranch
      if i == 0:
        self.window.run_command('git_custom', {
          'cmd': 'branch -d ' + targetBranch,
          'output': 'panel',
          'async': True
        })
    def onDone(i):
      global targetBranch
      if i != -1:
        targetBranch = branches[i]
        options = ['Yes, delete ' + targetBranch + '.', 'Do not delete anything.']
        self.window.show_quick_panel(options, doDelete)
    self.window.show_quick_panel(branches, onDone)
