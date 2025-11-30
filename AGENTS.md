# Agent Instructions

## Python Code Formatting

**MANDATORY**: After editing any Python files, you MUST automatically format them using `black`:

```bash
black <file_path>
```

This ensures consistent code formatting across all Python files in the project.

**IMPORTANT**: Do not skip this step. Formatting must be executed immediately after every Python file edit.

## Bash Script Formatting

**MANDATORY**: After editing any Bash/shell script files, you MUST automatically format them using `shfmt`:

```bash
shfmt -w <file_path>
```

This ensures consistent code formatting across all shell scripts in the project.

**IMPORTANT**: Do not skip this step. Formatting must be executed immediately after every shell script edit.

## Git Commits

**MANDATORY**: All commits MUST use semantic commit messages following the conventional commits format:

```
<type>(<scope>): <subject>

<body>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks, dependency updates

**Examples:**
- `feat(sway): add screen recording functionality`
- `fix(python): resolve import error in file_utils`
- `refactor(sway): abstract common patterns to dotfiles module`
- `docs: update AGENTS.md with commit guidelines`

**IMPORTANT**: Use semantic commits for all changes. The scope is optional but recommended for clarity.
