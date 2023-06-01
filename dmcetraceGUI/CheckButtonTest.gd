extends CheckButton


# Called when the node enters the scene tree for the first time.
func _ready():

	print ("SIZE: " + str(self.size))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.size.y = 10
	pass
