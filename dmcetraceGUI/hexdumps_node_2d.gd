extends Node2D

var SCROLL_VISIBLE_HEXDUMPS = 10
var SLIDER_VISIBLE_HEXDUMPS = 3
var HEXDUMP_WIDTH = 80
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
var index = 1
var yoffset = 0
var font_height
var font_width

func ClearScreen():
	for hdl in HDLabels:
		hdl.visible = false
	queue_redraw()

func _draw():
	MainWindowSize = get_tree().root.size
	draw_rect(Rect2(0,0, MainWindowSize.x, MainWindowSize.y), Color(0.15, 0.15, 0.15, 1.0), true)

func scroll_up():
	yoffset -= font_height
	for hdl in HDLabels:
		hdl.position.y = yoffset

func scroll_down():
	yoffset += font_height
	for hdl in HDLabels:
		hdl.position.y = yoffset

func PopulateScreen():
	var sindex = index - (SLIDER_VISIBLE_HEXDUMPS / 2)
	var xpos = 100
	var ypos = 100
	for i in range(SLIDER_VISIBLE_HEXDUMPS):
		if sindex >= 0:
			HDLabels[sindex].position.x = xpos
			HDLabels[sindex].position.y = ypos + yoffset
			HDLabels[sindex].visible = true
		sindex += 1
		xpos += font_width * HEXDUMP_WIDTH

# Called when the node enters the scene tree for the first time.
func _ready():
	HDLabelTemplate = get_node("HDLabelTemplate")
	font_height = HDLabelTemplate.size.y
	font_width = HDLabelTemplate.size.x / 10
	for i in range (SCROLL_VISIBLE_HEXDUMPS):
		var lset = LabelSettings.new()
		lset.font_size = 32 - i
		lset.font_color = Color(1,1,1,float(1) / ((float(i) / 2) + 1))
		lsettings.append(lset)

	print("Hexdump viewer ready")

func Load():
	for i in range(len(tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex)):
		var hdtmp = HDLabelTemplate.duplicate()
		hdtmp.visible = false
		var s = " ".join(tgui.Trace[tgui.TActive].HexDumpTraceEntry[tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex[i]])
		s += "\n" + tgui.Trace[tgui.TActive].HexDump[tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex[i]]
		hdtmp.text = s
		HDLabels.append(hdtmp)
		add_child(hdtmp)
	ClearScreen()
	PopulateScreen()

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
				if ev.keycode == KEY_UP:
					scroll_up()
					return
				if ev.keycode == KEY_DOWN:
					scroll_down()
					return
				if ev.keycode == KEY_LEFT:
					index -= 1
					if index < 0:
						index = 0
					PopulateScreen()
					return
				if ev.keycode == KEY_RIGHT:
					index += 1
					if index >= NumHexdumps - 1:
						index = NumHexdumps - 1
					PopulateScreen()
					return

func _process(delta):
	pass

func _processflash(delta):
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
