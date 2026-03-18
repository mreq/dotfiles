import * as vscode from "vscode";
import * as path from "path";
import * as fs from "fs";

interface TierConfig {
  id: string;
  key?: string;
}

interface RuleConfig {
  id: string;
  from: string[];
  to: string[];
  tier: string;
  create?: boolean;
  replace?: boolean;
  split?: boolean;
}

export function activate(context: vscode.ExtensionContext): void {
  context.subscriptions.push(
    vscode.commands.registerCommand(
      "fileTierNav.open",
      async (args: { tier?: string; ruleId?: string }) => {
        const tier = args?.tier;
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
          vscode.window.showInformationMessage(
            "File Tier Nav: No active editor."
          );
          return;
        }
        const doc = editor.document;
        const filePath = doc.uri.fsPath;
        const workspaceFolders = vscode.workspace.workspaceFolders ?? [];
        const primaryFolder = vscode.workspace.getWorkspaceFolder(doc.uri);
        if (!primaryFolder && workspaceFolders.length === 0) {
          vscode.window.showInformationMessage(
            "File Tier Nav: File is not in a workspace folder."
          );
          return;
        }

        const foldersContainingFile = workspaceFolders.filter((f) => {
          const rel = path.relative(f.uri.fsPath, filePath);
          return rel !== "" && !rel.startsWith("..") && !path.isAbsolute(rel);
        });
        const firstWorkspaceFolder = workspaceFolders[0];
        const useFirstFolder =
          firstWorkspaceFolder &&
          foldersContainingFile.some(
            (f) => f.uri.fsPath === firstWorkspaceFolder.uri.fsPath
          );
        const candidateFolders: vscode.WorkspaceFolder[] = useFirstFolder
          ? [
              firstWorkspaceFolder,
              ...foldersContainingFile
                .filter((f) => f.uri.fsPath !== firstWorkspaceFolder.uri.fsPath)
                .sort((a, b) => a.uri.fsPath.length - b.uri.fsPath.length),
            ]
          : foldersContainingFile.sort(
              (a, b) => a.uri.fsPath.length - b.uri.fsPath.length
            );

        const tiers = (vscode.workspace
          .getConfiguration("fileTierNav")
          .get<TierConfig[]>("tiers") ?? []) as TierConfig[];
        const rules = (vscode.workspace
          .getConfiguration("fileTierNav")
          .get<RuleConfig[]>("rules") ?? []) as RuleConfig[];

        let rulesToUse: RuleConfig[];
        if (tier !== undefined && tier !== "") {
          rulesToUse = rules.filter((r) => r.tier === tier);
        } else if (args?.ruleId) {
          const r = rules.find((r) => r.id === args.ruleId);
          rulesToUse = r ? [r] : [];
        } else {
          rulesToUse = rules;
        }

        for (const rootFolder of candidateFolders) {
          const rootPath = rootFolder.uri.fsPath;
          const relativePath = path.relative(rootPath, filePath);
          const normalizedRelative = relativePath.split(path.sep).join("/");

          for (const rule of rulesToUse) {
            let match: RegExpMatchArray | null = null;
            for (const from of rule.from) {
              match = normalizedRelative.match(new RegExp(from));
              if (match) break;
            }
            if (!match) continue;

            const toTemplates = rule.to;
            const resolvedPaths = toTemplates.map((tpl) => {
              let p = tpl;
              for (let i = 1; i < match!.length; i++) {
                p = p.replace(new RegExp("\\$" + i, "g"), match![i] ?? "");
              }
              return path.join(rootPath, p);
            });

            // Prefer focusing an existing tab anywhere in the window; only open in active group if not visible.
            const showOptions: vscode.TextDocumentShowOptions = rule.replace
              ? {}
              : { preview: false };

            const showTarget = async (targetUri: vscode.Uri) => {
              const existing = vscode.window.visibleTextEditors.find(
                (e) => e.document.uri.fsPath === targetUri.fsPath
              );
              if (existing?.viewColumn != null) {
                await vscode.window.showTextDocument(existing.document, {
                  viewColumn: existing.viewColumn,
                  preview: false,
                });
                return;
              }
              const targetDoc =
                await vscode.workspace.openTextDocument(targetUri);
              await vscode.window.showTextDocument(targetDoc, showOptions);
            };

            for (const absoluteTarget of resolvedPaths) {
              if (fs.existsSync(absoluteTarget)) {
                await showTarget(vscode.Uri.file(absoluteTarget));
                return;
              }
            }
            if (rule.create && resolvedPaths.length > 0) {
              const absoluteTarget = resolvedPaths[resolvedPaths.length - 1];
              const dir = path.dirname(absoluteTarget);
              if (!fs.existsSync(dir)) {
                fs.mkdirSync(dir, { recursive: true });
              }
              fs.writeFileSync(absoluteTarget, "", "utf8");
              await showTarget(vscode.Uri.file(absoluteTarget));
              return;
            }
          }
        }

        vscode.window.showInformationMessage(
          "File Tier Nav: No matching rule or file not found."
        );
      }
    )
  );
}

export function deactivate(): void {}
