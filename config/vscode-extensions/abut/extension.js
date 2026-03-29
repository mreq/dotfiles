const vscode = require('vscode');
const path = require('path');

exports.activate = (ctx) => {
  const loadItems = async (dir) => {
    const uri = vscode.Uri.file(dir);
    const parent = path.dirname(dir);
    const entries = await vscode.workspace.fs.readDirectory(uri);
    const dirs = entries.filter(([, t]) => t === vscode.FileType.Directory).map(([n]) => n).sort();
    const files = entries.filter(([, t]) => t === vscode.FileType.File).map(([n]) => n).sort();
    const items = [];
    if (parent !== dir)
      items.push({ label: '..', description: 'parent directory', fullPath: parent, isDir: true });
    dirs.forEach(d => items.push({ label: d + '/', fullPath: path.join(dir, d), isDir: true }));
    files.forEach(f => items.push({ label: f, fullPath: path.join(dir, f), isDir: false }));
    return items;
  };

  ctx.subscriptions.push(vscode.commands.registerCommand('abut.open', async () => {
    const editor = vscode.window.activeTextEditor;
    if (!editor) return;
    let currentDir = path.dirname(editor.document.uri.fsPath);

    const qp = vscode.window.createQuickPick();
    qp.placeholder = currentDir;
    qp.items = await loadItems(currentDir);

    qp.onDidAccept(async () => {
      const [sel] = qp.selectedItems;
      if (!sel) return;
      if (sel.isDir) {
        currentDir = sel.fullPath;
        qp.value = '';
        qp.placeholder = currentDir;
        qp.items = await loadItems(currentDir);
      } else {
        vscode.window.showTextDocument(vscode.Uri.file(sel.fullPath));
        qp.hide();
      }
    });

    qp.onDidHide(() => qp.dispose());
    qp.show();
  }));
};

exports.deactivate = () => {};
