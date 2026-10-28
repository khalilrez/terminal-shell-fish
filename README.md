# terminal-shell

fish + starship + modern CLI tools, themed Catppuccin Mocha end to end. One script, any machine.

## Install

```sh
# from a clone
git clone <this-repo> ~/.local/share/terminal-shell && ~/.local/share/terminal-shell/install.sh

# or one line
curl -fsSL <raw-url>/install.sh | TS_REPO=<this-repo-git-url> bash
```

Supports macOS (Homebrew) and Linux (apt, dnf, pacman, zypper, apk) on x86_64 and arm64.
Tools your package manager lacks, or every tool when there's no sudo (`--no-sudo`), come from
GitHub releases and go into `~/.local/bin`. Re-running is safe: configs are symlinked, and
anything replaced is backed up under `~/.local/state/terminal-shell/`.

Flags: `--no-sudo`, `--no-packages`, `--no-fonts`, `--no-chsh`, `--no-git`.

Afterwards, set your terminal font to **JetBrainsMono Nerd Font**.

## What you get

| Tool | Replaces | Why |
|---|---|---|
| fish | bash/zsh | autosuggestions, syntax highlighting, completions with no plugins |
| starship | prompt | fast, shows git/language/k8s/aws context only when relevant |
| atuin | Ctrl+R | fuzzy full-history search, optional encrypted sync between machines |
| zoxide | `cd` | `cd proj` jumps to the most-used match; `cdi` picks with fzf |
| fzf + fzf.fish | — | fuzzy finders for files, git log/status, processes |
| eza | `ls` | icons, git status, tree view |
| bat | `cat`, `man` | syntax highlighting, git gutter |
| fd, ripgrep | `find`, `grep` | fast, respect .gitignore |
| delta | git pager | syntax-highlighted diffs with line numbers |
| lazygit | — | git TUI (`lg`) |
| direnv | — | per-project env vars from `.envrc` |
| tldr, btop, jq | `man`, `top` | example-first docs, system monitor, JSON |

Fish plugins (fisher): fzf.fish, autopair, done (notifies when long commands finish),
sponge (drops typos from history), abbreviation-tips (reminds you of abbreviations), nvm.fish.

## Cheat sheet

| Keys | Action |
|---|---|
| → or Ctrl+F | accept autosuggestion (Alt+→ for one word) |
| Ctrl+R | atuin history search (Tab edits, Enter runs) |
| Ctrl+T | find file/dir, inserts path |
| Ctrl+Alt+L / Ctrl+Alt+S | search git log / git status |
| Ctrl+Alt+P | search processes |
| Alt+E | edit command in `$EDITOR` |
| Alt+L | `ls` the current dir without losing your input |

Abbreviations expand on space: `g gs ga gaa gc gcm gco gsw gd gds gl gp gpf gpl lg d dc`,
`..`/`...`/`....` to go up, `!!` for the last command, `reload` to restart fish.
See `home/.config/fish/conf.d/ts-30-aliases.fish` for the full list.

## Layout

```
install.sh
fish_plugins              merged into ~/.config/fish/fish_plugins (your extra plugins are kept)
home/                     mirrored into $HOME as symlinks
  .config/fish/config.fish, conf.d/ts-*.fish, functions/
  .config/starship.toml, bat/, eza/, atuin/
```

Per-machine settings (SSH keys, work paths, secrets) go in `~/.config/fish/local.fish`,
which is never touched.

Note: starship.toml writes Nerd Font glyphs as `\uXXXX` escapes so they survive copy/paste and editors.
