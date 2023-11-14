extends Control

var VScroll
# Called when the node enters the scene tree for the first time.
func _compare(a, b):
	return a <= b

func _ready():
	var a = [1,2,3,4,5,6,7,8,8,8,8,8,9,9,9,10,10]
	var ind = a.bsearch_custom(8, _compare)
	print(a)
	print(ind)

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
	$MyWindow.popup_centered()

func _my_id_pressed(id):
	print("Pressed: ", str(id))
	$FileDialog.visible = true

var count = 0
func _scrolling():
	var x = VScroll.value
	count += 1
	print("Scroll " + str(count) + "   " + str(x))
