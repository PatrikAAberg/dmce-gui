extends Node2D

var VISIBLE_HEXDUMPS = 10
var tgui
var inited = false
var HDLabels = []
var lsettings = []
var count = 0
var HexdumpsPanelContainer
var HDLabelTemplate
var TraceGUI_scene
var active = false

# Called when the node enters the scene tree for the first time.
func _ready():
	HDLabelTemplate = get_node("HexdumpsPanelContainer/HDLabelTemplate")
	HexdumpsPanelContainer = get_node("HexdumpsPanelContainer")
	var hdtmp = HDLabelTemplate.duplicate()
	hdtmp.visible = true
	for i in range (VISIBLE_HEXDUMPS):
		var lset = LabelSettings.new()
		lset.font_size = 32 - i
		lset.font_color = Color(1,1,1,float(1) / ((float(i) / 2) + 1))
		lsettings.append(lset)

	HDLabels.append(hdtmp)
	add_child(hdtmp)
	init(null)
	print("Hexdump ready")

func init(node):
	tgui = node
	inited = true
	print("Hexdump support init done")

func _input(ev):
	if inited and active:
		if ev is InputEventKey:
			if ev.pressed:
				if ev.keycode == KEY_ESCAPE:
					self.visible = false
					tgui.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if inited and active:
		var appsize = get_tree().root.size
		var apppos = Vector2(0,0)
		HexdumpsPanelContainer.size = appsize
		HexdumpsPanelContainer.position = apppos

#		OS.delay_msec(100)
		count += 1
		if count == 10:
			count = 0
		HDLabels[0].label_settings = lsettings[count]
		HDLabels[0].text = "Hexdump!"
		HDLabels[0].position.x += count
		HDLabels[0].position.y += count
		if HDLabels[0].position.x > 1200:
			HDLabels[0].position.x = 0
			HDLabels[0].position.y = 0
