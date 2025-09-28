extends Control

@onready var label: Label = get_node_or_null("MainLabel") as Label
<<<<<<< Updated upstream
@onready var arrow_sprite: AnimatedSprite2D = $"Arrows"   # your sprite node

=======
@onready var arrow_sprite: AnimatedSprite2D = $"../../RedArrow"   # your sprite node
>>>>>>> Stashed changes
var _seq_len := 0

const DIR_TO_ARROW := {"up":"↑","down":"↓","left":"←","right":"→"}
# Map directions to sprite frames
const DIR_TO_FRAME := {
	"up": 0,
	"right": 1,
	"down": 2,
	"left": 3
}

# Which animation set to use for each phase
const PHASE_TO_ANIM := {
	0: "green",   # Phase.GREEN
	1: "red",     # Phase.RED
	2: "yellow"   # Phase.YELLOW
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
	#label.text = "%s : %s" % [_phase_name(p), DIR_TO_ARROW.get(dir, "?")]
	label.text = _phase_name(p)
	match int(p):
		0: label.add_theme_color_override("font_color", Color.hex(0x35c759ff)) # green
		1: label.add_theme_color_override("font_color", Color.hex(0xff3b30ff)) # red
		2: label.add_theme_color_override("font_color", Color.hex(0xffcc00ff)) # yellow
		# update arrow sprite frame
	if dir in DIR_TO_FRAME:
<<<<<<< Updated upstream
		var anim_name = PHASE_TO_ANIM.get(int(p), "red")
		arrow_sprite.animation = anim_name
		arrow_sprite.stop()
		arrow_sprite.frame = DIR_TO_FRAME[dir]
		print("Showing dir=", dir, " frame=", DIR_TO_FRAME[dir])  # lock on that frame
		arrow_sprite.z_index = 2
		label.z_index = 1
=======
		arrow_sprite.animation = "default"    # select the animation
		arrow_sprite.stop()                   # make sure it's not animating
		arrow_sprite.frame = DIR_TO_FRAME[dir]
		print("Showing dir=", dir, " frame=", DIR_TO_FRAME[dir])
	arrow_sprite.z_index = 2
	label.z_index = 1
>>>>>>> Stashed changes

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
