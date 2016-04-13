atom.commands.add 'atom-workspace',
  'custom:close-panes': ->
    editors = atom.workspace.getTextEditors()
    activeEditor = atom.workspace.getActiveTextEditor()
    for editor in editors
      editor.destroy() 
