class_name SettingsPanel
extends PanelContainer

signal closed

const SLIDER_TRACK := Color(0.72, 0.48, 0.22, 1.0)
const SLIDER_FILL := Color(0.95, 0.62, 0.18, 1.0)

var _music: HSlider
var _sfx: HSlider
var _vibration: CheckButton
var _fullscreen: CheckButton
var _language: OptionButton
var _character: OptionButton
var _trail_mode: OptionButton
var _index: int = 0
var _controls: Array[Control] = []


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    _music = get_node_or_null("Margin/VBox/MusicSlider") as HSlider
    _sfx = get_node_or_null("Margin/VBox/SfxSlider") as HSlider
    _vibration = get_node_or_null("Margin/VBox/VibrationToggle") as CheckButton
    _fullscreen = get_node_or_null("Margin/VBox/FullscreenToggle") as CheckButton
    _language = get_node_or_null("Margin/VBox/LanguageDropdown") as OptionButton
    _character = get_node_or_null("Margin/VBox/CharacterDropdown") as OptionButton
    _trail_mode = get_node_or_null("Margin/VBox/TrailModeDropdown") as OptionButton
    var back := get_node_or_null("Margin/VBox/BackButton") as Button
    # Fallback for older scene layouts without the Margin wrapper.
    if _music == null:
        _music = get_node_or_null("VBox/MusicSlider") as HSlider
    if _sfx == null:
        _sfx = get_node_or_null("VBox/SfxSlider") as HSlider
    if _vibration == null:
        _vibration = get_node_or_null("VBox/VibrationToggle") as CheckButton
    if _fullscreen == null:
        _fullscreen = get_node_or_null("VBox/FullscreenToggle") as CheckButton
    if _language == null:
        _language = get_node_or_null("VBox/LanguageDropdown") as OptionButton
    if _character == null:
        _character = get_node_or_null("VBox/CharacterDropdown") as OptionButton
    if _trail_mode == null:
        _trail_mode = get_node_or_null("VBox/TrailModeDropdown") as OptionButton
    if back == null:
        back = get_node_or_null("VBox/BackButton") as Button
    _controls = [_music, _sfx, _vibration, _fullscreen, _language, _character, _trail_mode, back]
    _controls = _controls.filter(func(c: Control) -> bool: return c != null)
    _style_readable()
    _load_values()
    if _music:
        _music.value_changed.connect(func(v: float) -> void: GameManager.set_setting("music_volume", v))
    if _sfx:
        _sfx.value_changed.connect(func(v: float) -> void: GameManager.set_setting("sfx_volume", v))
    if _vibration:
        _vibration.toggled.connect(func(v: bool) -> void: GameManager.set_setting("vibration", v))
    if _fullscreen:
        _fullscreen.toggled.connect(func(v: bool) -> void: GameManager.set_setting("fullscreen", v))
    if _language:
        _language.item_selected.connect(_select_language)
    if _character:
        _character.item_selected.connect(_select_character)
    if _trail_mode:
        _trail_mode.item_selected.connect(_select_trail_mode)
    if back:
        back.pressed.connect(func() -> void: closed.emit())
    GameManager.settings_changed.connect(_load_values)


func _style_readable() -> void:
    ## Solid wood panel with bandana rim — matches start-screen chrome.
    add_theme_stylebox_override(&"panel", MenuChrome.panel_style())
    for path in [
        "Margin/VBox/Title",
        "Margin/VBox/MusicLabel",
        "Margin/VBox/SfxLabel",
        "Margin/VBox/LanguageLabel",
        "Margin/VBox/CharacterLabel",
        "Margin/VBox/TrailModeLabel",
        "VBox/Title",
        "VBox/MusicLabel",
        "VBox/SfxLabel",
        "VBox/LanguageLabel",
        "VBox/CharacterLabel",
        "VBox/TrailModeLabel",
    ]:
        var label := get_node_or_null(path) as Label
        if label == null:
            continue
        var is_title: bool = path.ends_with("Title")
        MenuChrome.apply_ink_label(label, not is_title)
        label.add_theme_font_size_override(
            &"font_size",
            32 if is_title else maxi(label.get_theme_font_size("font_size"), 22)
        )
    for control in [_vibration, _fullscreen]:
        if control == null:
            continue
        MenuChrome.style_check_button(control)
    var back: Button = null
    if not _controls.is_empty() and _controls[_controls.size() - 1] is Button:
        back = _controls[_controls.size() - 1] as Button
    if back != null:
        MenuChrome.style_wood_button(back, 24)
    _style_slider(_music)
    _style_slider(_sfx)
    _style_language_dropdown()
    _style_option_dropdown(_character)
    _style_option_dropdown(_trail_mode)


