#!/usr/bin/python
############################
# settings
############################
panel_height=24
# win_border=1
win_border=0
# dmenu_alias='dmenu'
dmenu_alias=['dmenu', '-i', '-b', '-l', '10', '-nb', '#242424', '-nf', 'white', '-sb', '#2e557e', '-fn', 'Ubuntu Mono-12']
tmp_file='/home/petr/tmp/wmctrl_tmp_file'
############################
#
####################################################################################
# You shouldn't edit anything under this line unless you know what you're doing :) #
####################################################################################
#
############################
# imports
############################
import sys
import os
import subprocess
import commands
# regex
import re
# for dmenu:
from subprocess import Popen, PIPE
############################
# Helpers
############################
def dmenu(items):
    input_str = "\n".join(items) + "\n"
    proc = Popen(dmenu_alias, stdout=PIPE, stdin=PIPE)
    return proc.communicate(input_str)[0]
############################
# classes
############################
class WindowManager():
    """Stores information such as screen size."""
    def __init__(self):
        self.get_dimensions()
    def get_dimensions(self):
        out = re.search('\d+x\d+', commands.getoutput("xrandr | grep +0+0")).group(0)
        dim = out.split('x')
        self.w = int(dim[0]) - 2*win_border
        self.h = int(dim[1]) - 2*win_border - panel_height
        self.workspace = commands.getoutput("wmctrl -d | grep '\*' | cut -d' ' -f 1")
    def width(self, portion = 0.5):
        return str(int(self.w*portion))
    def height(self, portion = 0.5):
        return str(int(self.h*portion))
    def get_active_win_id(self):
        return commands.getoutput('wmctrl -a :ACTIVE: -v').split('Using window: ')[1]
    def get_hostname(self):
        self.hostname = commands.getoutput('hostname')
        return self.hostname
    def get_window_from_list(self, answer, pretty = True):
        if answer:
            id = answer.split()[0]
            return Window(id)
        else:
            return False
    def build_win_list(self, return_pretty = True, current_workspace_only = True):
        if not hasattr(self, 'win_list'):
            self.win_list = commands.getoutput('wmctrl -lx').split('\n')
            self.win_list_pretty = []

            if not hasattr(self, 'regex'):
                self.regex = re.compile("0x[\d\w]{8}\s+" + self.workspace + "\s")

            if current_workspace_only:
                self.win_list = [ x for x in self.win_list if self.regex.match(x) ]

            if not self.win_list:
                self.win_list = []
                return []
            # print self.win_list

            self.get_hostname()

            names = [ x.split()[2] for x in self.win_list ]
            titles = [ ' '.join(x.split()[3:]).replace(self.hostname, '') for x in self.win_list ]
            mvargs = [ x.split()[0] for x in self.win_list ]

            max_name = max([ len(x) for x in names ])
            max_title = max([ len(x) for x in titles ])

            names = [ x + ' '*(max_name + 3 - len(x)) for x in names ]

            self.win_list_pretty = []
            for i in xrange(0,len(names)):
                self.win_list_pretty.append(mvargs[i] + ' '*3 + names[i] + titles[i])

        if return_pretty:
            return self.win_list_pretty
        else:
            return self.win_list
    def filter_win_list(self, win_string, active_workspace_only = True):
        a = self.build_win_list(False, active_workspace_only)
        if a:
            return [ x for x in a if win_string in x ]
        else:
            return []
    def prompt_for_win(self):
        win_list = self.build_win_list()
        return self.get_window_from_list(dmenu(win_list), True)
    def prompt_for_portion(self):
        # return dmenu([ str(x) for x in xrange(20, 80, 5) ])
        return dmenu('50 60 20 25 30 35 40 45 55 65 70 75 80'.split())
    def summon(self, win_string, cmd_to_launch):
        arr = commands.getoutput("wmctrl -lx | grep " + win_string + " | awk '{print $1}'").split('\n')
        if len(arr) and arr[0]:
            active = self.get_active_win_id()

            if len(arr) > 1 and active in arr:
                i = arr.index(active)
                if len(arr) > (i+1):
                    target = arr[i+1]
                else:
                    target = arr[0]
            else:
                target = arr[0]
            print('wmctrl -iR ' + target)
            subprocess.check_call('wmctrl -iR ' + target, shell=True)
        else:
            if cmd_to_launch:
                subprocess.check_call(cmd_to_launch, shell=True)
    def switch_to_generic(self, win_string, callback_success, callback_error):
        arr = self.filter_win_list(win_string, True)
        if len(arr):
            active = self.get_active_win_id()

            active_item = [ x for x in arr if active in x ]

            if len(arr) > 1 and active_item:
                i = arr.index(active_item[0])

                if len(arr) > (i+1):
                    target = arr[i+1]
                else:
                    target = arr[0]
            else:
                target = arr[0]

            callback_success(target.split()[0])
        else:
            callback_error()
    def switch_to(self, win_string, cmd_to_launch):
        def callback_success(a):
            subprocess.check_call('wmctrl -ia ' + a, shell=True)
        def callback_error():
            subprocess.check_call(cmd_to_launch, shell=True)
        self.switch_to_generic(win_string, callback_success, callback_error)
    def switch_to_running(self, win_string, ico):
        def callback_success(a):
            subprocess.check_call('wmctrl -ia ' + a, shell=True)
        def callback_error():
            if ico:
                subprocess.check_call('notify-send -i ' + ico + ' "' + ico + '" "' + ico + ' is not running."', shell=True)
        self.switch_to_generic(win_string, callback_success, callback_error)
    def get_win_ids_from_names(self, first_name, second_name):
        a = self.filter_win_list(first_name)
        b = self.filter_win_list(second_name)
        if len(a) and len(b):
            return [Window(a[0].split()[0]), Window(b[0].split()[0])]



