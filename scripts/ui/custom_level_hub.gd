extends Control

## Campaign workshop: edit built-in copies or insert extra trails anywhere.
## Compact start-screen chrome with kid-readable icon buttons.

const TRAIL_PACK_FILTER := "*.cowboytrail ; Cowboy Trail Pack"
const CIRCLE_PLATE := "res://assets/ui/menu_button_circle.png"
const ICON_BACK := "res://assets/ui/menu_icon_back.png"
const ICON_HAMMER := "res://assets/ui/menu_icon_hammer.png"
const ICON_EDIT := "res://assets/ui/menu_icon_edit.png"
const ICON_ADD := "res://assets/ui/menu_icon_add.png"
const ICON_REMOVE := "res://assets/ui/menu_icon_remove.png"
const ICON_RESTORE := "res://assets/ui/menu_icon_restore.png"
const ICON_EXPORT := "res://assets/ui/menu_icon_export.png"
const ICON_IMPORT := "res://assets/ui/menu_icon_import.png"
const ICON_ADD_TRAIL := "res://assets/ui/menu_icon_add_trail.png"

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


func _build_ui() -> void:
    MenuChrome.add_desert_backdrop(self, true)

    ## Circle back chrome — same language as start-screen corners.
    var back := _make_circle_chrome_button(
        "BackButtonTop",
        ICON_BACK,
        tr("Back to Cowboy Trail"),
        GameManager.return_to_save_select
    )
    back.set_anchors_preset(Control.PRESET_TOP_LEFT)
    back.offset_left = 24.0
    back.offset_top = 20.0
    back.offset_right = 132.0
    back.offset_bottom = 108.0
    add_child(back)

    var box := VBoxContainer.new()
    box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 18)
    box.offset_top = 112.0
    box.add_theme_constant_override(&"separation", 8)
    add_child(box)

    ## Compact title row (no giant saloon board) — hammer + cream title.
    var title_row := HBoxContainer.new()
    title_row.alignment = BoxContainer.ALIGNMENT_CENTER
    title_row.add_theme_constant_override(&"separation", 12)
    box.add_child(title_row)

    var title_icon := TextureRect.new()
    title_icon.custom_minimum_size = Vector2(44, 44)
    title_icon.texture = load(ICON_HAMMER) as Texture2D
    title_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    title_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    title_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    title_row.add_child(title_icon)

    var title := Label.new()
    title.name = "Title"
    title.text = tr("Campaign Workshop")
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override(&"font_size", 30)
    MenuChrome.apply_cream_outline(title, MenuChrome.TITLE_CREAM, 4)
    title_row.add_child(title)

    var help := Label.new()
    help.text = tr(
        "Self-made trails sit in campaign order. Changed campaign trails are marked. Add a trail before any row."
    )
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    help.add_theme_font_size_override(&"font_size", 14)
    MenuChrome.apply_cream_outline(help, Color(0.96, 0.9, 0.7, 1.0), 2)
    box.add_child(help)

    var scroll := ScrollContainer.new()
    scroll.name = "TrailScroll"
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.custom_minimum_size = Vector2(0, 200)
    box.add_child(scroll)

    var rows := VBoxContainer.new()
    rows.name = "TrailRows"
    rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    rows.add_theme_constant_override(&"separation", 8)
    scroll.add_child(rows)

    var campaign_index := 1
    for entry in CustomLevelStore.campaign_entries():
        _add_campaign_row(rows, entry, campaign_index)
        campaign_index += 1

    rows.add_child(_make_icon_button(
        tr("+ Add a new trail at the end"),
        ICON_ADD_TRAIL,
        Vector2(0, 52),
        18,
        func() -> void: _add_extra(CustomLevelStore.BUILTIN_COUNT + 1)
    ))

    var share_row := HBoxContainer.new()
    share_row.alignment = BoxContainer.ALIGNMENT_CENTER
    share_row.add_theme_constant_override(&"separation", 14)
    box.add_child(share_row)
    share_row.add_child(_make_icon_button(
        tr("Export Trails"),
        ICON_EXPORT,
        Vector2(240, 52),
        18,
        _open_export_dialog
    ))
    share_row.add_child(_make_icon_button(
        tr("Import Trails"),
        ICON_IMPORT,
        Vector2(240, 52),
        18,
        _open_import_dialog
    ))

    _status_label = Label.new()
    _status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _status_label.add_theme_font_size_override(&"font_size", 15)
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
        var first := rows.get_child(0)
        if first is Control:
            (first as Control).grab_focus()
    MenuChrome.bind_menu_buttons(self)


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
    label.custom_minimum_size = Vector2(280, 48)
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.add_theme_font_size_override(&"font_size", 20)
    label.text = _row_label(entry, campaign_index, entry_kind)
    if entry_kind == "extra":
        MenuChrome.apply_cream_outline(label, Color(0.75, 0.95, 0.55, 1.0), 3)
    elif entry_kind == "override":
        MenuChrome.apply_cream_outline(label, Color(1.0, 0.86, 0.45, 1.0), 3)
    else:
        ## Cream outline so trail names stay readable on the desert backdrop.
        MenuChrome.apply_cream_outline(label, Color(1.0, 0.94, 0.78, 1.0), 3)
    row.add_child(label)

    var edit_slot := int(entry.get("custom_slot", -1))
    if entry_kind == "builtin":
        edit_slot = CustomLevelStore.override_slot_for(int(entry.get("source_level", 1)))
    row.add_child(_make_icon_button(
        tr("Edit level") if entry_kind != "extra" else tr("Edit"),
        ICON_EDIT,
        Vector2(168, 48),
        16,
        func() -> void: GameManager.edit_custom_level(edit_slot)
    ))
    row.add_child(_make_icon_button(
        tr("Add before"),
        ICON_ADD,
        Vector2(168, 48),
        16,
        func() -> void: _add_before_entry(entry, entry_kind)
    ))
    if entry_kind == "override":
        row.add_child(_make_icon_button(
            tr("Restore original"),
            ICON_RESTORE,
            Vector2(168, 48),
            16,
            func() -> void:
                CustomLevelStore.erase(int(entry.get("custom_slot", -1)))
                get_tree().reload_current_scene()
        ))
    elif entry_kind == "extra":
        row.add_child(_make_icon_button(
            tr("Remove"),
            ICON_REMOVE,
            Vector2(140, 48),
            16,
            func() -> void:
                CustomLevelStore.erase(int(entry.get("custom_slot", -1)))
                get_tree().reload_current_scene()
        ))


