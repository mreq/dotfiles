# Agent Instructions

## Learning from Corrections

When the user corrects you, rejects an approach, or states a durable
preference, treat it as a candidate for persistent guidance.

Before continuing, check whether the current repository has a relevant
repo-local skill, such as `.skills/*/SKILL.md`. Prefer that local skill when the
correction is specific to the repository or its conventions. Ask the user
whether to update the specific skill before editing it.

If no repo-local skill fits, check whether an existing global Codex skill under
the Codex home is relevant. Use `$CODEX_HOME/skills` when `CODEX_HOME` is set;
otherwise use `~/.codex/skills`. If so, suggest the specific `SKILL.md` update
and ask the user whether to apply it before editing it.

If no existing skill fits, suggest whether the guidance belongs in the current
repo's `AGENTS.md`, global `~/.codex/AGENTS.md`, or a new skill.

## Sensitive Local Data

Never inspect, print, summarize, search inside, or otherwise read local secret
or credential files unless the user explicitly asks for that exact file or a
specific redacted snippet.

Treat these as sensitive by default:
- Kubernetes configs and credentials such as `~/.kube`
- SSH keys and config such as `~/.ssh`
- AWS credentials and auth caches such as `~/.aws`
- Password stores, keyrings, browser profiles, mail profiles, tokens, cookies,
  certificates, and private keys

It is fine to discuss directory names, permissions, migration commands, and
high-level security patterns without reading the contents.
