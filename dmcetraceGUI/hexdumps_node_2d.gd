extends Node2D

var VISIBLE_HEXDUMPS = 10
var tgui
var HDLabels = []
var lsettings = []
var count = 0
var HexdumpsPanelContainer
var HDLabelTemplate
var TraceGUI_scene
var Active = false
var inited = false
#var Active = true
#var inited = true
var MainWindowSize

# Called when the node enters the scene tree for the first time.
func _ready():
	HDLabelTemplate = get_node("HDLabelTemplate")
	var hdtmp = HDLabelTemplate.duplicate()
	hdtmp.visible = true
	for i in range (VISIBLE_HEXDUMPS):
		var lset = LabelSettings.new()
		lset.font_size = 32 - i
		lset.font_color = Color(1,1,1,float(1) / ((float(i) / 2) + 1))
		lsettings.append(lset)

	HDLabels.append(hdtmp)
	add_child(hdtmp)
	print("Hexdump viewer ready")

func init(node):
	tgui = node.TraceGuiSceneRef
	inited = true
	print("Hexdump support init done")

func Activate():
	Active = true

func _input(ev):
	if inited and Active:
		if ev is InputEventKey:
			if ev.pressed:
				if ev.keycode == KEY_ESCAPE:
					tgui.visible = true
					self.visible = false
					Active = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if inited and Active:
		MainWindowSize = get_tree().root.size
#		OS.delay_msec(100)
		count += 1
		if count == 10:
			count = 0

		self.visible = true
		HDLabels[0].visible = true
		HDLabels[0].label_settings = lsettings[count]
		HDLabels[0].text = "Hexdump!"
		HDLabels[0].position.x += count
		HDLabels[0].position.y += count
		if HDLabels[0].position.x > 1200:
			HDLabels[0].position.x = 0
			HDLabels[0].position.y = 0
