extends Control

@onready var backdrop: ColorRect = $Backdrop
@onready var center: CenterContainer = $Center
@onready var panel: Control = $Center/Panel
@onready var vbox: VBoxContainer = $Center/Panel/VBox
@onready var win_title: Label = $Center/Panel/VBox/WinTitle
@onready var winner_name: Label = $Center/Panel/VBox/WinnerName
@onready var play_btn: Button = $Center/Panel/VBox/PlayAgain
@onready var menu_btn: Button = $Center/Panel/VBox/MenuButton
@onready var gm := $"../../GameManager"

func _ready() -> void:
	z_index = 100
	set_anchors_preset(Control.PRESET_FULL_RECT, false)
	mouse_filter = Control.MOUSE_FILTER_STOP

	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	backdrop.color = Color(0,0,0,0.70)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE

	center.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	center.offset_left = 0
	center.offset_top = 0
	center.offset_right = 0
	center.offset_bottom = 0

	# Make the VBox fill the panel so children get full width
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	vbox.offset_left = 24; vbox.offset_right = -24
	vbox.offset_top = 24;  vbox.offset_bottom = -24
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	# Children expand horizontally; labels are centered text
	for c in vbox.get_children():
		if c is Control:
			(c as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	win_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	winner_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_btn.add_theme_font_size_override("font_size", 28)
	play_btn.custom_minimum_size = Vector2(0, 56)

	# Big, readable
	win_title.add_theme_font_size_override("font_size", 72)
	winner_name.add_theme_font_size_override("font_size", 44)

	get_viewport().size_changed.connect(_center_layout)
	_center_layout()
	visible = false
	
	# Make sure the button exists and is interactive
	if play_btn == null:
		push_error("PlayAgain button not found at $Center/Panel/VBox/PlayAgain")
	else:
		play_btn.disabled = false
		play_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		play_btn.pressed.connect(_on_play_again)
		# also allow Enter/Space to trigger when visible
		set_process_unhandled_input(true)
	menu_btn.pressed.connect(_on_menu)
		
func _unhandled_input(e: InputEvent) -> void:
	if not visible:
		return
	if e.is_action_pressed("ui_accept"):
		_on_play_again()

func _center_layout() -> void:
	var vr := get_viewport().get_visible_rect()
	var vw: float = vr.size.x
	var vh: float = vr.size.y

	# Large, responsive card
	var w: float = clampf(vw * 0.70, 640.0, 1600.0)
	var h: float = clampf(vh * 0.60, 360.0, 1000.0)

	# CenterContainer will center this panel by its size
	panel.custom_minimum_size = Vector2(w, h)
	panel.size = Vector2(w, h)



func show_winner(name: String) -> void:
	winner_name.text = "%s Wins!" % name
	visible = true
	if play_btn: play_btn.grab_focus()

func _on_play_again() -> void:
	print("PlayAgain clicked")
	visible = false
	if gm and gm.has_method("start_new_round"):
		gm.start_new_round()
	else:
		# Fallback so the game always recovers
		if gm and gm.has_method("set_hud_visible"):
			gm.set_hud_visible(true)
		if gm:
			gm.call_deferred("_reset_match")
			gm.call_deferred("_start_phase", 0)  # 0 = Phase.GREEN

func _on_menu() -> void:
	visible = false
	if gm and gm.has_method("return_to_menu"):
		gm.return_to_menu()
