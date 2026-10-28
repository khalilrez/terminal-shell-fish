# Tool integration. fzf.fish loads before this file (conf.d runs in alphabetical order).

if type -q fd
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
    set -g fzf_fd_opts --hidden --follow --exclude .git
end

if type -q eza
    set -g fzf_preview_dir_cmd eza --all --color=always --icons=always --group-directories-first
end

# fzf.fish bindings:
#   Ctrl+T          find files/dirs        Ctrl+Alt+L  git log
#   Ctrl+Alt+S      git status             Ctrl+Alt+P  processes
#   Ctrl+V          shell variables        Ctrl+R      history (only if atuin is missing)
if status is-interactive; and functions -q fzf_configure_bindings
    if type -q atuin
        fzf_configure_bindings --directory=\ct --history=
    else
        fzf_configure_bindings --directory=\ct
    end
end

# The `done` plugin: notify when a command running longer than 10s finishes in an unfocused window
set -g __done_min_cmd_duration 10000
