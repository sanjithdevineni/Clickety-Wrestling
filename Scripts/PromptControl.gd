extends Control

@onready var label: Label = get_node_or_null("MainLabel") as Label
@onready var arrow_sprite: AnimatedSprite2D = $"../../RedArrow"   # your sprite node

var _seq_len := 0

const DIR_TO_ARROW := {"up":"↑","down":"↓","left":"←","right":"→"}
# Map directions to sprite frames
const DIR_TO_FRAME := {
	"up": 0,
	"right": 1,
	"down": 2,
	"left": 3
}

func _ensure_label() -> bool:
	if label == null:
		# Try to find it anywhere under this prompt just in case it's nested
		label = find_child("MainLabel", true, false) as Label
	return label != null

func _phase_name(p) -> String:
	match int(p):
		0: return "GREEN"
		1: return "RED"
		2: return "YELLOW"
		_: return "?"

func show_arrow_color(dir: String, p) -> void:
	if not _ensure_label(): 
		push_warning("MainLabel not found under %s" % name)
		return
	label.text = "%s : %s" % [_phase_name(p), DIR_TO_ARROW.get(dir, "?")]
	match int(p):
		0: label.add_theme_color_override("font_color", Color.hex(0x35c759ff)) # green
		1: label.add_theme_color_override("font_color", Color.hex(0xff3b30ff)) # red
		2: label.add_theme_color_override("font_color", Color.hex(0xffcc00ff)) # yellow
		# update arrow sprite frame
	if dir in DIR_TO_FRAME:
		arrow_sprite.animation = "default"    # make sure it’s set
		arrow_sprite.play()
		arrow_sprite.frame = DIR_TO_FRAME[dir]
		arrow_sprite.stop()   # lock on that frame

func set_pop_visible(on: bool) -> void:
	if not _ensure_label(): return
	if on:
		label.text += "  (GO!)"

func show_sequence(seq: Array) -> void:
	if not _ensure_label(): return
	_seq_len = seq.size()
	var arrows: Array[String] = []
	for d in seq:
		arrows.append(DIR_TO_ARROW.get(d, "?"))
	label.text = "YELLOW SEQ: " + " ".join(arrows)

func highlight_seq_index(i: int) -> void:
	if not _ensure_label(): return
	label.text += "  [%d/%d]" % [i, _seq_len]

func set_boost_visual(on: bool) -> void:
	modulate = (Color(0.8, 1.0, 0.8, 1.0) if on else Color(1, 1, 1, 1))
