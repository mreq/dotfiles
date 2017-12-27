import sublime
import sublime_plugin
import subprocess

class SelectSprite(sublime_plugin.WindowCommand):
  def run(self):
    view = self.window.active_view()
    cmd = 'cd ' + self.window.folders()[0] + ';  pt -g=\'.*/sprites(?:@1x)?/.*\.(png|jpeg|jpg|gif)\''
    a = subprocess.check_output(cmd, shell=True)
    sprites = bytes.decode(a).splitlines()

    if len(sprites) > 0:
      sprites = [path.split('/').pop().split('.')[0] for path in sprites]
      sprites = list(set(sprites))
      sprites.sort()

      def onDone(i):
        if i != -1:
          text = sprites[i]
          self.window.active_view().run_command('insert', { 'characters': text })

      self.window.show_quick_panel(sprites, onDone)

    else:
      self.window.status_message('No sprites for cmd: ' + cmd)
