extends CanvasLayer

# Exported variables
@export var audio_folder: String = "res://assets/BA/Audios/Vocal/CN/scenario/vol.1/ch.1/ep.1"

# Member variables
@onready var balloon: Panel = %Balloon
@onready var character_label: Label = %CharacterName
@onready var subtitle_label: Label = %SubtitleLabel
@onready var dialogue_label: DialogueLabel = %DialogueLabel
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu
@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var arona: SpineCharacter = $Spine

var resource: Resource
var temporary_game_states: Array = []
var is_waiting_for_input: bool = false
var will_hide_balloon: bool = false

var mutation_cooldown: Timer = Timer.new()

var next_action: StringName = &"ui_accept"
var skip_action: StringName = &"ui_cancel"

var _locale: String = TranslationServer.get_locale()

var dialogue_line: DialogueLine:
	get: return dialogue_line
	set(value):
		is_waiting_for_input = false
		if value == null:
			queue_free()
			return
		dialogue_line = value
		apply_dialogue_line()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	balloon.hide()
	balloon.gui_input.connect(_on_balloon_gui_input)
	
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	# If the responses menu doesn't have a next action set, use this one
	responses_menu.response_selected.connect(_on_responses_menu_response_selected)
	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action
		
	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

	subtitle_label.text = ""
	
	JS.add_callback(arona.set_expression, "changeExpression")
	
# Handle unhandled input
func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	## Detect a change of locale and update the current dialogue line to show the new language
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_label):
		_locale = TranslationServer.get_locale()
		var visible_ratio = dialogue_label.visible_ratio
		self.dialogue_line = await resource.get_next_dialogue_line(dialogue_line.id)
		if visible_ratio < 1:
			dialogue_label.skip_typing()
			
# Handle GUI input
func _on_balloon_gui_input(event: InputEvent) -> void:
	# See if we need to skip typing of the dialogue
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	# When there are no response options the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)
		
#region Signals

func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()
		
func _on_mutated(_mutation: Dictionary) -> void:
	is_waiting_for_input = false
	will_hide_balloon = true
	mutation_cooldown.start(0.1)

func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)


# Start the dialogue
func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	resource = dialogue_resource
	self.dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)

## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()

	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	# Show our balloon
	balloon.show()
	will_hide_balloon = false

	set_character_expression()	

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	if dialogue_line.tags.size() > 0:
		for tag in dialogue_line.tags:
			print("Tag: ", tag)
			if tag.begins_with("audio"):
				var filename := dialogue_line.get_tag_value(tag)
				if filename == "":
					filename = tag.split(":")[1].strip_edges()
				print("Playing audio: ", audio_folder + "/" + filename)
				audio_player.stream = load(audio_folder + "/" + filename)
				audio_player.play()
				await audio_player.finished
#				play_audio(filename)
#			if tag.begins_with("mood"):
#				var mood := tag.split(":")[1].strip_edges()
#				print("Mood: ", mood)
#				spine.set_expression(mood)
		
#	await dialogue_label.finished_typing
	
	# Wait for input
	if dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
	elif dialogue_line.time != "":
		var time = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()


## Go to the next line
func next(next_id: String) -> void:
	self.dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)
	
func play_audio(filename: String) -> void:
	if audio_player.is_playing():
		await audio_player.finished
	audio_player.stream = load(audio_folder + "/" + filename)
	audio_player.play()

func set_character_expression():
	if dialogue_line.tags.size() > 0:
		for tag in dialogue_line.tags:
			if tag.begins_with("mood"):
				var mood := tag.split(":")[1].strip_edges()
				print("Mood: ", mood)
				arona.set_expression(mood)
	
#	var mood = dialogue_line.get_tag_value("mood")
#	spine.set_expression(mood)

func hide_arona():
	arona.visible = false