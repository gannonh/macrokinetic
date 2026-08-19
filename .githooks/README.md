# Git Hooks

This directory contains git hooks that are tracked in version control.

## Setup

After cloning the repo, install the repository hooks:

```bash
./scripts/install-hooks.sh
```

## Hooks

| Hook            | Purpose                                                                    |
| --------------- | -------------------------------------------------------------------------- |
| `pre-commit`    | Staged whitespace, SwiftLint, and Python compile checks              |
| `pre-push`      | Git LFS object upload                                             |
| `post-checkout` | Git LFS - downloads large files after checkout                       |
| `post-commit`   | Git LFS                                                               |
| `post-merge`    | Git LFS - downloads large files after merge                           |

CI owns project integrity, lint, Python, and test validation. The pre-push hook only uploads Git LFS objects; do not bypass it when pushing LFS content.
