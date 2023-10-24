extends Node2D

var SCROLL_VISIBLE_HEXDUMPS = 10
var SLIDER_VISIBLE_HEXDUMPS = 5
var HEXDUMP_WIDTH = 80
var HexdumpWidthPixels
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
var indexwanted
var yoffset = 0
var xscrolloffset = 0
var FontHeight
var FontWidth
var NumHexdumps = 0
var HexDumpMaxLines
var HexdumpScrollBar

func _draw():
	MainWindowSize = hexdump.MainWindowSize
	draw_rect(Rect2(-MainWindowSize.x,0, MainWindowSize.x * 3, MainWindowSize.y), Color(0.1, 0.1, 0.1, 1.0), true)

func scroll_set():
	if yoffset < -((HexDumpMaxLines) * FontHeight):
		yoffset = -(HexDumpMaxLines) * FontHeight
	elif yoffset > 0:
		yoffset = 0
	for hdl in HDLabels:
		hdl.position.y = yoffset

func scroll_up():
	yoffset -= FontHeight
	scroll_set()

func scroll_down():
	yoffset += FontHeight
	scroll_set()

func scroll_page_up():
	yoffset -= FontHeight * 20
	scroll_set()

func scroll_page_down():
	yoffset += FontHeight * 20
	scroll_set()

func PopulateScreen():
	for i in range(SLIDER_VISIBLE_HEXDUMPS):
		var tindex = index - 2 + i
		if tindex >= 0 and tindex < len(HDLabelsText):
			HDLabels[i].text = HDLabelsText[index - 2 + i]
		else:
			HDLabels[i].text = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	HDLabelTemplate = get_node("../../../HDLabelTemplate")
	HexdumpScrollBar = get_node("../../ControlPanelContainer/HexdumpHScrollBar")
	HexdumpScrollBar.value_changed.connect(self._value_changed)

	FontHeight = HDLabelTemplate.size.y
	FontWidth = HDLabelTemplate.size.x / 10

	var lsetmain = LabelSettings.new()
	lsetmain.font_color = Color(0.9, 0.9, 0.9, 1.0)

	HexdumpWidthPixels = FontWidth * HEXDUMP_WIDTH

	var xpos = 100 - HexdumpWidthPixels
	for i in range(SLIDER_VISIBLE_HEXDUMPS):
		var hdtmp = HDLabelTemplate.duplicate()
		hdtmp.position.x = xpos
		hdtmp.visible = true
		hdtmp.label_settings = lsetmain
		xpos += HexdumpWidthPixels
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

	index = 10
	indexwanted = index
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
					hexdump.visible = false
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
					indexwanted -= 1
					if indexwanted < 0:
						indexwanted = 0
					return
				if ev.keycode == KEY_RIGHT:
					indexwanted += 1
					if indexwanted >= NumHexdumps - 1:
						indexwanted = NumHexdumps - 1
					return

func _process(delta):
	if index != indexwanted:
		if indexwanted > index:
			# scrolling right
			if xscrolloffset <= 0:
				xscrolloffset = HexdumpWidthPixels
			xscrolloffset -= FontWidth * 8
			if xscrolloffset <= 0:
				index += 1
				PopulateScreen()
				xscrolloffset = 0
				self.position.x = xscrolloffset
			else:
				self.position.x = 0 - (HexdumpWidthPixels - xscrolloffset)
		else:
			# scrolling left
			if xscrolloffset <= 0:
				xscrolloffset = HexdumpWidthPixels
			xscrolloffset -= FontWidth * 8
			if xscrolloffset <= 0:
				index -= 1
				PopulateScreen()
				xscrolloffset = 0
				self.position.x = -xscrolloffset
			else:
				self.position.x = 0 + (HexdumpWidthPixels - xscrolloffset)

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
