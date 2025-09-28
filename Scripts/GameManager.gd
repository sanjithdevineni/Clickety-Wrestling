extends Node

enum Phase { GREEN, RED, YELLOW }
var phase: Phase = Phase.GREEN

@onready var audio := $"../Audio"
@onready var p1_bar := $"../UI/P1Bar"
@onready var p2_bar := $"../UI/P2Bar"
@onready var p1_prompt := $"../UI/P1Prompt"
@onready var p2_prompt := $"../UI/P2Prompt"
@onready var p1_name := $"../UI/P1Name"
@onready var p2_name := $"../UI/P2Name"
@onready var menu := $"../UI/MenuPanel"
@onready var victory := $"../UI/VictoryPanel"

var round_active := false
var game_active := false
var target_dir := "right"
var red_pop_time := 0.0
var phase_time_left := 0.0

var p1_progress := 0.0
var p2_progress := 0.0
var p1_boost_time := 0.0
var p2_boost_time := 0.0

var p1_seq: Array[String] = []
var p2_seq: Array[String] = []
var p1_seq_idx := 0
var p2_seq_idx := 0

var p1_yellow_done := false
var p2_yellow_done := false

@export var GREEN_TICK := 0.6
@export var RED_CHUNK := 6.0
@export var EARLY_PENALTY := 1.0
@export var BOOST_MULTI := 2.0
@export var BOOST_DURATION := 4.0
@export var YELLOW_SEQ_LEN := 4        # 4 arrows per request
@export var YELLOW_TIMEOUT := 10.0

func set_hud_visible(on: bool) -> void:
	(p1_bar as CanvasItem).visible = on
	(p2_bar as CanvasItem).visible = on
	(p1_prompt as CanvasItem).visible = on
	(p2_prompt as CanvasItem).visible = on
	if p1_name: (p1_name as CanvasItem).visible = on
	if p2_name: (p2_name as CanvasItem).visible = on

func _ensure_name_labels() -> void:
	var ui := $"../UI" as Node
	if p1_name == null or not (p1_name is Label):
		p1_name = ui.get_node_or_null("P1Name")
		if p1_name == null:
			p1_name = Label.new()
			p1_name.name = "P1Name"
			ui.add_child(p1_name)
	if p2_name == null or not (p2_name is Label):
		p2_name = ui.get_node_or_null("P2Name")
		if p2_name == null:
			p2_name = Label.new()
			p2_name.name = "P2Name"
			ui.add_child(p2_name)

	# defaults so they’re visible
	for n in [p1_name, p2_name]:
		(n as Label).add_theme_font_size_override("font_size", 30)
		(n as CanvasItem).visible = true
		(n as Label).text = "Player 1" if (n.name == "P1Name") else "Player 2"
		


func _ready():
	_ensure_name_labels()
	randomize()
	await get_tree().process_frame
	_layout_ui()
	get_viewport().size_changed.connect(_layout_ui)
	set_hud_visible(false)  # hide bars/prompts/names under the menu
	# Wait for MenuPanel to call start_game(...)
	
func start_game(p1n: String, p2n: String) -> void:
	_ensure_name_labels()
	game_active = true

	if p1_name is Label:
		(p1_name as Label).text = p1n
		(p1_name as Label).add_theme_font_size_override("font_size", 30)
	if p2_name is Label:
		(p2_name as Label).text = p2n
		(p2_name as Label).add_theme_font_size_override("font_size", 30)

	set_hud_visible(true)   # <— ensure names/bars/prompts are visible
	_layout_ui()            # <— anchor/position after we made them visible
	await get_tree().process_frame
	(p1_name as CanvasItem).show()
	(p2_name as CanvasItem).show()

	_reset_match()
	round_active = true
	_start_phase(Phase.GREEN)

func _process(delta: float) -> void:
	if not game_active or not round_active:
		return

	# timers
	phase_time_left -= delta
	if p1_boost_time > 0: p1_boost_time -= delta
	if p2_boost_time > 0: p2_boost_time -= delta

	if phase == Phase.RED and red_pop_time > 0.0:
		red_pop_time -= delta
		if red_pop_time <= 0.0:
			p1_prompt.call("set_pop_visible", true)
			p2_prompt.call("set_pop_visible", true)

	# update bars (keep your UI style)
	p1_bar.value = p1_progress
	p2_bar.value = p2_progress

	if p1_progress >= 100.0 or p2_progress >= 100.0:
		_end_round()
		return

	# phase exits
	if phase == Phase.YELLOW:
		# leave yellow when BOTH finished or safety timeout hits
		if (p1_yellow_done and p2_yellow_done) or phase_time_left <= 0.0:
			_start_next_phase()
	else:
		if phase_time_left <= 0.0:
			_start_next_phase()

