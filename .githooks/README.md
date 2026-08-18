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
| `pre-push`      | Project integrity, Python tests, unit tests, and Git LFS             |
| `post-checkout` | Git LFS - downloads large files after checkout                       |
| `post-commit`   | Git LFS                                                               |
| `post-merge`    | Git LFS - downloads large files after merge                           |

The local hooks are convenience checks and can be bypassed intentionally with `git push --no-verify`. GitHub CI remains the independent merge gate.
