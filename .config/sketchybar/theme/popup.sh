# Popup colors follow macOS appearance independently of the bar palette.
POPUP_BACKGROUND="0xee${BACKGROUND#0xd9}"
POPUP_FOREGROUND="$ON_BACKGROUND"
POPUP_BORDER="$SURFACE_VARIANT"
POPUP_ACCENT="$PRIMARY"
POPUP_MODE=$(defaults read -g AppleInterfaceStyle 2>/dev/null || printf Light)
if [ "$POPUP_MODE" != Dark ]; then
  POPUP_BACKGROUND=0xeef5f5f5
  POPUP_FOREGROUND=0xff202020
  POPUP_BORDER=0xffc6c6c6
  POPUP_ACCENT=0xff286322
fi
