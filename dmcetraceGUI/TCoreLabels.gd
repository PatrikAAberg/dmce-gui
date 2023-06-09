extends Node2D

var FChart
var tgui

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _draw():
	pass

func Init(node):
	for n in self.get_children():
		n.queue_free()
	tgui = node
	var i = 0
	for core in tgui.Trace[tgui.TActive].CoreList:
		var clab = Label.new()
		clab.position.y = i * tgui.CORE_KORV_HEIGHT
		clab.text = "Core " + str(core)
		var lsettings = LabelSettings.new()
		lsettings.font_size = tgui.CORE_KORV_HEIGHT - 2
		clab.label_settings = lsettings
		add_child(clab)
		i += 1
	print("TCorelabels for trace " + str(tgui.TActive) + " init done")

func MouseLeftPressed():
	tgui.FChart.AddCore(int(get_local_mouse_position().y / tgui.CORE_KORV_HEIGHT), tgui.TActive)
	tgui.UpdateTimeLine()
