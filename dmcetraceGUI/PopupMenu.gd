extends PopupMenu


# Called when the node enters the scene tree for the first time.
func _ready():
	$Button.connect("pressed", self, "on_button_pressed")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func on_button_pressed():
	print("Button pressed!")
