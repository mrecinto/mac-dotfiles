{ ... }:
{
  # Existing Homebrew installation is reused. Install it explicitly on a clean Mac.
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
      extraEnv.HOMEBREW_NO_INSTALL_CLEANUP = "1";
    };
    taps = [ "homebrew-zathura/zathura" "nikitabobko/tap" "rbstp/tap" "felixkratz/formulae" ];
    brews = [
      "cmake"
      "fd"
      "felixkratz/formulae/sketchybar"
      "ffmpeg"
      "fish"
      "fzf"
      "git"
      "homebrew-zathura/zathura/zathura"
      "homebrew-zathura/zathura/zathura-pdf-poppler"
      "imagemagick"
      "jq"
      "meson"
      "neovim"
      "node"
      "pkgconf"
      "pngpaste"
      "poppler"
      "ripgrep"
      "sevenzip"
      "sphinx-doc"
      "starship"
      "tinymist"
      "tmux"
      "tree-sitter-cli"
      "typst"
      "yazi"
      "zoxide"
    ];
    casks = [
      "android-platform-tools"
      "ghostty"
      "karabiner-elements"
      "linearmouse"
      "nikitabobko/tap/aerospace"
      "rbstp/tap/heed"
    ];
    # Zen and Xournal++ already exist outside Brew. Do not adopt/overwrite them.
    # See README for restoring these on a clean Mac.
  };
}
