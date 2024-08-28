extends Node2D

@onready var spineSprite = $SpineSprite


# Called when the node enters the scene tree for the first time.
func _ready():
	spineSprite.get_animation_state().set_animation("25");


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
 