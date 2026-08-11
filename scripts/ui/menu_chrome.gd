class_name MenuChrome
extends RefCounted

## Shared western menu look matching the start screen (save select).

const BACKDROP_PATH := "res://assets/ui/menu_backdrop_desert.png"
const TITLE_BOARD_PATH := "res://assets/ui/saloon_title_board.png"
const SLOT_BOARD_PATH := "res://assets/ui/saloon_slot_board.png"

const TITLE_CREAM := Color(0.96, 0.86, 0.48, 1.0)
const TITLE_CREAM_HOVER := Color(1.0, 0.92, 0.62, 1.0)
const TITLE_CREAM_PRESSED := Color(0.90, 0.78, 0.38, 1.0)
const INK := Color(0.28, 0.12, 0.04, 1.0)
const INK_SOFT := Color(0.42, 0.22, 0.08, 1.0)
const WOOD := Color(0.78, 0.48, 0.22, 0.96)
const WOOD_HOVER := Color(0.90, 0.62, 0.30, 1.0)
const WOOD_PRESSED := Color(0.62, 0.34, 0.14, 1.0)
const WOOD_PANEL := Color(0.82, 0.52, 0.26, 0.94)
const BANDANA := Color(0.58, 0.18, 0.10, 1.0)
const VEIL := Color(0.45, 0.18, 0.06, 0.22)
const DIM := Color(0.22, 0.10, 0.04, 0.45)
const PANEL_CREAM := Color(1.0, 0.93, 0.78, 1.0)
const PANEL_HOVER := Color(1.0, 0.86, 0.5, 1.0)
const HOVER_SCALE := 1.07
const PRESS_SCALE := 0.92
const _META_BOUND := &"_menu_btn_feedback"
const _META_REST_SCALE := &"_menu_rest_scale"
const _META_TWEEN := &"_menu_fb_tween"
const _META_PRESSED := &"_menu_fb_pressed"
const _META_HOVERED := &"_menu_fb_hovered"
const _META_TARGET := &"_menu_feedback_target"


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


static func settings_panel_style() -> StyleBoxFlat:
    ## Compact wood chrome so Trail Options fits a 720p frame.
    var style := wood_style(WOOD_PANEL, 14)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 10
    style.content_margin_bottom = 10
    style.shadow_color = Color(0.18, 0.06, 0.02, 0.4)
    style.shadow_size = 8
    style.shadow_offset = Vector2(0, 4)
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
    button.add_theme_color_override(&"font_pressed_color", TITLE_CREAM_PRESSED)
    button.add_theme_color_override(&"font_focus_color", TITLE_CREAM)
    button.add_theme_color_override(&"font_disabled_color", Color(0.75, 0.62, 0.42, 0.75))
    button.add_theme_color_override(&"font_outline_color", Color(0.22, 0.08, 0.03, 0.85))
    button.add_theme_constant_override(&"outline_size", 3)
    var normal := wood_style(WOOD, 10)
    var hover := wood_style(WOOD_HOVER, 10)
    var disabled := wood_style(Color(0.62, 0.42, 0.24, 0.9), 10)
    disabled.border_color = Color(0.45, 0.28, 0.14, 1.0)
    apply_button_styleboxes(button, normal, hover)
    button.add_theme_stylebox_override(&"disabled", disabled)


static func style_check_button(button: CheckButton) -> void:
    button.add_theme_color_override(&"font_color", INK)
    button.add_theme_color_override(&"font_pressed_color", INK)
    button.add_theme_color_override(&"font_hover_color", Color(0.45, 0.2, 0.06, 1.0))
    button.add_theme_color_override(&"font_outline_color", Color(1.0, 0.92, 0.72, 0.55))
    button.add_theme_constant_override(&"outline_size", 2)
    button.add_theme_font_size_override(&"font_size", 22)
    bind_button_feedback(button)


