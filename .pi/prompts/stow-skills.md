---
name: stow-skills
description: Stow pi skills from this dotfiles repo into ~/.pi/agent/skills
---
Run this command from the dotfiles repo to link pi skills into the global pi skills directory:

```bash
stow --dir=.pi/agent --target="$HOME/.pi/agent/skills" --ignore='reviewing-dbt-model' skills
```

Then verify that the expected skills are linked using the base folder:

```bash
ls -ld ~/.pi/agent/skills/grill-me ~/.pi/agent/skills/using-python
```

Expose every compatible Pi skill and prompt to Codex as well:

```bash
bin/link-pi-skills
```

Codex discovers user-wide workflows from `~/.agents/skills`. The linker creates
symlinks back to Pi's skill and prompt directories, converts prompts into
explicit-only Codex skills, skips files without Codex's required `name` and
`description` frontmatter, and reports conflicts without replacing them.

Report any conflicts instead of using `--adopt` automatically.
