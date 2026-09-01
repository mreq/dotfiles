"""
Small YAML path navigator derived from ddiachkov/sublime-yaml-nav.

Copyright (c) 2013-2016 Denis Diachkov

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

import re

import sublime
import sublime_plugin

STATUS_KEY = "yaml_nav"
UPDATE_DELAY_MS = 400
YAML_KEY_SELECTOR = "meta.mapping.key.yaml"
LOCALE_PATH_RE = re.compile(r"[/\\]locales?[/\\.]")

_symbols_by_view = {}
_update_generations = {}
_scheduled_views = set()


def _is_yaml(view):
    return view.match_selector(0, "source.yaml")


def _key_name(view, region):
    name = view.substr(region).strip()

    if "\n" in name:
        return None

    if len(name) >= 2 and name[0] == name[-1] and name[0] in ("'", '"'):
        name = name[1:-1]

    return name.lstrip(":")


def _build_symbols(view):
    symbols = []
    current_path = []

    for region in view.find_by_selector(YAML_KEY_SELECTOR):
        name = _key_name(view, region)
        if not name:
            continue

        line = view.line(region.begin())
        indent = region.begin() - line.begin()

        while current_path and current_path[-1]["indent"] >= indent:
            current_path.pop()

        current_path.append({"name": name, "indent": indent})
        symbols.append(
            {
                "name": ".".join(item["name"] for item in current_path),
                "region": region,
            }
        )

    return symbols


def _selected_symbol(view, symbols):
    selections = list(view.sel())
    if len(selections) != 1:
        return None

    selected_line = view.line(selections[0])
    for symbol in reversed(symbols):
        if selected_line.intersects(symbol["region"]):
            return symbol

    return None


def _update_status(view):
    symbol = _selected_symbol(view, _symbols_by_view.get(view.id(), []))

    if symbol:
        view.set_status(STATUS_KEY, "YAML path: " + symbol["name"])
    else:
        view.erase_status(STATUS_KEY)


def _clear_view(view):
    view_id = view.id()
    _symbols_by_view.pop(view_id, None)
    _update_generations.pop(view_id, None)
    _scheduled_views.discard(view_id)
    if view.is_valid():
        view.erase_status(STATUS_KEY)


def _refresh(view):
    if not view.is_valid() or not _is_yaml(view):
        _clear_view(view)
        return

    _symbols_by_view[view.id()] = _build_symbols(view)
    _update_status(view)


def _schedule_refresh(view, delay_ms=UPDATE_DELAY_MS):
    view_id = view.id()
    generation = _update_generations.get(view_id, 0) + 1
    _update_generations[view_id] = generation

    if view_id in _scheduled_views:
        return

    _scheduled_views.add(view_id)

    def run(expected_generation):
        if not view.is_valid():
            _clear_view(view)
            return

        current_generation = _update_generations.get(view_id)
        if current_generation != expected_generation:
            sublime.set_timeout_async(lambda: run(current_generation), UPDATE_DELAY_MS)
            return

        _scheduled_views.discard(view_id)
        _refresh(view)

    sublime.set_timeout_async(lambda: run(generation), delay_ms)


def _symbols_for(view):
    symbols = _symbols_by_view.get(view.id())
    if symbols is None:
        _refresh(view)
        symbols = _symbols_by_view.get(view.id(), [])
    return symbols


class YamlNavListener(sublime_plugin.EventListener):
    def on_new_async(self, view):
        _schedule_refresh(view, 0)

    def on_load_async(self, view):
        _schedule_refresh(view, 0)

    def on_activated_async(self, view):
        _schedule_refresh(view, 0)

    def on_modified_async(self, view):
        if _is_yaml(view):
            _schedule_refresh(view)

    def on_selection_modified_async(self, view):
        if _is_yaml(view):
            _update_status(view)

    def on_close(self, view):
        _clear_view(view)


class GotoYamlSymbolCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        symbols = _symbols_for(self.view)
        window = self.view.window()
        if not window:
            return

        def on_symbol_selected(index):
            if index < 0:
                return

            region = symbols[index]["region"]
            self.view.show_at_center(region)
            self.view.sel().clear()
            self.view.sel().add(sublime.Region(region.end() + 1))

        window.show_quick_panel(
            [symbol["name"] for symbol in symbols], on_symbol_selected
        )

    def is_enabled(self):
        return _is_yaml(self.view)


class CopyYamlSymbolToClipboardCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        symbol = _selected_symbol(self.view, _symbols_for(self.view))
        if not symbol:
            self.view.set_status(STATUS_KEY, "YAML path: nothing selected")
            return

        name = symbol["name"]
        file_name = self.view.file_name() or ""
        if LOCALE_PATH_RE.search(file_name) and "." in name:
            name = name.split(".", 1)[1]

        sublime.set_clipboard(name)
        self.view.set_status(STATUS_KEY, "YAML path: " + name + " - copied")

    def is_enabled(self):
        return _is_yaml(self.view)