func _start_next_phase():
	_start_phase(randi() % 3)

func _start_phase(new_phase: int) -> void:
	phase = new_phase as Phase
	target_dir = _random_dir()
	p1_prompt.call("show_arrow_color", target_dir, int(phase))
	p2_prompt.call("show_arrow_color", target_dir, int(phase))

	match phase:
		Phase.GREEN:
			phase_time_left = randf_range(6.0, 9.0)
			red_pop_time = 0.0
			audio.pitch_scale = 1.0
			p1_prompt.call("set_pop_visible", false)
			p2_prompt.call("set_pop_visible", false)
			
		Phase.RED:
			phase_time_left = randf_range(3.0, 5.0)
			red_pop_time = randf_range(0.4, 0.8)
			audio.pitch_scale = 0.8
			p1_prompt.call("set_pop_visible", false)
			p2_prompt.call("set_pop_visible", false)
			
		Phase.YELLOW:
			phase_time_left = YELLOW_TIMEOUT
			audio.pitch_scale = 1.25
			p1_yellow_done = false
			p2_yellow_done = false
			
			p1_seq = _make_seq(YELLOW_SEQ_LEN)
			p2_seq = _make_seq(YELLOW_SEQ_LEN)
			p1_seq_idx = 0
			p2_seq_idx = 0
			p1_prompt.call("show_sequence", p1_seq)
			p2_prompt.call("show_sequence", p2_seq)

func _end_round():
	audio.pitch_scale = 1.0
	round_active = false

	var winner := "Draw"
	if p1_progress > p2_progress:
		winner = (p1_name as Label).text if (p1_name is Label) else "Player 1"
	elif p2_progress > p1_progress:
		winner = (p2_name as Label).text if (p2_name is Label) else "Player 2"

	set_hud_visible(false)  # hide bars/prompts/names under the overlay
	if victory:
		victory.call("show_winner", winner)
		
func return_to_menu() -> void:
	round_active = false
	game_active = false
	_reset_match()
	set_hud_visible(false)
	if victory:
		(victory as CanvasItem).visible = false
	# Prefill last names in the menu (optional)
	var n1 := (p1_name as Label).text if (p1_name is Label) else ""
	var n2 := (p2_name as Label).text if (p2_name is Label) else ""
	if menu:
		if menu.has_method("show_menu"):
			menu.call("show_menu", n1, n2)
		else:
			(menu as CanvasItem).visible = true

				
func start_new_round() -> void:
	set_hud_visible(true)   # show bars/prompts/names again
	_reset_match()          # zero progress, clear boosts, etc.
	round_active = true
	_start_phase(Phase.GREEN)


func _reset_match():
	p1_progress = 0; p2_progress = 0
	p1_boost_time = 0; p2_boost_time = 0
	_start_phase(Phase.GREEN)

func _random_dir() -> String:
	var dirs = ["up","down","left","right"]
	return dirs[randi() % dirs.size()]

func _make_seq(n: int) -> Array[String]:
	var arr: Array[String] = []
	for i in n: arr.append(_random_dir())
	return arr

func on_player_tap(player: int, dir: String) -> void:
	if not game_active or not round_active:
		return
	match phase:
		Phase.GREEN:
			if dir == target_dir:
				var mult := BOOST_MULTI if ((player == 1 and p1_boost_time > 0) or (player == 2 and p2_boost_time > 0)) else 1.0
				_add_progress(player, GREEN_TICK * mult)
		Phase.RED:
			if red_pop_time > 0:
				_add_progress(player, -EARLY_PENALTY)
			elif dir == target_dir:
				_add_progress(player, RED_CHUNK)
				phase_time_left = 0.2
		Phase.YELLOW:
			if player == 1:
				if not p1_yellow_done:
					_advance_seq(1, dir)            # keeps p1_seq_idx updated + highlights
					if p1_seq_idx >= p1_seq.size():
						p1_yellow_done = true
						p1_boost_time = BOOST_DURATION
						p1_prompt.call("set_boost_visual", true)
						# ⬇️ flip ONLY P1 to GREEN while P2 still solves
						p1_prompt.call("show_arrow_color", target_dir, int(Phase.GREEN))
				else:
					# P1 already green; allow scoring during P2's yellow
					if dir == target_dir:
						var mult1 := BOOST_MULTI if p1_boost_time > 0.0 else 1.0
						_add_progress(1, GREEN_TICK * mult1)

			else: # player 2
				if not p2_yellow_done:
					_advance_seq(2, dir)
					if p2_seq_idx >= p2_seq.size():
						p2_yellow_done = true
						p2_boost_time = BOOST_DURATION
						p2_prompt.call("set_boost_visual", true)
						p2_prompt.call("show_arrow_color", target_dir, int(Phase.GREEN))
				else:
					if dir == target_dir:
						var mult2 := BOOST_MULTI if p2_boost_time > 0.0 else 1.0
						_add_progress(2, GREEN_TICK * mult2)

