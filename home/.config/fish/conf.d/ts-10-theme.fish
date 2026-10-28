# Catppuccin Mocha for fish syntax highlighting, the completion pager and fzf.
# Set as globals so they override any universal colors left behind by `fish_config`.

set -g fish_color_normal cdd6f4
set -g fish_color_command 89b4fa
set -g fish_color_keyword f38ba8
set -g fish_color_param f2cdcd
set -g fish_color_option a6e3a1
set -g fish_color_quote a6e3a1
set -g fish_color_redirection f5c2e7
set -g fish_color_end fab387
set -g fish_color_operator f5c2e7
set -g fish_color_escape eba0ac
set -g fish_color_comment 7f849c
set -g fish_color_error f38ba8
set -g fish_color_autosuggestion 6c7086
set -g fish_color_valid_path --underline
set -g fish_color_selection --background=313244
set -g fish_color_search_match --background=313244
set -g fish_color_history_current --bold
set -g fish_color_cancel f38ba8
set -g fish_color_cwd f9e2af
set -g fish_color_cwd_root f38ba8
set -g fish_color_user 94e2d5
set -g fish_color_host 89b4fa
set -g fish_color_host_remote a6e3a1
set -g fish_color_status f38ba8

set -g fish_pager_color_progress 6c7086
set -g fish_pager_color_prefix f5c2e7 --bold
set -g fish_pager_color_completion cdd6f4
set -g fish_pager_color_description 6c7086
set -g fish_pager_color_selected_background --background=313244

set -gx FZF_DEFAULT_OPTS "\
--height=50% --layout=reverse --border=rounded --info=inline-right \
--prompt='❯ ' --pointer='▌' --marker='┃' --separator='─' \
--color=bg+:#313244,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a,border:#6c7086,label:#cdd6f4"
