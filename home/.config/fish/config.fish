# ~/.config/fish/config.fish — managed by terminal-shell (symlinked, edits go to the repo)
#
# Most settings live in conf.d/ts-*.fish, which fish loads before this file.
# Put machine-specific settings (SSH keys, work paths, secrets) in
# ~/.config/fish/local.fish. That file is not managed and never overwritten.

if status is-interactive
    # Prompt
    type -q starship; and starship init fish | source

    # Smarter cd: `cd foo` jumps to the best match, `cdi` picks one with fzf
    type -q zoxide; and zoxide init fish --cmd cd | source

    # Searchable, syncable shell history on Ctrl+R (Up arrow keeps fish's own history)
    type -q atuin; and atuin init fish --disable-up-arrow | source

    # Per-project env vars: put `export FOO=bar` in a .envrc, then `direnv allow`
    type -q direnv; and direnv hook fish | source
end

test -f ~/.config/fish/local.fish; and source ~/.config/fish/local.fish
