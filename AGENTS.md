# Agent Instructions

## AGENTS.md File Resolution

AGENTS.md files can be placed at the project root or in subdirectories. When multiple files exist, traverse up from the edited file's directory to the root, collecting all AGENTS.md files. Files closer to the edited file take precedence over files further away.

## Code Formatting and Linting

After editing any code files, automatically format and lint them using the appropriate tools for that language.

### Python
- Format: `black <file_path>`
- Lint: `ruff check <file_path>`

### Bash/Shell
- Format: `shfmt -w <file_path>`
- Lint: `shellcheck <file_path>`

## File Formatting Standards

When editing any file:
- Remove trailing whitespace from all lines
- Keep a single newline at the end of file (EOF)

## Git Commits

All commits must use semantic commit messages:

```
<type>(<scope>): <subject>

<body>
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

**Examples:**
- `feat(sway): add screen recording functionality`
- `fix(python): resolve import error in file_utils`
- `refactor(sway): abstract common patterns to dotfiles module`
- `docs: update AGENTS.md with commit guidelines`

Scope is optional but recommended for clarity.
