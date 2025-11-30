import sublime
import sublime_plugin
import re


class ruby_component_convert_path_to_render(sublime_plugin.TextCommand):
    def run(self, edit):
        view = self.view
        sel = view.sel()[0]

        line = view.line(sel)
        line_text = view.substr(line)

        # store whitespace from start of line_text
        leading_whitespace = re.match(r"(\s+)", line_text)

        if leading_whitespace:
            leading_whitespace = leading_whitespace.group(1)
        else:
            leading_whitespace = ""

        component_path = re.sub(r"\s*(app|test)/components/", "", line_text)
        component_path = re.sub(r"_component(_test)?\.\w+", "", component_path)

        parts = component_path.split("_")
        parts = [part[0].upper() + part[1:] for part in parts]
        parts = "".join(parts)

        parts = parts.split("/")
        parts = [part[0].upper() + part[1:] for part in parts]
        component_name = "::".join(parts) + "Component"

        new_line_text = leading_whitespace + "= render(" + component_name + ".new())"

        view.replace(edit, line, new_line_text)

        line = view.line(line.a)
        view.sel().clear()
        view.sel().add(sublime.Region(line.b - 2))
        view.show(line.b - 2)
        view.run_command("nv_enter_insert_mode")


class ruby_component_create_initialize_method(sublime_plugin.TextCommand):
    def run(self, edit):
        view = self.view
        sel = view.sel()[0]

        line = view.line(sel)
        line_text = view.substr(line)

        # store whitespace from start of line_text
        leading_whitespace = re.match(r"(\s+)", line_text)

        if leading_whitespace:
            leading_whitespace = leading_whitespace.group(1)
        else:
            leading_whitespace = ""

        argument_matches = re.sub(r"\s*i\s+", "", line_text).split(" ")

        arguments = [argument + ":" for argument in argument_matches]
        arguments_line = (
            leading_whitespace + "def initialize(" + ", ".join(arguments) + ")"
        )

        attributes = [
            "@" + argument + " = " + argument for argument in argument_matches
        ]
        attributes_lines = ("\n  " + leading_whitespace).join(attributes)

        text = (
            arguments_line
            + "\n  "
            + leading_whitespace
            + attributes_lines
            + "\n"
            + leading_whitespace
            + "end"
        )

        view.replace(edit, line, text)


class ruby_component_insert_bem_class_name(sublime_plugin.TextCommand):
    def run(self, edit):
        view = self.view
        window = self.view.window()
        file_name = window.active_view().file_name()

        if not file_name:
            return window.status_message("No active project view.")

        if "app/components" not in file_name:
            return window.status_message("Not in app/components.")

        component_path = re.sub(
            r"^(.*app/components/)(.*)(_component\.\w+)$", r"\2", file_name
        )
        bem_class_name = re.sub(r"^(\w)\w*/(.*)", r"\1/\2", component_path)
        bem_class_name = re.sub(r"[_/]", r"-", bem_class_name)

        if ".slim" in file_name:
            bem_class_name = "." + bem_class_name

        for sel in view.sel():
            view.insert(edit, sel.a, bem_class_name)
