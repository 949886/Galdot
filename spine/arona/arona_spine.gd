class_name SpineCharacter extends Node2D

# Enums for the expressions of Arona
enum AronaExpressions {
	NORMAL = 1,
	DISTRACTED = 2,
	SMILE = 3,
	PANIC = 4,
	ANGRY = 5,
	HUMILIATED = 6,
	DONBIKI = 7,
	SIGH = 10,
	HAPPY = 11,
}

const expression_map : Dictionary[String, int] = {
	"": AronaExpressions.NORMAL,
	"normal": AronaExpressions.NORMAL,
	"o": AronaExpressions.DISTRACTED,
	"smile": AronaExpressions.SMILE,
	"embarrassed": 4,
	"angry": AronaExpressions.ANGRY,
	"humiliated": AronaExpressions.HUMILIATED,
	"donbiki": AronaExpressions.DONBIKI,
	"osorosiko": 9,
	"sigh": AronaExpressions.SIGH,
	"happy": AronaExpressions.HAPPY,
	"> <": 12,
	"- -": 13,
	">_<": 18,
	"ehehe": 23,
	"-o-": 24,
	"star": 25,
	"pop": 26,
	"p_p": 27,
	"o_o":28,
	"@ @":30,
}

@onready var spineSprite: SpineSprite = $SpineSprite

var state: SpineAnimationState:
	get: return spineSprite.get_animation_state()

# Called when the node enters the scene tree for the first time.
func _ready():
#	spineSprite.get_animation_state().set_animation("Idle_01");
#	spineSprite.get_animation_state().set_animation("25");
	state.set_animation("Idle_01", true, 0)
#	state.set_animation("05", true, 1)
#	set_expression(AronaExpressions.HAPPY)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
 
func set_expression(expression) -> void:
	if expression is String:
		if expression in expression_map:
			expression = expression_map[expression]
		else:
			print("[SpineCharacter] Invalid expression name: ", expression)
			return
	state.set_animation("%02d" % expression, true, 1)
	
