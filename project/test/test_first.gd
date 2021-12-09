extends "res://addons/gut/test.gd"

var sketchs =load("res://src/ui/sketch_select/SketchSelect.gd")
var entry =load("res://entry.gd")
var process = load("res://src//attachments//AnalogRaycast.gd")
var control =load("res://src/ui/sketch_control/ControlPane.gd")
var odo =load("res://src/utilities/sensors/odometer/Odometer.gd")
var SMCE = load("res://src//bind//SMCE.gd")

func test_signal():
#Checks for signal in the file , need to understand sender and receiver concept
	var sketchss= sketchs.new()
	assert_has_signal(sketchss,"exited")

#All required files to run SMCE and dependent UI code exits 
func test_filexists():
	var en =entry.new()
	assert_file_exists("res://gdnative/lib/SMCE.dll")
	assert_file_exists("res://share/config/smartcar_shield_board.json")

#Visualize function working 
func test_visualcontentisnotempty():
		var my_obj = process.new()
		var a = my_obj.visualize_content()
		var b = my_obj.visualize()
		assert_not_null(a)
		assert_not_null(b)

#Fail test case to check stimulator is working, failing as prev_pos is vector
func test_processandphysicsprocessworking():
	var my_obj = odo.new()
	add_child_autofree(my_obj)
	gut.simulate(my_obj,20, .1)
	gut.p('-- Failing --')
	assert_eq(my_obj._prev_pos,20)

#Input File Path found, Sketch class working
func test_controlpane():
	var con =preload("res://src/ui/sketch_control/ControlPane.gd")
	var controlp= con.new()
	var path = controlp.sketch_path
	assert_not_null(path)
	print(path)
	#check sketch provided, board is configured and sketch is attached
	#var result = controlp.init(Sketch,Toolchain).res
	#assert_not_null(result)
#	var attachsketch =controlp.attach_res
#	assert_not_null(attachsketch)
	#check the boardbutton is disabled if the sketch is not compiled
#	var status = controlp._toolchain.is_building()
#	if status != true:
#		var press_btn =controlp.pause_btn.disabled 
#		assert_eq(press_btn,"True")

#func test_setgetcheck():
#	#assert_setget(UltraSonic, 'max_angle',true)
#	var debug =load("res://src/ui/utilities/debug_canvas/DebugCanvas.tscn").instance()
#	assert_setget(debug,'disabled',true,false)
#	var cam =load("res://src/ui/utilities/controllable_camera/ControllableCamera.gd").new()
#	gut.p('-- Failing --')
#	_assert_setget_called(cam,'target','set_target','get_target')

func test_status():
	var smce = SMCE.new()
	var status = smce.Status
	var p_status=""
	for key in status:
		p_status = p_status+str(key)
	gut.p('-- passing --')
	assert_string_contains(p_status,'CLEAN')
	assert_string_contains(p_status,'CONFIGURED')
	assert_string_contains(p_status,'RUNNING')
	assert_string_contains(p_status,'SUSPENDED')
	assert_string_contains(p_status,'STOPPED')
	gut.p('-- Failing --')
	assert_string_contains(p_status,'PENDING')





