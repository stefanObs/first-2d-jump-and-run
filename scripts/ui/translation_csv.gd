class_name TranslationCsv
extends RefCounted

## CSV and printf-placeholder helpers shared by the translation editor and tests.

const SOURCE_PATH := "res://assets/i18n/game_text.csv"


static func parse(text: String) -> Dictionary:
	var records: Array[Array] = []
	var record: Array[String] = []
	var field := ""
	var quoted := false
	var i := 0
	while i < text.length():
		var character := text[i]
		if quoted:
			if character == "\"":
				if i + 1 < text.length() and text[i + 1] == "\"":
					field += "\""
					i += 2
					continue
				quoted = false
			else:
				field += character
		elif character == "\"":
			if field.is_empty():
				quoted = true
			else:
				field += character
		elif character == ",":
			record.append(field)
			field = ""
		elif character == "\n" or character == "\r":
			record.append(field)
			records.append(record)
			record = []
			field = ""
			if character == "\r" and i + 1 < text.length() and text[i + 1] == "\n":
				i += 1
		else:
			field += character
		i += 1
	if quoted:
		return {"rows": [], "error": "The CSV ends inside a quoted value."}
	if not record.is_empty() or not field.is_empty():
		record.append(field)
		records.append(record)
	if records.is_empty():
		return {"rows": [], "error": "The CSV is empty."}
	var header: Array = records.pop_front()
	if header.size() < 3 or String(header[0]).trim_prefix("\ufeff") != "keys":
		return {"rows": [], "error": "Expected CSV columns: keys,en,de."}
	var rows: Array[Dictionary] = []
	for record_value in records:
		var columns: Array = record_value
		if columns.size() == 1 and String(columns[0]).is_empty():
			continue
		if columns.size() != 3:
			return {
				"rows": [],
				"error": "A CSV row has %d columns instead of 3." % columns.size(),
			}
		rows.append({
			"key": String(columns[0]),
			"en": String(columns[1]),
			"de": String(columns[2]),
		})
	return {"rows": rows, "error": ""}


static func serialize(rows: Array) -> String:
	var lines: PackedStringArray = ["keys,en,de"]
	for value in rows:
		var row: Dictionary = value
		lines.append(",".join([
			_encode_field(String(row.get("key", ""))),
			_encode_field(String(row.get("en", ""))),
			_encode_field(String(row.get("de", ""))),
		]))
	return "\n".join(lines) + "\n"


static func load_source() -> Dictionary:
	var file := FileAccess.open(SOURCE_PATH, FileAccess.READ)
	if file == null:
		return {"rows": [], "error": "Could not open %s." % SOURCE_PATH}
	return parse(file.get_as_text())


static func placeholder_signature(text: String) -> PackedStringArray:
	var signature := PackedStringArray()
	var i := 0
	while i < text.length():
		if text[i] != "%":
			i += 1
			continue
		var placeholder := _read_placeholder(text, i)
		if placeholder.is_empty():
			i += 1
			continue
		i = int(placeholder["end"])
		var kind := String(placeholder["kind"])
		signature.append(kind)
	return signature


static func placeholders_match(english: String, german: String) -> bool:
	return placeholder_signature(english) == placeholder_signature(german)


static func has_placeholders(text: String) -> bool:
	return not placeholder_signature(text).is_empty()


static func example(text: String) -> String:
	var output := ""
	var cursor := 0
	var i := 0
	var value_index := 0
	while i < text.length():
		if text[i] != "%":
			i += 1
			continue
		var placeholder := _read_placeholder(text, i)
		if placeholder.is_empty():
			i += 1
			continue
		output += text.substr(cursor, i - cursor)
		var kind := String(placeholder["kind"])
		if kind == "percent":
			output += "%"
		else:
			output += _representative_value(kind, value_index, String(placeholder["raw"]))
			value_index += 1
		i = int(placeholder["end"])
		cursor = i
	output += text.substr(cursor)
	return output


static func _encode_field(value: String) -> String:
	if value.contains(",") or value.contains("\"") or value.contains("\n") or value.contains("\r"):
		return "\"%s\"" % value.replace("\"", "\"\"")
	return value


static func _read_placeholder(text: String, start: int) -> Dictionary:
	if start + 1 >= text.length() or text[start] != "%":
		return {}
	if text[start + 1] == "%":
		return {"end": start + 2, "kind": "percent", "raw": "%%"}
	var i := start + 1
	while i < text.length() and "#0- +'".contains(text[i]):
		i += 1
	while i < text.length() and (text[i].is_valid_int() or text[i] == "*" or text[i] == "$"):
		i += 1
	if i < text.length() and text[i] == ".":
		i += 1
		while i < text.length() and (text[i].is_valid_int() or text[i] == "*"):
			i += 1
	while i < text.length() and "hlLjzt".contains(text[i]):
		i += 1
	if i >= text.length():
		return {}
	var conversion := text[i]
	var kind := ""
	if "diouxX".contains(conversion):
		kind = "integer"
	elif "fFeEgGaA".contains(conversion):
		kind = "float"
	elif conversion == "s":
		kind = "string"
	elif conversion == "c":
		kind = "character"
	else:
		return {}
	return {
		"end": i + 1,
		"kind": kind,
		"raw": text.substr(start, i + 1 - start),
	}


static func _representative_value(kind: String, index: int, raw: String) -> String:
	if kind == "string":
		var strings := ["Wings", "Dusty Trail", "Space", "Lasso"]
		return strings[index % strings.size()]
	if kind == "character":
		return "A"
	if kind == "integer":
		var integers := [7, 2, 3, 12]
		var value := str(integers[index % integers.size()])
		var width_text := ""
		for character in raw:
			if character.is_valid_int():
				width_text += character
			elif not width_text.is_empty():
				break
		var width := int(width_text) if not width_text.is_empty() else 0
		if raw.contains("0") and width > value.length():
			value = value.pad_zeros(width)
		return value
	var floats := [30.0, 7.5, 45.0, 12.25]
	var number: float = floats[index % floats.size()]
	var precision := 1
	var dot := raw.find(".")
	if dot >= 0:
		var digits := ""
		var digit_index := dot + 1
		while digit_index < raw.length() and raw[digit_index].is_valid_int():
			digits += raw[digit_index]
			digit_index += 1
		if not digits.is_empty():
			precision = clampi(int(digits), 0, 4)
	return String.num(number, precision)
