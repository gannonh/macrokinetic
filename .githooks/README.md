# Git Hooks

This directory contains git hooks that are tracked in version control.

## Setup

After cloning the repo, configure git to use this hooks directory:

```bash
git config core.hooksPath .githooks
```

## Hooks

| Hook            | Purpose                                                                    |
| --------------- | -------------------------------------------------------------------------- |
| `pre-commit`    | Branch protection warning + swift-format + SwiftLint + coverage validation |
| `pre-push`      | Git LFS - uploads large files before push                                  |
| `post-checkout` | Git LFS - downloads large files after checkout                             |
| `post-commit`   | Git LFS                                                                    |
| `post-merge`    | Git LFS - downloads large files after merge                                |

## Branch Protection

The `pre-commit` hook warns before committing directly to `main` or `master`. You'll be prompted to confirm before the commit proceeds.
