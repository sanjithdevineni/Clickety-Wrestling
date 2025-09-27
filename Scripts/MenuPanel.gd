extends Control

@onready var backdrop: ColorRect = $Backdrop
@onready var p1_edit: LineEdit = $Center/Panel/VBox/P1Edit
@onready var p2_edit: LineEdit = $Center/Panel/VBox/P2Edit
@onready var start_btn: Button = $Center/Panel/VBox/StartButton
@onready var big_title: Label = $Center/Panel/VBox/BigTitle
@onready var title: Label = $Center/Panel/VBox/Title
@onready var gm := $"../../GameManager"

func _ready() -> void:
	# Make the overlay cover and block the whole screen
	z_index = 100
	set_anchors_preset(Control.PRESET_FULL_RECT, false)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Backdrop must NOT eat mouse events
	backdrop.color = Color(0,0,0,0.60)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT, false)

	# Center the panel; make inputs fill width
	var vbox := $Center/Panel/VBox as VBoxContainer
	for c in vbox.get_children():
		if c is LineEdit or c is Button:
			(c as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL

	big_title.text = "Clickety Wrestling"
	big_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big_title.add_theme_font_size_override("font_size", 48)

	title.text = "Enter Player Names"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)

	# Start visible; hide HUD while menu is up
	visible = true
	if "set_hud_visible" in gm:
		gm.set_hud_visible(false)

	# Hook up events + focus
	start_btn.pressed.connect(_on_start)
	p1_edit.text_submitted.connect(func(_t): _on_start())
	p2_edit.text_submitted.connect(func(_t): _on_start())
	p1_edit.grab_focus()

func _on_start() -> void:
	var n1 := p1_edit.text.strip_edges()
	var n2 := p2_edit.text.strip_edges()
	if n1 == "": n1 = "Player 1"
	if n2 == "": n2 = "Player 2"

	if "start_game" in gm:
		gm.start_game(n1, n2)

	# Show HUD again after starting
	if "set_hud_visible" in gm:
		gm.set_hud_visible(true)

	visible = false
