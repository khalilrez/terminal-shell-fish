# Aliases and abbreviations.
# Abbreviations expand when you press space, so history records the full command.

status is-interactive; or return

# Listing
if type -q eza
    alias ls 'eza --icons=auto --group-directories-first'
    alias ll 'eza -l --icons=auto --group-directories-first --git --header --time-style=relative'
    alias la 'eza -la --icons=auto --group-directories-first --git --header --time-style=relative'
    alias lt 'eza --tree --level=2 --icons=auto --group-directories-first --git-ignore'
else
    alias ll 'ls -lh'
    alias la 'ls -lah'
end

type -q bat; and alias cat 'bat --paging=never'
type -q nvim; and alias vim nvim
type -q btop; and alias top btop
alias cls clear

# Navigation: `..` → cd .., `...` → cd ../.., and so on
function _ts_multicd
    echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
end
abbr -a dotdot --regex '^\.\.+$' --function _ts_multicd

# `!!` expands to the previous command, e.g. `sudo !!`
function _ts_last_command
    echo $history[1]
end
abbr -a !! --position anywhere --function _ts_last_command

# Git
abbr -a g git
abbr -a lg lazygit
abbr -a gs git status -sb
abbr -a gst git status
abbr -a ga git add
abbr -a gaa git add --all
abbr -a gap git add --patch
abbr -a gc git commit
abbr -a gcm git commit -m
abbr -a gca git commit --amend
abbr -a gco git checkout
abbr -a gsw git switch
abbr -a gswc git switch -c
abbr -a gb git branch
abbr -a gd git diff
abbr -a gds git diff --staged
abbr -a gl git log --oneline --graph --decorate -20
abbr -a glog git log --oneline --graph --decorate --all
abbr -a gp git push
abbr -a gpf git push --force-with-lease
abbr -a gpl git pull --rebase
abbr -a gf git fetch --all --prune
abbr -a grb git rebase
abbr -a gsh git stash
abbr -a gshp git stash pop

# Docker
abbr -a d docker
abbr -a dc docker compose
abbr -a dps docker ps
abbr -a dimg docker images

# Misc
abbr -a v $EDITOR
abbr -a reload 'exec fish'
