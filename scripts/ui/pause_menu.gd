class_name PauseMenu
extends CanvasLayer

signal continue_pressed
signal save_pressed
signal load_pressed
signal restart_level_pressed
signal restart_pressed
signal save_select_pressed
signal settings_pressed
signal quit_pressed

const BUTTON_NAMES := [
    "ContinueButton",
    "SaveButton",
    "LoadButton",
    "RestartLevelButton",
    "RestartButton",
    "SaveSelectButton",
    "SettingsButton",
    "QuitButton",
]

var _settings: SettingsPanel
var _buttons: Array[Button] = []
var _index: int = 0


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    layer = 120
    _settings = get_node_or_null("SettingsPanel") as SettingsPanel
    _style_panel()
    call_deferred(&"_fit_panel_to_viewport")
    _collect_buttons(true)
    if _settings != null:
        _settings.visible = false
        _settings.closed.connect(_on_settings_closed)
    _connect_buttons()
    if not get_viewport().size_changed.is_connected(_fit_panel_to_viewport):
        get_viewport().size_changed.connect(_fit_panel_to_viewport)


func _unhandled_input(event: InputEvent) -> void:
    if not visible or (_settings != null and _settings.visible):
        return
    if event.is_action_pressed(&"ui_down") or event.is_action_pressed(&"move_right"):
        _move(1)
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"move_left"):
        _move(-1)
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed(&"confirm") or event.is_action_pressed(&"jump"):
        _activate()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed(&"back") or event.is_action_pressed(&"pause"):
        continue_pressed.emit()
        get_viewport().set_input_as_handled()


func focus_first() -> void:
    _index = 0
    _highlight()


func show_settings() -> void:
    var panel := get_node_or_null("Panel") as Control
    if panel != null:
        panel.visible = false
    if _settings != null:
        _settings.visible = true
        _settings.focus_first()


func set_save_options(campaign_save_enabled: bool, can_load: bool) -> void:
    var save_button := _button("SaveButton")
    var load_button := _button("LoadButton")
    var restart_trail := _button("RestartButton")
    if save_button != null:
        save_button.visible = campaign_save_enabled
    if load_button != null:
        load_button.visible = campaign_save_enabled
        load_button.disabled = not can_load
        load_button.text = tr("Load Game") if can_load else tr("Load Game (none yet)")
    ## Full-trail restart only makes sense on a campaign save, not a workshop playtest.
    if restart_trail != null:
        restart_trail.visible = campaign_save_enabled
    _collect_buttons(false)
    call_deferred(&"_fit_panel_to_viewport")
    focus_first()


func _on_settings_closed() -> void:
    if _settings != null:
        _settings.visible = false
    var panel := get_node_or_null("Panel") as Control
    if panel != null:
        panel.visible = true
    call_deferred(&"_fit_panel_to_viewport")
    focus_first()


func _button(button_name: String) -> Button:
    var button := get_node_or_null("Panel/Margin/VBox/%s" % button_name) as Button
    if button == null:
        button = get_node_or_null("Panel/%s" % button_name) as Button
    return button


func _collect_buttons(include_disabled: bool) -> void:
    _buttons.clear()
    for button_name in BUTTON_NAMES:
        var button := _button(button_name)
        if button == null or not button.visible:
            continue
        if include_disabled or not button.disabled:
            _buttons.append(button)


func _connect_buttons() -> void:
    var continue_button := _button("ContinueButton")
    var save_button := _button("SaveButton")
    var load_button := _button("LoadButton")
    var restart_level_button := _button("RestartLevelButton")
    var restart_button := _button("RestartButton")
    var select_button := _button("SaveSelectButton")
    var settings_button := _button("SettingsButton")
    var quit_button := _button("QuitButton")
    if continue_button != null:
        continue_button.pressed.connect(func() -> void: continue_pressed.emit())
    if save_button != null:
        save_button.pressed.connect(func() -> void: save_pressed.emit())
    if load_button != null:
        load_button.pressed.connect(func() -> void: load_pressed.emit())
    if restart_level_button != null:
        restart_level_button.pressed.connect(func() -> void: restart_level_pressed.emit())
    if restart_button != null:
        restart_button.pressed.connect(func() -> void: restart_pressed.emit())
    if select_button != null:
        select_button.pressed.connect(func() -> void: save_select_pressed.emit())
    if settings_button != null:
        settings_button.pressed.connect(func() -> void: settings_pressed.emit())
    if quit_button != null:
        quit_button.pressed.connect(func() -> void: quit_pressed.emit())


func _style_panel() -> void:
    var dim := get_node_or_null("Dim") as ColorRect
    if dim != null:
        dim.color = MenuChrome.DIM
    var panel := get_node_or_null("Panel") as PanelContainer
    if panel != null:
        panel.add_theme_stylebox_override(&"panel", MenuChrome.panel_style())
    var margin := get_node_or_null("Panel/Margin") as MarginContainer
    if margin != null:
        margin.add_theme_constant_override(&"margin_left", 20)
        margin.add_theme_constant_override(&"margin_top", 14)
        margin.add_theme_constant_override(&"margin_right", 20)
        margin.add_theme_constant_override(&"margin_bottom", 14)
    var vbox := get_node_or_null("Panel/Margin/VBox") as VBoxContainer
    if vbox != null:
        vbox.add_theme_constant_override(&"separation", 8)
    var title := get_node_or_null("Panel/Margin/VBox/Title") as Label
    if title != null:
        MenuChrome.apply_ink_label(title)
        title.add_theme_font_size_override(&"font_size", 28)
    for button_name in BUTTON_NAMES:
        var button := _button(button_name)
        if button != null:
            button.custom_minimum_size.y = 44
            MenuChrome.style_wood_button(button, 18)
            var normal := MenuChrome.wood_style(MenuChrome.WOOD, 8)
            normal.content_margin_top = 6
            normal.content_margin_bottom = 6
            var hover := MenuChrome.wood_style(MenuChrome.WOOD_HOVER, 8)
            hover.content_margin_top = 6
            hover.content_margin_bottom = 6
            button.add_theme_stylebox_override(&"normal", normal)
            button.add_theme_stylebox_override(&"hover", hover)
            button.add_theme_stylebox_override(&"pressed", hover)
            button.add_theme_stylebox_override(&"focus", hover)


func _fit_panel_to_viewport() -> void:
    var panel := get_node_or_null("Panel") as Control
    if panel == null or not panel.visible:
        return
    var viewport := get_viewport().get_visible_rect().size
    if viewport.x < 32.0 or viewport.y < 32.0:
        return
    var max_w := mini(480.0, viewport.x - 48.0)
    var max_h := viewport.y - 28.0
    panel.custom_minimum_size = Vector2(max_w, 0.0)
    panel.reset_size()
    var wanted_h := maxf(panel.get_combined_minimum_size().y, 1.0)
    var h := minf(wanted_h, max_h)
    var half_w := max_w * 0.5
    var half_h := h * 0.5
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.offset_left = -half_w
    panel.offset_right = half_w
    panel.offset_top = -half_h
    panel.offset_bottom = half_h


func _move(delta: int) -> void:
    if _buttons.is_empty():
        return
    _index = wrapi(_index + delta, 0, _buttons.size())
    _highlight()


func _activate() -> void:
    if _buttons.is_empty():
        return
    _buttons[_index].pressed.emit()


func _highlight() -> void:
    for i in range(_buttons.size()):
        _buttons[i].modulate = Color(1, 1, 0.6, 1) if i == _index else Color(1, 1, 1, 1)
