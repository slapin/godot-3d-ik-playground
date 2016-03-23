
extends Spatial

# member variables here, example:
# var a=2
# var b="textvar"
onready var skeleton = get_node("arm/arm/Skeleton")
var ik_bone = "lowerarm.R"
var ik_bone_no
var ik_cube
var tail_bone
var tail_cube
var ik_target

func put_cube(v):
	var c = TestCube.new()
	c.set_scale(Vector3(0.01, 0.01, 0.01))
	c.set_translation(v)
	add_child(c)
	return c

var bones = []
func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	put_cube(skeleton.get_global_transform().origin)
	for l in range(0, skeleton.get_bone_count()):
		var t = skeleton.get_bone_global_pose(l)
		put_cube(t.origin)
	ik_bone_no = skeleton.find_bone(ik_bone)
	var ik_material = FixedMaterial.new()
	ik_material.set_flag(ik_material.FLAG_ONTOP, true)
	ik_material.set_parameter(ik_material.PARAM_DIFFUSE, Color(0.0, 0.0, 0.0))
	print(ik_bone_no)
	ik_cube = put_cube(skeleton.get_bone_global_pose(ik_bone_no).origin + skeleton.get_translation())
	ik_cube.set_material_override(ik_material)
	tail_bone = -1
	for l in range(0, skeleton.get_bone_count()):
		if skeleton.get_bone_parent(l) == ik_bone_no:
			tail_bone = l
	var t = skeleton.get_bone_global_pose(tail_bone)
	tail_cube = put_cube(t.origin)
	tail_cube.set_material_override(ik_material)
	ik_target = put_cube(Vector3())
	var cur_bone = ik_bone_no
	var chain_size = 2
	while true:
		bones.push_back(cur_bone)
		cur_bone = skeleton.get_bone_parent(cur_bone)
		chain_size -= 1
		if cur_bone < 0 or chain_size <= 0:
			break
			
	
	set_process(true)

var reached = false
func _process(dt):
	if Input.is_action_pressed("arm_left"):
		skeleton.set_translation(skeleton.get_translation() + Vector3(-0.5 * dt, 0.0, 0.0))
	elif Input.is_action_pressed("arm_right"):
		skeleton.set_translation(skeleton.get_translation() + Vector3(0.5 * dt, 0.0, 0.0))
	ik_cube.set_translation(skeleton.get_bone_global_pose(ik_bone_no).origin + skeleton.get_translation())
	tail_cube.set_translation(skeleton.get_bone_global_pose(tail_bone).origin + skeleton.get_translation())
	if Input.is_action_pressed("target_left"):
		ik_target.set_translation(ik_target.get_translation() + Vector3(-0.5 * dt, 0.0, 0.0))
	elif Input.is_action_pressed("target_right"):
		ik_target.set_translation(ik_target.get_translation() + Vector3(0.5 * dt, 0.0, 0.0))
	if Input.is_action_pressed("target_up"):
		ik_target.set_translation(ik_target.get_translation() + Vector3(0.0, 0.5 * dt, 0.0))
	elif Input.is_action_pressed("target_down"):
		ik_target.set_translation(ik_target.get_translation() + Vector3(0.0, -0.5 * dt, 0.0))
	var to = ik_target.get_translation()
	var chain_count = 2
	var count = 20 * chain_count
	var precision = 0.001
	for hum in range(30):
		var depth = 0
		var olderr = 1000.0
		var psign = 1.0
		for cur_bone in bones:
			var d = skeleton.get_bone_global_pose(tail_bone).origin
			var rg = to
			var err = d.distance_squared_to(rg)
			if err < precision or count <= 0:
				if not reached and err < precision:
					print("Complete")
					reached = true
				break
			else:
				if reached:
					reached = false
					print("Lost contact")
			print("err: ", err)
			if err > olderr:
				psign = -psign
			var mod = skeleton.get_bone_global_pose(cur_bone)
			var q1 = Quat(mod.basis).normalized()
			var mod2 = mod.looking_at(to, Vector3(0.0, 1.0, 0.0))
			var q2 = Quat(mod2.basis).normalized()
			if psign < 0:
				q2 = q2.inverted()
			var q = q1.slerp(q2, 0.2 / (1.0 + 500.0 * depth)).normalized()
			var fin = Transform(q)
			fin.origin = mod.origin
			skeleton.set_bone_global_pose(cur_bone, fin)
			depth = depth + 1
		if reached:
			break


