class_name JS extends Node

static var godot: JavaScriptObject # JavaScript Bridge
static var callbacks: Dictionary[String, JavaScriptObject] = {}

static func _static_init():
	if not OS.has_feature("web"):
		print("JavaScript is not supported on this platform.")
		return

	JavaScriptBridge.eval("""
if (godot == undefined)
	var godot = {};
""", true)

	godot = JavaScriptBridge.get_interface("godot")
	print("[JS] Godot bridge initialized.")

static func add_callback(function: Callable, js_name: String = "") -> void:
	if js_name in callbacks:
		print("[JS] Callback already exists.")
		return
		
	var callback_ref: JavaScriptObject = JavaScriptBridge.create_callback(function.callv)
	if callback_ref == null:
		print("[JS] Failed to create callback.")
		return

	if js_name.is_empty():
		js_name = function.get_method().get_basename()		

	callbacks[js_name] = callback_ref
	godot.set(js_name, callback_ref)

static func remove_callback(js_name: String) -> void:
	if js_name in callbacks:
		godot.set(js_name, null)
		callbacks[js_name].free()
		callbacks.erase(js_name)
	else:
		print("[JS] Callback not found.")
