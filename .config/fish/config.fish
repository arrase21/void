if status is-interactive
    set fish_greeting
    
    # Paths
    fish_add_path $HOME/.cargo/bin
    fish_add_path $HOME/.local/bin
    fish_add_path $HOME/.spicetify
    fish_add_path $HOME/go/bin

    # Aliases básicos
    alias ls 'eza --icons'
    alias la 'eza --icons -A'
    alias ll 'eza --icons -l'
    alias lla 'eza --icons -lA'
    alias lt 'eza --icons --tree --level=2'
    alias clear "printf '\033[2J\033[3J\033[1;1H'"

    # Aliases de aplicaciones
    alias q 'qs -c ii'
    alias v 'nvim'
    alias t 'tmux'
    alias g 'git'
    alias y 'yazi'

    # Aliases de Python
    alias pv 'python -m venv .env'
    alias pva 'source .env/bin/activate.fish'
    alias pga 'source pgadmin4/bin/activate.fish'
    alias mango="dbus-run-session ~/.local/bin/start-wayland"
end

# FZF
if test -f /usr/share/fzf/key-bindings.fish
    source /usr/share/fzf/key-bindings.fish
end

if test -f /usr/share/fzf/completion.fish
    source /usr/share/fzf/completion.fish
end

function __fzf_files
    set -l dir (fd -H -t d . $HOME | fzf --preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null || tree -C {} | head -200')
    test -n "$dir"; and builtin cd "$dir"; and commandline -f repaint
end
bind \cf __fzf_files
set -Ux FZF_DEFAULT_OPTS '
    --height 70%
    --layout=reverse
    --border=rounded
    --prompt="❯ "
    --pointer="▶"
    --marker="✓"
    --color=fg:#c0caf5,bg:-1,hl:#B388FF 
    --color=fg+:#ffffff,bg+:-1,hl+:#B388FF 
    --color=info:#7aa2f7,prompt:#2CF9ED,pointer:#bb9af7 
    --color=marker:#9ece6a,spinner:#9ece6a,header:#565f89
    --popup=center
    --popup=70%
'
# #
# # FZF
# source /usr/share/fzf/shell/key-bindings.fish
# source /usr/share/fish/completions/fzf.fish
#
# set -Ux FZF_DEFAULT_OPTS "
#     --height 70%
#     --layout=reverse
#     --border=rounded
#     --prompt='❯ '
#     --pointer='▶'
#     --marker='✓'
#     --style=full
#     --padding=1,2
#     --border-label=' Demo ' 
#     --input-label=' Input '
#     --color=fg:#c0caf5,bg:-1,hl:#B388FF 
#     --color=fg+:#ffffff,bg+:-1,hl+:#B388FF 
#     --color=info:#7aa2f7,prompt:#2CF9ED,pointer:#bb9af7 
#     --color=marker:#9ece6a,spinner:#9ece6a,header:#565f89
#     --color='border:#aaaaaa,label:#cccccc' 
#     --color='preview-border:#9999cc,preview-label:#ccccff' 
#     --color='list-border:#669966,list-label:#99cc99' 
#     --color='input-border:#996666,input-label:#ffcccc'
#     --bind='result:transform-list-label:
#         if [ -z \"\$FZF_QUERY\" ]; then
#           echo \" \$FZF_MATCH_COUNT items \"
#         else
#           echo \" \$FZF_MATCH_COUNT matches for [\$FZF_QUERY] \"
#         fi
#         ' 
#     --bind='focus:transform-preview-label:[ -n {} ] && printf \" Previewing [%s] \" {}'
# "
#
# function __fzf_files
#     set -l dir (fd -H -t d . $HOME | fzf --preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null || tree -C {} | head -200')
#     test -n "$dir"; and builtin cd "$dir"; and commandline -f repaint
# end
#
# bind \cf __fzf_files
