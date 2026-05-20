---
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

Report any conflicts instead of using `--adopt` automatically.
