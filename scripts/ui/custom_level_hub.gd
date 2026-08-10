extends Control

## Campaign workshop: edit built-in copies or insert extra trails anywhere.
## Painted desert / saloon look matching the start screen.

const TRAIL_PACK_FILTER := "*.cowboytrail ; Cowboy Trail Pack"

var _status_label: Label
var _export_dialog: FileDialog
var _import_dialog: FileDialog


func _ready() -> void:
    _build_ui()


func _unhandled_input(event: InputEvent) -> void:
    if _dialog_open():
        return
    if event.is_action_pressed(&"back"):
        GameManager.return_to_save_select()
        get_viewport().set_input_as_handled()


func _dialog_open() -> bool:
    return (
        (_export_dialog != null and _export_dialog.visible)
        or (_import_dialog != null and _import_dialog.visible)
    )


func _fit_title_on_board(label: Label, max_width: float, max_size: int, min_size: int) -> void:
    var font := label.get_theme_font(&"font")
    if font == null:
        label.add_theme_font_size_override(&"font_size", mini(24, max_size))
        return
    for size in range(max_size, min_size - 1, -1):
        var text_w := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
        if text_w <= max_width:
            label.add_theme_font_size_override(&"font_size", size)
            return
    label.add_theme_font_size_override(&"font_size", min_size)


func _build_ui() -> void:
    MenuChrome.add_desert_backdrop(self, true)

    var box := VBoxContainer.new()
    box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 22)
    box.add_theme_constant_override(&"separation", 10)
    add_child(box)

    var back := _make_button(
        tr("Back to Cowboy Trail"),
        Vector2(0, 48),
        18,
        GameManager.return_to_save_select
    )
    back.name = "BackButtonTop"
    box.add_child(back)

    var title_row := CenterContainer.new()
    title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_child(title_row)

    var title_board := TextureRect.new()
    title_board.name = "TitleBoard"
    title_board.texture = load(MenuChrome.TITLE_BOARD_PATH) as Texture2D
    title_board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    title_board.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    ## Match the 720×280 art aspect so the painted plank fills the control
    ## (otherwise KEEP_ASPECT shrinks the board while the label stays full-width).
    var board_w := 820.0
    var board_h := board_w * (280.0 / 720.0)
    title_board.custom_minimum_size = Vector2(board_w, board_h)
    title_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
    title_row.add_child(title_board)

    var title := Label.new()
    title.name = "Title"
    title.text = tr("Campaign Workshop")
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    title.offset_left = 120.0
    title.offset_right = -120.0
    title.offset_top = -12.0
    title.offset_bottom = -12.0
    title.clip_text = true
    MenuChrome.apply_ink_label(title)
    title_board.add_child(title)
    _fit_title_on_board(title, board_w - 280.0, 26, 17)

    var help := Label.new()
    help.text = tr(
        "Self-made trails sit in campaign order. Changed campaign trails are marked. Add a trail before any row."
    )
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    help.add_theme_font_size_override(&"font_size", 18)
    MenuChrome.apply_cream_outline(help, Color(0.96, 0.9, 0.7, 1.0), 2)
    box.add_child(help)

    var list_panel := PanelContainer.new()
    list_panel.name = "TrailPanel"
    list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    list_panel.add_theme_stylebox_override(&"panel", MenuChrome.panel_style())
    box.add_child(list_panel)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.custom_minimum_size = Vector2(0, 160)
    list_panel.add_child(scroll)

    var rows := VBoxContainer.new()
    rows.name = "TrailRows"
    rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    rows.add_theme_constant_override(&"separation", 8)
    scroll.add_child(rows)

    var campaign_index := 1
    for entry in CustomLevelStore.campaign_entries():
        _add_campaign_row(rows, entry, campaign_index)
        campaign_index += 1
    rows.add_child(_make_button(
        tr("+ Add a new trail at the end"),
        Vector2(0, 48),
        19,
        func() -> void: _add_extra(CustomLevelStore.BUILTIN_COUNT + 1)
    ))

    var share_row := HBoxContainer.new()
    share_row.alignment = BoxContainer.ALIGNMENT_CENTER
    share_row.add_theme_constant_override(&"separation", 12)
    box.add_child(share_row)
    share_row.add_child(_make_button(
        tr("Export Trails"),
        Vector2(220, 48),
        18,
        _open_export_dialog
    ))
    share_row.add_child(_make_button(
        tr("Import Trails"),
        Vector2(220, 48),
        18,
        _open_import_dialog
    ))

    _status_label = Label.new()
    _status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _status_label.add_theme_font_size_override(&"font_size", 16)
    MenuChrome.apply_cream_outline(_status_label, Color(0.96, 0.9, 0.7, 1.0), 2)
    box.add_child(_status_label)

    _export_dialog = FileDialog.new()
    _export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
    _export_dialog.access = FileDialog.ACCESS_FILESYSTEM
    _export_dialog.filters = PackedStringArray([TRAIL_PACK_FILTER])
    _export_dialog.title = tr("Export Trails")
    _export_dialog.file_selected.connect(_on_export_selected)
    add_child(_export_dialog)
    _import_dialog = FileDialog.new()
    _import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    _import_dialog.access = FileDialog.ACCESS_FILESYSTEM
    _import_dialog.filters = PackedStringArray([TRAIL_PACK_FILTER])
    _import_dialog.title = tr("Import Trails")
    _import_dialog.file_selected.connect(_on_import_selected)
    add_child(_import_dialog)
    if rows.get_child_count() > 0:
        (rows.get_child(0) as Control).grab_focus()


