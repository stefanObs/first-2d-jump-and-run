class_name MenuChrome
extends RefCounted

## Shared western menu look matching the start screen (save select).

const BACKDROP_PATH := "res://assets/ui/menu_backdrop_desert.png"
const TITLE_BOARD_PATH := "res://assets/ui/saloon_title_board.png"
const SLOT_BOARD_PATH := "res://assets/ui/saloon_slot_board.png"

const TITLE_CREAM := Color(0.96, 0.86, 0.48, 1.0)
const TITLE_CREAM_HOVER := Color(1.0, 0.92, 0.62, 1.0)
const INK := Color(0.28, 0.12, 0.04, 1.0)
const INK_SOFT := Color(0.42, 0.22, 0.08, 1.0)
const WOOD := Color(0.78, 0.48, 0.22, 0.96)
const WOOD_HOVER := Color(0.90, 0.62, 0.30, 1.0)
const WOOD_PANEL := Color(0.82, 0.52, 0.26, 0.94)
const BANDANA := Color(0.58, 0.18, 0.10, 1.0)
const VEIL := Color(0.45, 0.18, 0.06, 0.22)
const DIM := Color(0.22, 0.10, 0.04, 0.45)
const PANEL_CREAM := Color(1.0, 0.93, 0.78, 1.0)
const PANEL_HOVER := Color(1.0, 0.86, 0.5, 1.0)


static func add_desert_backdrop(parent: Control, with_veil: bool = true) -> void:
    var backdrop := TextureRect.new()
    backdrop.name = "Backdrop"
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.texture = load(BACKDROP_PATH) as Texture2D
    backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(backdrop)
    parent.move_child(backdrop, 0)
    if not with_veil:
        return
    var veil := ColorRect.new()
    veil.name = "Veil"
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    veil.color = VEIL
    veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(veil)
    parent.move_child(veil, 1)


static func wood_style(fill: Color = WOOD, radius: int = 12) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(fill.r, fill.g, fill.b, 1.0)
    style.set_corner_radius_all(radius)
    style.set_border_width_all(4)
    style.border_color = BANDANA
    style.content_margin_left = 14
    style.content_margin_right = 14
    style.content_margin_top = 12
    style.content_margin_bottom = 12
    return style


static func panel_style() -> StyleBoxFlat:
    ## Tall/wide menu panels — solid painted wood (no stretched slot-board art).
    var style := wood_style(WOOD_PANEL, 16)
    style.content_margin_left = 22
    style.content_margin_right = 22
    style.content_margin_top = 18
    style.content_margin_bottom = 18
    style.shadow_color = Color(0.18, 0.06, 0.02, 0.45)
    style.shadow_size = 10
    style.shadow_offset = Vector2(0, 5)
    return style


static func row_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(1.0, 0.90, 0.68, 1.0)
    style.set_corner_radius_all(10)
    style.set_border_width_all(2)
    style.border_color = Color(0.55, 0.28, 0.10, 1.0)
    style.content_margin_left = 10
    style.content_margin_right = 10
    style.content_margin_top = 6
    style.content_margin_bottom = 6
    return style


static func slot_board_style() -> StyleBoxTexture:
    ## Short boards only — nails/rim look wrong when stretched into tall panels.
    var style := StyleBoxTexture.new()
    style.texture = load(SLOT_BOARD_PATH) as Texture2D
    style.texture_margin_left = 36
    style.texture_margin_top = 36
    style.texture_margin_right = 36
    style.texture_margin_bottom = 36
    style.content_margin_left = 28
    style.content_margin_top = 24
    style.content_margin_right = 28
    style.content_margin_bottom = 24
    return style


static func apply_cream_outline(label: Label, fill: Color = TITLE_CREAM, outline_size: int = 3) -> void:
    label.add_theme_color_override(&"font_color", fill)
    label.add_theme_color_override(&"font_outline_color", Color(0.22, 0.08, 0.03, 0.85))
    if outline_size > 0:
        label.add_theme_constant_override(&"outline_size", outline_size)


static func apply_ink_label(label: Label, soft: bool = false) -> void:
    label.add_theme_color_override(&"font_color", INK_SOFT if soft else INK)
    label.add_theme_color_override(&"font_outline_color", Color(1.0, 0.92, 0.72, 0.7))
    label.add_theme_constant_override(&"outline_size", 2)


static func style_wood_button(button: Button, font_size: int = 0) -> void:
    if font_size > 0:
        button.add_theme_font_size_override(&"font_size", font_size)
    button.add_theme_color_override(&"font_color", TITLE_CREAM)
    button.add_theme_color_override(&"font_hover_color", TITLE_CREAM_HOVER)
    button.add_theme_color_override(&"font_pressed_color", TITLE_CREAM)
    button.add_theme_color_override(&"font_focus_color", TITLE_CREAM)
    button.add_theme_color_override(&"font_disabled_color", Color(0.75, 0.62, 0.42, 0.75))
    button.add_theme_color_override(&"font_outline_color", Color(0.22, 0.08, 0.03, 0.85))
    button.add_theme_constant_override(&"outline_size", 3)
    var normal := wood_style(WOOD, 10)
    var hover := wood_style(WOOD_HOVER, 10)
    var disabled := wood_style(Color(0.62, 0.42, 0.24, 0.9), 10)
    disabled.border_color = Color(0.45, 0.28, 0.14, 1.0)
    button.add_theme_stylebox_override(&"normal", normal)
    button.add_theme_stylebox_override(&"hover", hover)
    button.add_theme_stylebox_override(&"pressed", hover)
    button.add_theme_stylebox_override(&"focus", hover)
    button.add_theme_stylebox_override(&"disabled", disabled)


static func style_check_button(button: CheckButton) -> void:
    button.add_theme_color_override(&"font_color", INK)
    button.add_theme_color_override(&"font_pressed_color", INK)
    button.add_theme_color_override(&"font_hover_color", Color(0.45, 0.2, 0.06, 1.0))
    button.add_theme_color_override(&"font_outline_color", Color(1.0, 0.92, 0.72, 0.55))
    button.add_theme_constant_override(&"outline_size", 2)
    button.add_theme_font_size_override(&"font_size", 22)