class Window():
    """docstring for Window"""
    def __init__(self, id):
        self.id = id
        self.default_movement = { 'x': '0', 'y': 0, 'width': '-1', 'height': '-1' }
    def add_win_borders(self, how_to_move):
        if how_to_move['x'] != '0':
            how_to_move['x'] = str(int(how_to_move['x']) + win_border)
        if how_to_move['y'] != '0':
            how_to_move['y'] = str(int(how_to_move['y']) + win_border + panel_height)
        if how_to_move['width'] != '-1':
            how_to_move['width'] = str(int(how_to_move['width']) - 2*win_border)
        if how_to_move['height'] != '-1':
            how_to_move['height'] = str(int(how_to_move['height']) - 2*win_border - panel_height)
        return how_to_move
    def move(self, how_to_move):
        a = self.default_movement
        a.update(how_to_move)
        a = self.add_win_borders(a)
        cmd = '-e 0,' + a['x'] + ',' + a['y'] + ',' + a['width'] + ',' + a['height']
        self.unshade().wmctrl(cmd)
    def wmctrl(self, cmd):
        subprocess.check_call('wmctrl -i -r ' + self.id + ' ' + cmd, shell=True)
        return self
    def maximize(self, horz = True, vert = True):
        if horz and vert:
            self.wmctrl('-b add,maximized_vert,maximized_horz')
        elif horz:
            self.wmctrl('-b add,maximized_horz')
            self.wmctrl('-b remove,maximized_vert')
        elif vert:
            self.wmctrl('-b add,maximized_vert')
            self.wmctrl('-b remove,maximized_horz')
        else:
            self.wmctrl('-b remove,maximized_vert,maximized_horz')
        return self
    def unmaximize(self):
        return self.maximize(False, False)
    def shade(self):
        return self.wmctrl('-b add,shaded')
    def unshade(self):
        return self.wmctrl('-b remove,shaded')
    def toggle_sticky(self):
        pass
    def show(self):
        subprocess.check_call('wmctrl -i -R ' + self.id, shell=True)
        return self