func _add_campaign_row(parent: VBoxContainer, entry: Dictionary, campaign_index: int) -> void:
    var entry_kind := str(entry.get("entry_kind", ""))
    if entry_kind.is_empty():
        if int(entry.get("source_level", 0)) == 0:
            entry_kind = "extra"
        elif str(entry.get("kind", "")) == "custom":
            entry_kind = "override"
        else:
            entry_kind = "builtin"
    var row := HBoxContainer.new()
    row.add_theme_constant_override(&"separation", 8)
    row.set_meta("campaign_index", campaign_index)
    row.set_meta("entry_kind", entry_kind)
    row.set_meta("custom_slot", int(entry.get("custom_slot", -1)))
    row.set_meta("source_level", int(entry.get("source_level", 0)))
    parent.add_child(row)
    if entry_kind == "extra":
        row.add_child(_make_kind_badge(tr("self-made"), Color(0.22, 0.48, 0.18), Color(0.86, 0.95, 0.72)))
    elif entry_kind == "override":
        row.add_child(_make_kind_badge(tr("changed"), Color(0.48, 0.28, 0.08), Color(0.96, 0.86, 0.62)))
    var label := Label.new()
    label.custom_minimum_size = Vector2(360, 48)
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.add_theme_font_size_override(&"font_size", 20)
    label.text = _row_label(entry, campaign_index, entry_kind)
    if entry_kind == "extra":
        label.add_theme_color_override(&"font_color", Color(0.12, 0.32, 0.08))
    elif entry_kind == "override":
        label.add_theme_color_override(&"font_color", Color(0.42, 0.22, 0.05))
    else:
        label.add_theme_color_override(&"font_color", MenuChrome.INK)
    row.add_child(label)
    var edit_slot := int(entry.get("custom_slot", -1))
    if entry_kind == "builtin":
        edit_slot = CustomLevelStore.override_slot_for(int(entry.get("source_level", 1)))
    row.add_child(_make_button(
        tr("Edit level") if entry_kind != "extra" else tr("Edit"),
        Vector2(190, 48),
        0,
        func() -> void: GameManager.edit_custom_level(edit_slot)
    ))
    row.add_child(_make_button(
        tr("Add before"),
        Vector2(190, 48),
        0,
        func() -> void: _add_before_entry(entry, entry_kind)
    ))
    if entry_kind == "override":
        row.add_child(_make_button(
            tr("Restore original"),
            Vector2(190, 48),
            0,
            func() -> void:
                CustomLevelStore.erase(int(entry.get("custom_slot", -1)))
                get_tree().reload_current_scene()
        ))
    elif entry_kind == "extra":
        row.add_child(_make_button(
            tr("Remove"),
            Vector2(190, 48),
            0,
            func() -> void:
                CustomLevelStore.erase(int(entry.get("custom_slot", -1)))
                get_tree().reload_current_scene()
        ))


