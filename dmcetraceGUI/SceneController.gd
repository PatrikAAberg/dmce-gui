extends Control

var HexdumpSceneRef
var TraceGuiSceneRef

# Called when the node enters the scene tree for the first time.
func _ready():
	HexdumpSceneRef = preload("res://hexdumps_node_2d.tscn").instantiate()
	add_child(HexdumpSceneRef)
	HexdumpSceneRef.visible = false

	TraceGuiSceneRef = preload("res://TraceGUI.tscn").instantiate()
	add_child(TraceGuiSceneRef)
	TraceGuiSceneRef.visible = false

	HexdumpSceneRef.init(self)
	TraceGuiSceneRef.init(self)

	TraceGuiSceneRef.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