func _advance_seq(player: int, dir: String):
	if player == 1:
		# Guard: nothing to read or already finished
		if p1_seq.size() == 0 or p1_seq_idx >= p1_seq.size():
			return
		if dir == p1_seq[p1_seq_idx]:
			p1_seq_idx += 1
			p1_prompt.call("highlight_seq_index", p1_seq_idx)
			if p1_seq_idx >= p1_seq.size():
				p1_boost_time = BOOST_DURATION
				p1_prompt.call("set_boost_visual", true)
				#phase_time_left = min(phase_time_left, 0.5)  # wrap up yellow soon
		else:
			p1_seq_idx = 0
			p1_prompt.call("highlight_seq_index", 0)
	else:
		if p2_seq.size() == 0 or p2_seq_idx >= p2_seq.size():
			return
		if dir == p2_seq[p2_seq_idx]:
			p2_seq_idx += 1
			p2_prompt.call("highlight_seq_index", p2_seq_idx)
			if p2_seq_idx >= p2_seq.size():
				p2_boost_time = BOOST_DURATION
				p2_prompt.call("set_boost_visual", true)
				#phase_time_left = min(phase_time_left, 0.5)
		else:
			p2_seq_idx = 0
			p2_prompt.call("highlight_seq_index", 0)


func _add_progress(player: int, amount: float):
	if player == 1:
		p1_progress = clamp(p1_progress + amount, 0.0, 100.0)
	else:
		p2_progress = clamp(p2_progress + amount, 0.0, 100.0)
		
func _layout_ui() -> void:
	var vr := get_viewport().get_visible_rect()
	var vw: float = vr.size.x
	var vh: float = vr.size.y
	var pad: float = 16.0
	var gap: float = 10.0

	var bar_size := Vector2(350, 50)
	var prompt_size := Vector2(350, 48)

	var p1b := p1_bar as Control
	var p2b := p2_bar as Control
	var p1p := p1_prompt as Control
	var p2p := p2_prompt as Control

	# sizes
	p1b.size = bar_size
	p2b.size = bar_size
	p1p.size = prompt_size
	p2p.size = prompt_size

	# TOP row: bars (left/right)
	p1b.position = Vector2(pad, pad)
	p2b.position = Vector2(vw - bar_size.x - pad, pad)

	# SECOND row: prompts (under each bar, clearly separated)
	p1p.position = Vector2(pad, pad + bar_size.y + gap)
	p2p.position = Vector2(vw - prompt_size.x - pad, pad + bar_size.y + gap)

	# render prompts above bars
	p1p.z_index = 1
	p2p.z_index = 1

	# --- Bottom names (explicit positions; no bottom anchors) ---
	if p1_name and p2_name:
		var p1 := p1_name as Control
		var p2 := p2_name as Control

		# Measure text so the label has enough width
		var p1_size: Vector2 = p1.get_minimum_size()
		var p2_size: Vector2 = p2.get_minimum_size()
		var name_h: float = max(36.0, p1_size.y, p2_size.y)
		var p1_w: float = max(160.0, p1_size.x + 12.0)
		var p2_w: float = max(160.0, p2_size.x + 12.0)

		# Anchor both to TOP_LEFT and place them using the viewport size (vw, vh)
		p1.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
		p1.size = Vector2(p1_w, name_h)
		p1.position = Vector2(pad, vh - name_h - pad)  # bottom-left

		p2.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
		p2.size = Vector2(p2_w, name_h)
		p2.position = Vector2(vw - p2_w - pad, vh - name_h - pad)  # bottom-right

		(p1 as CanvasItem).z_index = 10
		(p2 as CanvasItem).z_index = 10
		if p2_name is Label:
			(p2_name as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	print("P1Name vis=", (p1_name as CanvasItem).visible, " pos=", (p1_name as Control).global_position)
	print("P2Name vis=", (p2_name as CanvasItem).visible, " pos=", (p2_name as Control).global_position)
