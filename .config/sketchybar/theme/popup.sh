# Popup colors follow macOS appearance independently of the bar palette.
POPUP_BACKGROUND="0xee${BACKGROUND#0xd9}"
POPUP_FOREGROUND="$ON_BACKGROUND"
POPUP_BORDER="$SURFACE_VARIANT"
POPUP_ACCENT="$PRIMARY"
# Pointer/workspace updates reuse the appearance watcher cache instead of
# launching defaults on every event. The watcher itself still checks live state.
POPUP_MODE=""
if [ "${SKETCHYBAR_POPUP_CACHED:-0}" = 1 ] && [ -r "$THEME_CACHE/popup-mode" ]; then
  IFS= read -r POPUP_MODE < "$THEME_CACHE/popup-mode" || :
fi
if [ -z "$POPUP_MODE" ]; then
  POPUP_MODE=$(defaults read -g AppleInterfaceStyle 2>/dev/null || printf Light)
fi
if [ "$POPUP_MODE" != Dark ]; then
  POPUP_BACKGROUND=0xeef5f5f5
  POPUP_FOREGROUND=0xff202020
  POPUP_BORDER=0xffc6c6c6
  POPUP_ACCENT=0xff286322
fi
