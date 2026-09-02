import os
import re
import shutil
import subprocess
import tempfile

import sublime
import sublime_plugin

CODEX_MODEL = "gpt-5.6-luna"
CODEX_REASONING_EFFORT = "low"
RECENT_SUBJECT_LIMIT = 12
STATUS_KEY = "user_git.codex_commit_message"
FINAL_STATUS_DURATION_MS = 4000
GENERATING_VIEW_IDS = set()
ERROR_PANEL_NAME = "user_git_codex"
MAX_ERROR_OUTPUT_LENGTH = 4000

PROMPT = """Generate one Git commit message from the supplied diff.
Do not use tools or infer repository contents beyond that diff.
Return only the commit message as plain text, without Markdown or commentary.
Use a Conventional Commits subject: type(scope): description, or type: description
when no useful scope is clear. Keep the subject imperative and at most 72
characters. After one blank line, add one super-concise explanatory sentence.
Use recent commit subjects only as a style and terminology reference. The diff
is the source of truth for the commit's intent."""

SENSITIVE_SUFFIXES = (".key", ".pem", ".p12", ".pfx", ".jks", ".token")
SENSITIVE_FILENAMES = {
    ".env",
    ".netrc",
    ".npmrc",
    ".pypirc",
    "auth.json",
    "credentials",
    "id_ed25519",
    "id_rsa",
    "kubeconfig",
    "secret",
    "secrets",
}
SENSITIVE_PREFIXES = (".env.", "credentials.", "secret.", "secrets.")
CONVENTIONAL_SUBJECT = re.compile(r"^[a-z][a-z0-9-]*(\([A-Za-z0-9./_-]+\))?!?:\s+\S.*$")


def set_final_status(view_id, message):
    GENERATING_VIEW_IDS.discard(view_id)
    view = sublime.View(view_id)
    if not view.is_valid():
        return

    view.set_status(STATUS_KEY, message)
    sublime.set_timeout(
        lambda: clear_final_status(view_id, message), FINAL_STATUS_DURATION_MS
    )


def clear_final_status(view_id, message):
    view = sublime.View(view_id)
    if view.is_valid() and view.get_status(STATUS_KEY) == message:
        view.erase_status(STATUS_KEY)


def show_error_panel(view_id, diagnostics):
    view = sublime.View(view_id)
    if not view.is_valid():
        return

    window = view.window()
    if not window:
        return

    diagnostics = diagnostics.strip() or "Codex exited without a diagnostic message."
    panel = window.create_output_panel(ERROR_PANEL_NAME)
    panel.set_read_only(False)
    panel.run_command("select_all")
    panel.run_command("right_delete")
    panel.run_command(
        "append",
        {
            "characters": "Codex commit-message generation failed:\n\n"
            + diagnostics[:MAX_ERROR_OUTPUT_LENGTH]
            + "\n"
        },
    )
    panel.set_read_only(True)
    window.run_command("show_panel", {"panel": "output." + ERROR_PANEL_NAME})


class CodexError(RuntimeError):
    def __init__(self, returncode, diagnostics):
        RuntimeError.__init__(self, "Codex exited with status " + str(returncode))
        self.returncode = returncode
        self.diagnostics = diagnostics


def commit_message_region(view):
    regions = view.find_by_selector("meta.commit.message")
    return regions[0] if regions else sublime.Region(0, 0)


def commit_message(view):
    return view.substr(commit_message_region(view))


def diff_args(include_unstaged, amend):
    args = ["diff", "--no-ext-diff", "--no-color"]
    if include_unstaged:
        args.append("HEAD^" if amend else "HEAD")
    else:
        args.append("--cached")
    return args