func _row_label(entry: Dictionary, campaign_index: int, entry_kind: String) -> String:
    var title := str(entry.get("title", tr("Extra Trail")))
    if entry_kind == "extra":
        return "%d: %s" % [campaign_index, title]
    if entry_kind == "override":
        var source := int(entry.get("source_level", 0))
        if source >= 1 and source <= CustomLevelStore.BUILTIN_COUNT:
            title = CustomLevelStore.BUILTIN_NAMES[source - 1]
        return "%d: %s" % [campaign_index, title]
    return "%d: %s" % [campaign_index, title]


func _make_kind_badge(text: String, ink: Color, fill: Color) -> PanelContainer:
    var badge := PanelContainer.new()
    badge.custom_minimum_size = Vector2(120, 40)
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


func _make_circle_chrome_button(
    button_name: String,
    icon_path: String,
    tooltip: String,
    action: Callable
) -> Button:
    var button := Button.new()
    button.name = button_name
    button.flat = true
    button.focus_mode = Control.FOCUS_ALL
    button.custom_minimum_size = Vector2(108, 88)
    button.tooltip_text = tooltip
    var empty := StyleBoxEmpty.new()
    MenuChrome.apply_button_styleboxes(button, empty, empty)

    var plate := TextureRect.new()
    plate.name = "Plate"
    plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
    plate.texture = load(CIRCLE_PLATE) as Texture2D
    plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    plate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    button.add_child(plate)

    var icon := TextureRect.new()
    icon.name = "Icon"
    icon.set_anchors_preset(Control.PRESET_CENTER)
    icon.offset_left = -28.0
    icon.offset_top = -28.0
    icon.offset_right = 28.0
    icon.offset_bottom = 28.0
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    icon.texture = load(icon_path) as Texture2D
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    button.add_child(icon)

    button.pressed.connect(action)
    return button


func _make_icon_button(
    text: String,
    icon_path: String,
    min_size: Vector2,
    font_size: int,
    action: Callable
) -> Button:
    var button := Button.new()
    button.text = text
    button.tooltip_text = text
    var sized := min_size
    if sized.y < 56.0:
        sized.y = 56.0
    button.custom_minimum_size = sized
    if ResourceLoader.exists(icon_path):
        button.icon = load(icon_path) as Texture2D
        button.expand_icon = true
        button.add_theme_constant_override(&"icon_max_width", 44)
        button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
    MenuChrome.style_wood_button(button, font_size if font_size > 0 else 18)
    var normal := MenuChrome.wood_style(MenuChrome.WOOD, 8)
    normal.content_margin_left = 8
    normal.content_margin_right = 12
    normal.content_margin_top = 6
    normal.content_margin_bottom = 6
    var hover := MenuChrome.wood_style(MenuChrome.WOOD_HOVER, 8)
    hover.content_margin_left = 8
    hover.content_margin_right = 12
    hover.content_margin_top = 6
    hover.content_margin_bottom = 6
    MenuChrome.apply_button_styleboxes(button, normal, hover)
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
