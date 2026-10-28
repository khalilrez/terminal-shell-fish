# Environment: PATH, editor, pagers

set -g fish_greeting

# ~/.local/bin goes first so the bat/fd shims win over distro binaries with the same name
fish_add_path -g ~/bin ~/.cargo/bin ~/go/bin ~/.local/bin

for editor in nvim vim nano
    if type -q $editor
        set -gx EDITOR $editor
        set -gx VISUAL $editor
        break
    end
end

set -gx LESS -R
if type -q bat
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
    set -gx MANROFFOPT -c
end
