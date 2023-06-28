extends Control

var VScroll
# Called when the node enters the scene tree for the first time.
func _ready():
	$Button.pressed.connect(self._my_pressed)
	$MenuBar/PopupMenu.id_pressed.connect(self._my_id_pressed)
	$LineEdit.text_submitted.connect(self._find_text_submitted)
	$FileDialog.size = Vector2(500,500)
	VScroll = get_node("VScrollBar")
	VScroll.scrolling.connect(self._scrolling)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _find_text_submitted(text):
	print(text)

func _my_pressed():
	print("Button pressed ")
#	$AcceptDialog.popup_centered()
	get_node("../Background").visible=true
	self.visible = false

func _my_id_pressed(id):
	print("Pressed: ", str(id))
	$FileDialog.visible = true

var count = 0
func _scrolling():
	var x = VScroll.value
	count += 1
	print("Scroll " + str(count) + "   " + str(x))
