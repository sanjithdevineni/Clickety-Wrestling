extends Control

@onready var center: CenterContainer = $Center
@onready var label: Label = $Center/GoLabel
var _tw: Tween

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 1000
	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false

# duration = how long GO! stays
# pop_scale = how much it pops from smaller to final (1.0 = no pop)
func show_go(duration: float = 1.2, pop_scale: float = 1.12) -> void:
	visible = true

	# Big, centered, readable
	label.text = "GO!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1, 0.15, 0.15))

	# Pick a large font size that fits the screen nicely
	var vs: Vector2i = get_viewport_rect().size         # or: get_viewport().get_visible_rect().size
	var base_font: int = int(min(vs.x, vs.y) * 0.28)
	label.add_theme_font_size_override("font_size", base_font)

	# Make sure the label has a concrete size before setting the pivot
	await get_tree().process_frame
	label.size = label.get_minimum_size()
	label.pivot_offset = label.size * 0.5          # <-- center the pivot

	# Pop animation around the center
	label.modulate = Color(1, 1, 1, 0)
	label.scale = Vector2(1.0 / pop_scale, 1.0 / pop_scale)

	if _tw: _tw.kill()
	_tw = create_tween()
	_tw.tween_property(label, "modulate:a", 1.0, 0.12)
	_tw.parallel().tween_property(label, "scale", Vector2(1, 1), 0.20)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tw.tween_interval(max(0.0, duration - 0.30))
	_tw.tween_property(label, "modulate:a", 0.0, 0.18)
	_tw.tween_callback(func(): visible = false)

func hide_now() -> void:
	if _tw: _tw.kill()
	visible = false