class WindowTiler():
    """docstring for WindowTiler"""
    def __init__(self):
        self.wm = WindowManager()
    def snap(self, direction, portion = 0.5):
        if portion == None:
            portion = 0.5
        else:
            portion = float(portion)
        win = Window(self.wm.get_active_win_id())
        self.snap_win(win, direction, portion)
        self.log('snap', direction, portion, win.id)
    def snap_win(self, win, direction, portion):
        if direction == 'top':
            how_to_move = { 'width': self.wm.width(1), 'height': self.wm.height(portion) }
        elif direction == 'bottom':
            how_to_move = { 'width': self.wm.width(1), 'height': self.wm.height(portion), 'y': self.wm.height(1-portion) }
        elif direction == 'right':
            how_to_move = { 'height': self.wm.height(1), 'width': self.wm.width(portion), 'x': self.wm.width(1-portion) }
        else: # left
            how_to_move = { 'height': self.wm.height(1), 'width': self.wm.width(portion) }
        win.unmaximize().move(how_to_move)
    def shade(self):
        Window(self.wm.get_active_win_id()).shade()
    def unshade(self):
        Window(self.wm.get_active_win_id()).unshade()
    def maximize(self, horz, vert):
        Window(self.wm.get_active_win_id()).maximize(int(horz), int(vert))
    def tile_two(self, tile_type = 'horz', portion = None, first_win = None, second_win = None):
        if first_win and second_win:
            first_win, second_win = self.wm.get_win_ids_from_names(first_win, second_win)
        else:
            first_win = None
            second_win = None

        if tile_type == None:
            tile_type = 'horz'

        if not first_win:
            first_win = self.wm.prompt_for_win()
            if not first_win:
                return False
        if not second_win:
            second_win = self.wm.prompt_for_win()
            if not second_win:
                return False


        if not portion:
            portion = float(self.wm.prompt_for_portion())/100
            if not portion:
                return False
        else:
            portion = float(portion)

        if tile_type == 'horz':
            self.snap_win(first_win, 'left', portion)
            self.snap_win(second_win, 'right', 1-portion)
        elif tile_type == 'vert':
            self.snap_win(first_win, 'top', portion)
            self.snap_win(second_win, 'bottom', 1-portion)

        first_win.show()
        second_win.show()

        self.log('tile', tile_type, portion, first_win.id, second_win.id)
    def resize_tile(self, tmp_file, direction, portion_change = 0.05):
        tile, tile_type, portion, first_id, second_id = tmp_file
        portion = float(portion)
        if tile_type == 'horz':
            if direction == 'left':
                new_portion = portion - portion_change
            elif direction == 'right':
                new_portion = portion + portion_change
        elif tile_type == 'vert':
            if direction == 'top':
                new_portion = portion - portion_change
            elif direction == 'bottom':
                new_portion = portion + portion_change

        if new_portion < 0:
            new_portion = 0
        elif new_portion > 1:
            new_portion = 1

        first_win = Window(first_id)
        if not first_win:
            return False
        second_win = Window(second_id)
        if not second_win:
            return False


        if tile_type == 'horz':
            self.snap_win(first_win, 'left', new_portion)
            self.snap_win(second_win, 'right', 1-new_portion)
        elif tile_type == 'vert':
            self.snap_win(first_win, 'top', new_portion)
            self.snap_win(second_win, 'bottom', 1-new_portion)

        self.log('tile', tile_type, new_portion, first_id, second_id)
    def resize_snap(self, tmp_file, direction, portion_change = 0.05):
        snap_dir = tmp_file[1]
        portion = float(tmp_file[2])
        win_id = tmp_file[3]

        win = Window(win_id)


        if snap_dir == 'left':
            if direction == 'left':
                new_portion = portion - portion_change
            elif direction == 'right':
                new_portion = portion + portion_change
        elif snap_dir == 'right':
            if direction == 'left':
                new_portion = portion + portion_change
            elif direction == 'right':
                new_portion = portion - portion_change

        if new_portion < 0:
            new_portion = 0
        elif new_portion > 1:
            new_portion = 1

        self.snap_win(win, snap_dir, new_portion)
        self.log('snap', snap_dir, new_portion, win_id)
    def resize(self, direction, portion_change = 0.05):
        portion_change = float(portion_change)
        tmp_file = self.load_tmp_file()
        name = tmp_file[0]
        if name == 'snap':
            self.resize_snap(tmp_file, direction, portion_change)
        elif name == 'tile':
            self.resize_tile(tmp_file, direction, portion_change)

    def log(self, *args):
        ar = [ str(x) for x in args ]
        subprocess.check_call('echo "' + '\n'.join(ar) + '" > ' + tmp_file, shell=True)
    def load_tmp_file(self):
        return commands.getoutput('cat ' + tmp_file).split('\n')


class WindowSwitcher():
    """docstring for WindowSwitcher"""
    def __init__(self):
        pass
############################
# Help
############################
def print_help():
    print """
A simple tiling script I wrote. Since you're reading this, you know how to invoke it.

Usage:

  Invoke the script like you just did, but with different arguments:

    snap <left/right/top/bottom> <portion_of_screen>
     - Snaps the window in the specified direction, stretching it on portion_of_screen.
     - e.g. to snap the window on the left 65% of the screen:
         snap left 0.65

    maximize <horizontally> <vertically>
     - Maximizes/minimizes the window vertically and/or horizontally. To maximize:
         maximize 1 1
     - to minize:
         maximize 0 0

    shade
     - Shades the window (aka sends it to the background).

    unshade
     - Unshades the window (aka makes it visible again).

    """
############################
# Bind bash arguments
############################
try:
    if len(sys.argv) > 1:
        bash_args = sys.argv
        for i in xrange(1,5):
            bash_args.append(None)

        wt = WindowTiler()
        # snap direction portion
        if bash_args[1] == 'help':
            print_help()
        elif bash_args[1] == '--help':
            print_help()
        elif bash_args[1] == 'snap':
            wt.snap(bash_args[2], bash_args[3])
        elif bash_args[1] == 'shade':
            wt.shade()
        elif bash_args[1] == 'unshade':
            wt.unshade()
        elif bash_args[1] == 'maximize':
            wt.maximize(bash_args[2], bash_args[3])
        elif bash_args[1] == 'tile_two':
            wt.tile_two(bash_args[2], bash_args[3], bash_args[4], bash_args[5])
        elif bash_args[1] == 'resize':
            wt.resize(bash_args[2], bash_args[3])
        elif bash_args[1] == 'switch_to':
            wt.wm.switch_to(bash_args[2], bash_args[3])
        elif bash_args[1] == 'summon':
            wt.wm.summon(bash_args[2], bash_args[3])
        elif bash_args[1] == 'switch_to_running':
            wt.wm.switch_to_running(bash_args[2], bash_args[3])
    # kill previous
    os.system('killall -o 10s wmctile > /dev/null')
except Exception as err:
    os.system('notify-send -i error "wmctile.py" "'+str(err)+'"')
