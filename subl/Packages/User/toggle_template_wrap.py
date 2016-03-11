import sublime_plugin
import re

class ToggleTemplateWrap(sublime_plugin.TextCommand):
    def run(self, edit):
        view = self.view
        line = view.line(view.sel()[0])
        line_text = view.substr(line)
        # if re.match(r'^\s*[^\s\(]+\(', line_text):
        #     new_text = re.sub(r'\((.+)\)', r' \1 ', line_text)
        #     return view.replace(edit, line, new_text)
        # else:
        # wrap the arguments
        new_text = re.sub(r'(\s*)((=\s*)?[\w-]+)\s*(.+)$', self.re_sub_expand, line_text.rstrip())
        return view.replace(edit, line, new_text)

    def re_sub_expand(self, match):
        groups = match.groups()
        whitespace = groups[0]
        element_name = groups[1]
        has_equal_sign = groups[2] is not None
        arguments = '\n  ' + whitespace + re.sub(' ', '\n  ' + whitespace, groups[3])
        if has_equal_sign:
            element_name = re.sub(groups[2], '', element_name)
        new_text = whitespace + element_name + '[' + arguments + '\n' + whitespace + ']'
        return new_text

# ('', 'bottom-bar', None, 'photoCollection=photoCollection backLink="goBack" modelType="photoCollectionItem" buttonAction="goToCart" dontTrackCount=true')
# ('  ', '= cart-breadcrumb', '= ', 'secondStep="goBack" typeTitle=photoCollection.collectionType.title supportsCaptions=photoCollection.supportsCaptions isPoster=photoCollection.isPoster')