def run_git(repo_path, args):
    process = subprocess.Popen(
        ["git"] + args,
        cwd=repo_path,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    output, _ = process.communicate()
    if process.returncode == 0:
        return output

    raise RuntimeError("Git diff failed")


def is_sensitive_path(path):
    filename = os.path.basename(path).lower()
    return (
        filename in SENSITIVE_FILENAMES
        or filename.startswith(SENSITIVE_PREFIXES)
        or filename.endswith(SENSITIVE_SUFFIXES)
    )


def has_sensitive_path(repo_path, args):
    path_args = args + ["--name-only", "-z"]
    paths = run_git(repo_path, path_args).split(b"\0")
    return any(
        is_sensitive_path(path.decode("utf-8", "replace")) for path in paths if path
    )


def recent_commit_subjects(repo_path):
    try:
        return run_git(
            repo_path,
            ["log", "-n", str(RECENT_SUBJECT_LIMIT), "--format=%s"],
        )
    except RuntimeError:
        return b""


def valid_commit_message(message):
    message = message.strip()
    if "```" in message or "\n\n" not in message:
        return None

    subject, body = message.split("\n\n", 1)
    if (
        not CONVENTIONAL_SUBJECT.match(subject)
        or len(subject) > 72
        or not body.strip()
        or "\n" in body
        or len(body) > 200
    ):
        return None

    return message


class GitGenerateCommitMessageWithCodexCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        view = self.view
        settings = view.settings()
        repo_path = settings.get("git_savvy.repo_path")

        if not repo_path:
            set_final_status(view.id(), "Codex: no GitSavvy repository is available.")
            return
        if not shutil.which("codex"):
            set_final_status(view.id(), "Codex: CLI is unavailable.")
            return
        if view.id() in GENERATING_VIEW_IDS:
            return

        include_unstaged = settings.get("git_savvy.commit_view.include_unstaged", False)
        amend = settings.get("git_savvy.commit_view.amend", False)
        original_message = commit_message(view)
        GENERATING_VIEW_IDS.add(view.id())
        view.set_status(STATUS_KEY, "Codex: generating commit message…")
        sublime.set_timeout_async(
            lambda: self.generate(
                view.id(),
                repo_path,
                include_unstaged,
                amend,
                original_message,
            ),
            0,
        )

    def generate(self, view_id, repo_path, include_unstaged, amend, original_message):
        try:
            args = diff_args(include_unstaged, amend)
            if has_sensitive_path(repo_path, args):
                self.report(view_id, "Codex: skipped potentially sensitive changes.")
                return

            diff = run_git(repo_path, args)
            if not diff:
                self.report(view_id, "Codex: no changes to describe.")
                return

            suggestion = self.run_codex(diff, recent_commit_subjects(repo_path))
            if not suggestion:
                self.report(view_id, "Codex: returned an invalid commit message.")
                return
        except CodexError as error:
            self.report(
                view_id,
                "Codex: generation failed (exit " + str(error.returncode) + ").",
                error.diagnostics,
            )
            return
        except OSError as error:
            self.report(view_id, "Codex: generation failed.", str(error))
            return
        except RuntimeError:
            self.report(view_id, "Codex: unable to read the commit diff.")
            return

        sublime.set_timeout(
            lambda: self.apply_suggestion(view_id, original_message, suggestion), 0
        )

    def run_codex(self, diff, recent_subjects):
        with tempfile.TemporaryDirectory(prefix="sublime-git-codex-") as directory:
            output_path = os.path.join(directory, "message")
            command = [
                "codex",
                "exec",
                "--ignore-user-config",
                "--ephemeral",
                "--disable",
                "shell_tool",
                "--sandbox",
                "read-only",
                "--skip-git-repo-check",
                "--color",
                "never",
                "--json",
                "--model",
                CODEX_MODEL,
                "--config",
                'cli_auth_credentials_store="keyring"',
                "--config",
                'model_reasoning_effort="' + CODEX_REASONING_EFFORT + '"',
                "--config",
                "tools.web_search=false",
                "--cd",
                directory,
                "--output-last-message",
                output_path,
                PROMPT,
            ]
            process = subprocess.Popen(
                command,
                stdin=subprocess.PIPE,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
            )
            context = diff
            if recent_subjects:
                context += b"\n\nRecent commit subjects (style reference only):\n"
                context += recent_subjects
            _, diagnostics = process.communicate(context)
            if process.returncode != 0:
                raise CodexError(
                    process.returncode, diagnostics.decode("utf-8", "replace")
                )

            try:
                with open(output_path, encoding="utf-8") as output:
                    return valid_commit_message(output.read())
            except OSError:
                return None

    def apply_suggestion(self, view_id, original_message, suggestion):
        view = sublime.View(view_id)
        if view.is_valid():
            view.run_command(
                "git_apply_codex_commit_message",
                {"expected_message": original_message, "message": suggestion},
            )
        else:
            GENERATING_VIEW_IDS.discard(view_id)

    def report(self, view_id, message, diagnostics=None):
        sublime.set_timeout(lambda: self.show_failure(view_id, message, diagnostics), 0)

    def show_failure(self, view_id, message, diagnostics):
        set_final_status(view_id, message)
        if diagnostics:
            show_error_panel(view_id, diagnostics)


class GitApplyCodexCommitMessageCommand(sublime_plugin.TextCommand):
    def run(self, edit, expected_message, message):
        if commit_message(self.view) != expected_message:
            set_final_status(
                self.view.id(), "Codex: commit message changed; suggestion discarded."
            )
            return

        region = commit_message_region(self.view)
        message = message.rstrip()
        self.view.replace(edit, region, message + "\n\n")
        cursor = region.begin() + len(message)
        self.view.sel().clear()
        self.view.sel().add(sublime.Region(cursor))
        self.view.show(cursor)
        set_final_status(self.view.id(), "Codex: commit message inserted.")