static func apply_button_icon(button: Button, icon_path: String, max_width: int = 36) -> void:
    if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
        return
    button.icon = load(icon_path) as Texture2D
    button.expand_icon = true
    button.add_theme_constant_override(&"icon_max_width", max_width)
    button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
    if button.tooltip_text.is_empty() and not button.text.is_empty():
        button.tooltip_text = button.text


static func style_compact_icon_button(button: Button, font_size: int = 13) -> void:
    ## Smaller wood chrome for dense editor toolbars.
    style_wood_button(button, font_size)
    var normal := wood_style(WOOD, 8)
    normal.content_margin_left = 6
    normal.content_margin_right = 8
    normal.content_margin_top = 4
    normal.content_margin_bottom = 4
    var hover := wood_style(WOOD_HOVER, 8)
    hover.content_margin_left = 6
    hover.content_margin_right = 8
    hover.content_margin_top = 4
    hover.content_margin_bottom = 4
    var disabled := wood_style(Color(0.62, 0.42, 0.24, 0.9), 8)
    disabled.border_color = Color(0.45, 0.28, 0.14, 1.0)
    disabled.content_margin_left = 6
    disabled.content_margin_right = 8
    disabled.content_margin_top = 4
    disabled.content_margin_bottom = 4
    apply_button_styleboxes(button, normal, hover)
    button.add_theme_stylebox_override(&"disabled", disabled)


static func pressed_from(hover: StyleBox) -> StyleBox:
    if hover == null or not (hover is StyleBoxFlat):
        return hover
    var src := hover as StyleBoxFlat
    var pressed := src.duplicate() as StyleBoxFlat
    if _looks_like_wood(src.bg_color):
        pressed.bg_color = Color(WOOD_PRESSED.r, WOOD_PRESSED.g, WOOD_PRESSED.b, 1.0)
        pressed.border_color = Color(0.42, 0.12, 0.06, 1.0)
    else:
        pressed.bg_color = src.bg_color.darkened(0.14)
        pressed.border_color = src.border_color.darkened(0.12)
    pressed.content_margin_top = src.content_margin_top + 3.0
    pressed.content_margin_bottom = maxf(src.content_margin_bottom - 2.0, 2.0)
    pressed.shadow_size = 2
    pressed.shadow_offset = Vector2(0, 1)
    return pressed


static func apply_button_styleboxes(
    button: BaseButton, normal: StyleBox, hover: StyleBox, pressed: StyleBox = null
) -> void:
    if button == null:
        return
    if pressed == null:
        pressed = pressed_from(hover)
    button.add_theme_stylebox_override(&"normal", normal)
    button.add_theme_stylebox_override(&"hover", hover)
    button.add_theme_stylebox_override(&"pressed", pressed)
    button.add_theme_stylebox_override(&"hover_pressed", pressed)
    button.add_theme_stylebox_override(&"focus", hover)
    bind_button_feedback(button)


static func bind_menu_buttons(root: Node) -> void:
    if root == null:
        return
    for child in root.find_children("*", "BaseButton", true, false):
        var button := child as BaseButton
        if button == null or _skip_menu_feedback(button):
            continue
        bind_button_feedback(button)


static func bind_button_feedback(button: BaseButton) -> void:
    if button == null or bool(button.get_meta(_META_BOUND, false)):
        return
    button.set_meta(_META_BOUND, true)
    button.set_meta(_META_REST_SCALE, button.scale)
    button.set_meta(_META_PRESSED, false)
    button.set_meta(_META_HOVERED, false)
    button.set_meta(_META_TARGET, button.scale)
    _center_button_pivot(button)
    button.resized.connect(func() -> void: _center_button_pivot(button))
    button.mouse_entered.connect(func() -> void:
        if button.disabled:
            return
        button.set_meta(_META_HOVERED, true)
        refresh_button_feedback(button)
    )
    button.mouse_exited.connect(func() -> void:
        button.set_meta(_META_HOVERED, false)
        refresh_button_feedback(button)
    )
    button.button_down.connect(func() -> void:
        if button.disabled:
            return
        button.set_meta(_META_PRESSED, true)
        refresh_button_feedback(button)
        AudioManager.play_sfx(&"ui_click")
    )
    button.button_up.connect(func() -> void:
        button.set_meta(_META_PRESSED, false)
        refresh_button_feedback(button)
    )
    button.pressed.connect(func() -> void:
        if bool(button.get_meta(_META_PRESSED, false)) or button.disabled:
            return
        AudioManager.play_sfx(&"ui_click")
        _pulse_button_press(button)
    )


