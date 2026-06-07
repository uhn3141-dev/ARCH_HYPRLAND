-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- Toolkit Backend Variables

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

-- XDG Specifications

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Qt Variables
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")

-- Theming Related Variables

-- hl.env("HYPRCURSOR_THEME", "cursors/Night_Diamond_Blue") -- put themes in ~/.local/share/icons/cursors/
-- hl.env("HYPRCURSOR_SIZE", "24")

-- Others
hl.env("XDG_MENU_PREFIX","arch-") -- To use default applications