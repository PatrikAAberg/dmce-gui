extends Node2D

var SCROLL_VISIBLE_HEXDUMPS = 10
var SLIDER_VISIBLE_HEXDUMPS = 3
var HEXDUMP_WIDTH = 80
var tgui
var hexdump
var HDLabels = []
var HDLabelsText = []
var lsettings = []
var count = 0
var HexdumpsPanelContainer
var HDLabelTemplate
var TraceGUI_scene
var Active = false
var Inited = false
var MainWindowSize
var index
var yoffset = 0
var font_height
var font_width
var NumHexdumps = 0
var HexDumpMaxLines

func _draw():
	MainWindowSize = hexdump.MainWindowSize
	draw_rect(Rect2(0,0, MainWindowSize.x, MainWindowSize.y), Color(0.1, 0.1, 0.1, 1.0), true)

func scroll_set():
	if yoffset < -((HexDumpMaxLines) * font_height):
		yoffset = -(HexDumpMaxLines) * font_height
	elif yoffset > 0:
		yoffset = 0
	for hdl in HDLabels:
		hdl.position.y = yoffset

func scroll_up():
	yoffset -= font_height
	scroll_set()

func scroll_down():
	yoffset += font_height
	scroll_set()

func scroll_page_up():
	yoffset -= font_height * 20
	scroll_set()

func scroll_page_down():
	yoffset += font_height * 20
	scroll_set()

func PopulateScreen():
	for i in range(SLIDER_VISIBLE_HEXDUMPS):
		if index - 1 + i >= 0:
			HDLabels[i].text = HDLabelsText[index - 1 + i]
		HDLabels[i].visible = false

	HDLabels[1].visible = true
	if index > 0:
		HDLabels[0].visible = true
	if index < NumHexdumps - 1:
		HDLabels[2].visible = true
	queue_redraw()

# Called when the node enters the scene tree for the first time.
func _ready():
	HDLabelTemplate = get_node("../../../HDLabelTemplate")
	font_height = HDLabelTemplate.size.y
	font_width = HDLabelTemplate.size.x / 10

	var lsetmain = LabelSettings.new()
	lsetmain.font_color = Color(0.9, 0.9, 0.9, 1.0)

	var xpos = 100
	for i in range(SLIDER_VISIBLE_HEXDUMPS):
		var hdtmp = HDLabelTemplate.duplicate()
		hdtmp.position.x = xpos
		hdtmp.visible = true
		hdtmp.label_settings = lsetmain
		xpos += font_width * HEXDUMP_WIDTH
		add_child(hdtmp)
		HDLabels.append(hdtmp)

	for i in range (SCROLL_VISIBLE_HEXDUMPS):
		var lset = LabelSettings.new()
		lset.font_size = 32 - i
		lset.font_color = Color(1,1,1,float(1) / ((float(i) / 2) + 1))
		lsettings.append(lset)

	print("Hexdump viewer ready")

func Load():
	NumHexdumps = len(tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex)
	HexDumpMaxLines = 0

	for i in range(NumHexdumps):
		var hdtmp = HDLabelTemplate.duplicate()
		hdtmp.visible = false
		var tl = tgui.Trace[tgui.TActive].HexDumpTraceEntry[tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex[i]]
		var s =     "Hexdump:    " + str(i)
		s += "\n" + "Core:       " + str(tl[0])
		s += "\n" + "Timestamp:  " + str(tl[1])
		s += "\n" + "File/line:  " + str(tl[2]) + str(tl[3])
		s += "\n" + "Function:   " + str(tl[4])
		s += "\n"
		s += "\n" + tgui.Trace[tgui.TActive].HexDump[tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex[i]]
		HDLabelsText.append(s)
		if HexDumpMaxLines < s.count("\n"):
			HexDumpMaxLines = s.count("\n")
	index = 0
	if NumHexdumps > 0:
		index = 1
	PopulateScreen()

func init(node):
	tgui = node.TraceGuiSceneRef
	hexdump = node.HexdumpSceneRef

	Inited = true
	print("Hexdump support init done")

func Activate():
	Active = true

func _input(ev):
	if Inited and Active:
		if ev is InputEventKey:
			if ev.pressed:
				if ev.keycode == KEY_ESCAPE:
					tgui.visible = true
					self.visible = false
					Active = false
					tgui.Activate()
					return
				if ev.keycode == KEY_UP:
					scroll_down()
					return
				if ev.keycode == KEY_DOWN:
					scroll_up()
					return
				if ev.keycode == KEY_PAGEUP:
					scroll_page_down()
					return
				if ev.keycode == KEY_PAGEDOWN:
					scroll_page_up()
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
	if Inited and Active:
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
