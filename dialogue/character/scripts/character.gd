extends Resource
class_name Character

@export var id: int
@export var name: String = ""
@export var orgnization: String = ""
@export var image: Texture = null
@export var list: Array[String] = []
@export var texs: Array[Texture] = []

func _init(p_name = ""):
	name = p_name
