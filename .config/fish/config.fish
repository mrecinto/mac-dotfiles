# ============================================================
# ENVIRONMENT
# ============================================================

set -gx EDITOR nvim
set -gx VISUAL nvim


if status is-interactive

    set -g fish_greeting

    # ========================================================
    # STARSHIP
    # ========================================================

    starship init fish | source


    # ========================================================
    # YAZI
    #
    # Lets Yazi change the current Fish directory when exiting.
    # ========================================================

    function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"

        if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            builtin cd -- "$cwd"
        end

        rm -f -- "$tmp"
    end


    # ========================================================
    # GENERAL
    # ========================================================

    function d
        cd ~/Downloads
        y
    end

    function personal
        cd ~/Documents/personal
        y
    end

    function cfg
        cd ~/dotfiles
        y
    end

    function fi-cfg
        cd ~/.config/fish
        y
    end


    # ========================================================
    # UCSD NOTES
    # ========================================================

    function notes
        cd ~/Documents/ucsd-notes
        y
    end

    function fourth
        cd ~/Documents/ucsd-notes/fourth-year
        y
    end

    function book
        cd ~/Documents/ucsd-notes/textbooks
        y
    end


    # ========================================================
    # CURRENT QUARTER
    #
    # n
    #   -> opens Fall 2026
    #
    # n math180a
    #   -> opens/creates:
    #      fa2026/math180a/notes
    # ========================================================

    function n
        set base ~/Documents/ucsd-notes/fourth-year/fa2026

        if test (count $argv) -eq 0
            cd "$base"
            y
            return
        end

        set notes_dir "$base/$argv[1]/notes"

        mkdir -p "$notes_dir"

        cd "$notes_dir"
        y
    end


    # ========================================================
    # CURRENT CLASSES
    # ========================================================

    function 100a
        cd ~/Documents/ucsd-notes/fourth-year/fa2026/math100a
        y
    end

    function 180a
        cd ~/Documents/ucsd-notes/fourth-year/fa2026/math180a
        y
    end

    function cogs1
        cd ~/Documents/ucsd-notes/fourth-year/fa2026/cogs1
        y
    end

    function 14a
        cd ~/Documents/ucsd-notes/fourth-year/fa2026/cogs14a
        y
    end


    # ========================================================
    # PRACTICE
    #
    # p
    #   -> ~/Documents/personal/practice
    #
    # p cpp
    #   -> ~/Documents/personal/practice/cpp
    # ========================================================

    function p
        set base ~/Documents/personal/practice

        if test (count $argv) -eq 0
            mkdir -p "$base"
            cd "$base"
        else
            set target "$base/$argv[1]"
            mkdir -p "$target"
            cd "$target"
        end

        y
    end


    # ========================================================
    # TMUX
    #
    # Example:
    #   t school
    #
    # Creates the session if necessary or attaches if it exists.
    # ========================================================

    function t
        if test (count $argv) -eq 0
            echo "usage: t <session-name>"
            return 1
        end

        tmux new-session -A -s $argv[1]
    end

end