func _style_language_dropdown() -> void:
    _style_option_dropdown(_language)


func _style_option_dropdown(dropdown: OptionButton) -> void:
    if dropdown == null:
        return
    var ink := MenuChrome.INK
    var ink_hover := Color(0.45, 0.2, 0.06, 1.0)
    var ink_disabled := Color(0.45, 0.35, 0.28, 1.0)
    var panel_cream := MenuChrome.PANEL_CREAM
    var panel_hover := MenuChrome.PANEL_HOVER
    var border := Color(0.45, 0.24, 0.08, 1.0)
    dropdown.add_theme_color_override(&"font_color", MenuChrome.TITLE_CREAM)
    dropdown.add_theme_color_override(&"font_hover_color", MenuChrome.TITLE_CREAM_HOVER)
    dropdown.add_theme_color_override(&"font_pressed_color", MenuChrome.TITLE_CREAM)
    dropdown.add_theme_color_override(&"font_focus_color", MenuChrome.TITLE_CREAM)
    dropdown.add_theme_color_override(&"font_disabled_color", ink_disabled)
    dropdown.add_theme_color_override(&"font_outline_color", Color(0.22, 0.08, 0.03, 0.85))
    dropdown.add_theme_constant_override(&"outline_size", 3)
    dropdown.add_theme_font_size_override(&"font_size", 22)
    var normal := MenuChrome.wood_style(MenuChrome.WOOD, 10)
    var hover := MenuChrome.wood_style(MenuChrome.WOOD_HOVER, 10)
    dropdown.add_theme_stylebox_override(&"normal", normal)
    dropdown.add_theme_stylebox_override(&"hover", hover)
    dropdown.add_theme_stylebox_override(&"pressed", hover)
    dropdown.add_theme_stylebox_override(&"focus", hover)
    var popup := dropdown.get_popup()
    popup.add_theme_font_size_override(&"font_size", 22)
    popup.add_theme_color_override(&"font_color", ink)
    popup.add_theme_color_override(&"font_hover_color", ink_hover)
    popup.add_theme_color_override(&"font_disabled_color", ink_disabled)
    var popup_panel := StyleBoxFlat.new()
    popup_panel.bg_color = panel_cream
    popup_panel.set_border_width_all(3)
    popup_panel.border_color = border
    popup_panel.set_corner_radius_all(10)
    popup_panel.content_margin_left = 8
    popup_panel.content_margin_top = 6
    popup_panel.content_margin_right = 8
    popup_panel.content_margin_bottom = 6
    popup.add_theme_stylebox_override(&"panel", popup_panel)
    var item_hover := StyleBoxFlat.new()
    item_hover.bg_color = panel_hover
    item_hover.set_corner_radius_all(6)
    popup.add_theme_stylebox_override(&"hover", item_hover)


func _style_slider(slider: HSlider) -> void:
    if slider == null:
        return
    slider.custom_minimum_size.y = 36
    var track := StyleBoxFlat.new()
    track.bg_color = SLIDER_TRACK
    track.set_corner_radius_all(8)
    track.content_margin_top = 12
    track.content_margin_bottom = 12
    var fill := StyleBoxFlat.new()
    fill.bg_color = SLIDER_FILL
    fill.set_corner_radius_all(8)
    slider.add_theme_stylebox_override(&"slider", track)
    slider.add_theme_stylebox_override(&"grabber_area", fill)
    slider.add_theme_stylebox_override(&"grabber_area_highlight", fill)
    var knob := _make_knob_texture()
    slider.add_theme_icon_override(&"grabber", knob)
    slider.add_theme_icon_override(&"grabber_highlight", knob)