func _row_label(entry: Dictionary, campaign_index: int, entry_kind: String) -> String:
    var title := str(entry.get("title", tr("Extra Trail")))
    if entry_kind == "extra":
        ## Badge already says Eigenbau / homemade — keep the name front and center.
        return "%d: %s" % [campaign_index, title]
    if entry_kind == "override":
        var source := int(entry.get("source_level", 0))
        if source >= 1 and source <= CustomLevelStore.BUILTIN_COUNT:
            title = CustomLevelStore.BUILTIN_NAMES[source - 1]
        return "%d: %s" % [campaign_index, title]
    return "%d: %s" % [campaign_index, title]


func _make_kind_badge(text: String, ink: Color, fill: Color) -> PanelContainer:
    var badge := PanelContainer.new()
    badge.custom_minimum_size = Vector2(128, 40)
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.set_corner_radius_all(10)
    style.set_border_width_all(2)
    style.border_color = ink
    style.content_margin_left = 10
    style.content_margin_right = 10
    style.content_margin_top = 6
    style.content_margin_bottom = 6
    badge.add_theme_stylebox_override(&"panel", style)
    var label := Label.new()
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override(&"font_size", 15)
    label.add_theme_color_override(&"font_color", ink)
    badge.add_child(label)
    return badge


func _add_before_entry(entry: Dictionary, entry_kind: String) -> void:
    if entry_kind == "extra":
        _add_extra(
            int(entry.get("insert_position", CustomLevelStore.BUILTIN_COUNT + 1)),
            int(entry.get("custom_slot", -1))
        )
        return
    _add_extra(int(entry.get("source_level", 1)))


func _make_button(
    text: String,
    min_size: Vector2,
    font_size: int,
    action: Callable
) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = min_size
    MenuChrome.style_wood_button(button, font_size if font_size > 0 else 18)
    button.pressed.connect(action)
    return button


func _add_extra(insert_position: int, before_custom_slot: int = -1) -> void:
    var draft := CustomLevelStore.new_extra_draft(insert_position, before_custom_slot)
    if not draft.is_empty():
        GameManager.edit_new_custom_level(int(draft["slot"]), draft)


func _open_export_dialog() -> void:
    if CustomLevelStore.existing_custom_slots().is_empty():
        _set_status(tr("No custom trails to export."))
        return
    _export_dialog.popup_centered(Vector2i(900, 600))


func _open_import_dialog() -> void:
    _import_dialog.popup_centered(Vector2i(900, 600))


func _on_export_selected(path: String) -> void:
    var export_path := _ensure_pack_extension(path)
    if CustomLevelStore.export_share_pack(export_path):
        _set_status(tr("Exported %d trail(s).") % CustomLevelStore.existing_custom_slots().size())
    else:
        _set_status(tr("Could not write trail pack."))


func _on_import_selected(path: String) -> void:
    var result := CustomLevelStore.import_share_pack(path)
    if bool(result.get("ok", false)):
        get_tree().reload_current_scene()
        return
    var message := str(result.get("message", tr("Could not import trail pack.")))
    _set_status(message)


func _ensure_pack_extension(path: String) -> String:
    if path.get_extension().is_empty():
        return "%s.cowboytrail" % path
    return path


func _set_status(message: String) -> void:
    if _status_label != null:
        _status_label.text = message