static func set_button_rest_scale(button: BaseButton, rest: Vector2) -> void:
    if button == null:
        return
    if not bool(button.get_meta(_META_BOUND, false)):
        bind_button_feedback(button)
    button.set_meta(_META_REST_SCALE, rest)
    refresh_button_feedback(button, true)


static func refresh_button_feedback(button: BaseButton, snap: bool = false) -> void:
    if button == null or not is_instance_valid(button):
        return
    if not bool(button.get_meta(_META_BOUND, false)):
        return
    _center_button_pivot(button)
    var rest: Vector2 = button.get_meta(_META_REST_SCALE, Vector2.ONE)
    var target := rest
    if not button.disabled:
        if bool(button.get_meta(_META_PRESSED, false)):
            target = rest * PRESS_SCALE
        elif bool(button.get_meta(_META_HOVERED, false)):
            target = rest * HOVER_SCALE
    button.set_meta(_META_TARGET, target)
    var duration := 0.08 if target.x >= rest.x else 0.06
    if snap:
        duration = 0.0
    _tween_button_scale(button, target, duration)


static func _pulse_button_press(button: BaseButton) -> void:
    var rest: Vector2 = button.get_meta(_META_REST_SCALE, Vector2.ONE)
    var squashed := rest * PRESS_SCALE
    button.set_meta(_META_TARGET, squashed)
    _tween_button_scale(button, squashed, 0.05)
    var tween := _feedback_tween(button)
    if tween != null:
        tween.tween_callback(func() -> void:
            if is_instance_valid(button):
                refresh_button_feedback(button)
        )


static func _feedback_tween(button: BaseButton) -> Tween:
    if button == null or not button.has_meta(_META_TWEEN):
        return null
    var prev: Variant = button.get_meta(_META_TWEEN)
    return prev as Tween if prev is Tween and is_instance_valid(prev) else null


static func _tween_button_scale(button: BaseButton, target: Vector2, duration: float) -> void:
    var prev := _feedback_tween(button)
    if prev != null:
        prev.kill()
    if button.scale.is_equal_approx(target):
        if button.has_meta(_META_TWEEN):
            button.remove_meta(_META_TWEEN)
        return
    if not button.is_inside_tree() or duration <= 0.0:
        button.scale = target
        if button.has_meta(_META_TWEEN):
            button.remove_meta(_META_TWEEN)
        return
    var tween := button.create_tween()
    tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
    tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", target, duration)
    button.set_meta(_META_TWEEN, tween)


static func _center_button_pivot(button: Control) -> void:
    if button == null:
        return
    var sz := button.size
    if sz.x < 1.0 or sz.y < 1.0:
        sz = button.custom_minimum_size
    if sz.x >= 1.0 and sz.y >= 1.0:
        button.pivot_offset = sz * 0.5


static func _looks_like_wood(color: Color) -> bool:
    return color.r > 0.55 and color.g > 0.25 and color.g < 0.75 and color.b < 0.45


static func _skip_menu_feedback(button: BaseButton) -> bool:
    var parent := button.get_parent()
    if parent != null and parent.name == "StampGrid":
        return true
    var node: Node = button
    while node != null:
        if node is FileDialog or node is PopupMenu:
            return true
        node = node.get_parent()
    return false