func _make_knob_texture() -> ImageTexture:
    var image := Image.create(22, 22, false, Image.FORMAT_RGBA8)
    image.fill(Color(0, 0, 0, 0))
    for y in range(22):
        for x in range(22):
            var dx := float(x) - 10.5
            var dy := float(y) - 10.5
            if dx * dx + dy * dy <= 100.0:
                image.set_pixel(x, y, Color(0.35, 0.16, 0.05, 1.0))
            elif dx * dx + dy * dy <= 121.0:
                image.set_pixel(x, y, Color(0.55, 0.3, 0.1, 1.0))
    return ImageTexture.create_from_image(image)


func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if event.is_action_pressed(&"ui_down") or event.is_action_pressed(&"move_right"):
        _index = wrapi(_index + 1, 0, _controls.size())
        _highlight()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"move_left"):
        _index = wrapi(_index - 1, 0, _controls.size())
        _highlight()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed(&"confirm") or event.is_action_pressed(&"jump"):
        _activate()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed(&"back"):
        closed.emit()
        get_viewport().set_input_as_handled()


func focus_first() -> void:
    _index = 0
    _highlight()


func _load_values() -> void:
    var settings := GameManager.get_settings()
    if _music:
        _music.value = float(settings.get("music_volume", 0.8))
    if _sfx:
        _sfx.value = float(settings.get("sfx_volume", 0.8))
    if _vibration:
        _vibration.button_pressed = bool(settings.get("vibration", true))
    if _fullscreen:
        _fullscreen.button_pressed = bool(settings.get("fullscreen", false))
    if _language:
        var current := String(settings.get("language", "de"))
        _language.select(1 if current.begins_with("de") else 0)
    if _character:
        var is_cowgirl := GameManager.get_player_character() == GameManager.PLAYER_COWGIRL
        if _character.item_count < 2:
            _character.clear()
            _character.add_item(tr("Cowboy"), 0)
            _character.add_item(tr("Cowgirl"), 1)
        _character.select(1 if is_cowgirl else 0)
    if _trail_mode:
        var badges_per_life := GameManager.get_badges_per_life_setting()
        _trail_mode.clear()
        _trail_mode.add_item(tr("Classic"), 0)
        for tier in GameManager.ADVANCED_BADGE_TIERS:
            _trail_mode.add_item(tr("Advanced ★%d") % tier, tier)
        var select_index := 0
        for i in range(_trail_mode.item_count):
            if int(_trail_mode.get_item_id(i)) == badges_per_life:
                select_index = i
                break
        _trail_mode.select(select_index)


func _select_language(item_index: int) -> void:
    if _language == null or item_index < 0:
        return
    var locale := "de" if item_index == 1 else "en"
    GameManager.set_setting("language", locale)


func _select_character(item_index: int) -> void:
    if _character == null or item_index < 0:
        return
    var character := GameManager.PLAYER_COWGIRL if item_index == 1 else GameManager.PLAYER_COWBOY
    GameManager.set_setting("player_character", character)


func _select_trail_mode(item_index: int) -> void:
    if _trail_mode == null or item_index < 0:
        return
    GameManager.set_badges_per_life_setting(int(_trail_mode.get_item_id(item_index)))


func _activate() -> void:
    var control := _controls[_index]
    if control is CheckButton:
        (control as CheckButton).button_pressed = not (control as CheckButton).button_pressed
    elif control is OptionButton:
        (control as OptionButton).show_popup()
    elif control is Button:
        (control as Button).pressed.emit()


func _highlight() -> void:
    for i in range(_controls.size()):
        if _controls[i] != null:
            _controls[i].modulate = Color(1, 1, 0.55, 1) if i == _index else Color(1, 1, 1, 1)
