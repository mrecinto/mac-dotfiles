# No generated Fish config: keep this live alongside your functions and prompt.
# Append Nix profiles so adopting Nix does not replace working Brew/npm commands.
# Fish universal paths remain local state; this does not write universal variables.
for profile in /nix/var/nix/profiles/default /run/current-system/sw /etc/profiles/per-user/$USER $HOME/.nix-profile
    if test -d "$profile/bin"
        fish_add_path --path --append "$profile/bin"
    end
end
# Keep audited Homebrew commands (not Apple's older Git) ahead of system paths.
# The main config still prepends .local/bin, and npm's prefix remains preferred.
for brew_prefix in /opt/homebrew /usr/local
    if test -x "$brew_prefix/bin/brew"
        fish_add_path --path --move "$brew_prefix/sbin"
        fish_add_path --path --move "$brew_prefix/bin"
        break
    end
end
# Match the existing npm user prefix on a new Mac without importing fish_variables.
if test -d "$HOME/.npm-global/bin"
    fish_add_path --path "$HOME/.npm-global/bin"
end
