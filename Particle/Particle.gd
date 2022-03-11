extends RigidBody

# physical properties:
var vel3 = Vector3.ZERO
export var fmass = 3.5
export var is_dead = false
var hp = 50
var max_hp = 100 
var age = 0
var gen = 1
var target: Spatial

# action timers and state:
var spawn_time = 0
const spawn_cooldown = 0.5
const cooldown_seconds = 0.13
var cooldown_elapsed_seconds = 0
const action_seconds = 0.13
var action_elapsed_seconds = action_seconds

const think_seconds = 0.1
var think_elapsed_seconds = think_seconds

var shared_thoughts = [0,0,0]

var original_size = 0.5
const size_factor = 0.3

const State = { STATE_IDLE = 0, STATE_EXPANDING = 3, STATE_CONTRACTING = 6, STATE_EXPANDED = 9 }
var state = State.STATE_IDLE

# parent-given properties:
const NeuralNetwork = preload("res://Neural Network/Brain.gd")
var brain: NeuralNetwork
var spawn_brain: NeuralNetwork
var parent
var material: SpatialMaterial

func _init():
	pass

func _ready():
	assert(brain != null)
	assert(spawn_brain != null)
	randomize()

func get_size() -> float:
	var a = $CollisionShape
	return $CollisionShape.scale.x

func set_material():
	var color = lerp(Color.red, Color.green, hp/max_hp)
	$Particles.material_override.albedo_color = color


func set_target(t: Spatial):
	target = t
	
func set_collision_layer(layer):
	self.set_collision_layer_bit(layer, true)
	self.set_collision_mask_bit(layer, true)
	$InfluenceArea.set_collision_layer_bit(layer, true)
	$InfluenceArea.set_collision_mask_bit(layer, true)
	
func _set_size(size):
	$InfluenceArea.scale.x = size
	$InfluenceArea.scale.y = size
	$InfluenceArea.scale.z = size
	$CollisionShape.scale.x = size
	$CollisionShape.scale.y = size
	$CollisionShape.scale.z = size
	$Particles.scale.x = size
	$Particles.scale.y = size
	$Particles.scale.z = size

func _expand():
	_act(State.STATE_IDLE, State.STATE_EXPANDING)

func _contract():
	_act(State.STATE_EXPANDED, State.STATE_CONTRACTING)
	
func _act(from_state, to_state):
	if state == from_state && cooldown_elapsed_seconds >= cooldown_seconds:
		_set_size(original_size + size_factor / 2.0)
		state = to_state
		action_elapsed_seconds = 0
		cooldown_elapsed_seconds = 0

func _process_state(delta):
	age += delta
	spawn_time += delta
	
	# TODO: might need to think about order here
	if state == State.STATE_EXPANDING || state == State.STATE_CONTRACTING:
		action_elapsed_seconds += delta
		if action_elapsed_seconds >= action_seconds:
			action_elapsed_seconds = action_seconds
			state = State.STATE_IDLE if state == State.STATE_CONTRACTING else State.STATE_EXPANDED
			_set_size(original_size if state == State.STATE_IDLE else original_size + size_factor)
		return
	if (state == State.STATE_IDLE || state == State.STATE_EXPANDED) && \
	cooldown_elapsed_seconds < cooldown_seconds:
		cooldown_elapsed_seconds += delta

func _physics_process(delta):
	if is_dead:
		return

	_process_state(delta)
	
	
	
	var a = $Particles.draw_pass_1

	var overlapping = $InfluenceArea.get_overlapping_bodies()
	var g = 5.0
	
	var totalInstAcc = Vector3.ZERO
	var totalActivation = Vector3.ZERO
	var length = target.global_transform.origin.distance_squared_to(self.global_transform.origin)
	
	var relative_distance = 0
	var total_distance = 0
	
	var shared_thoughts_input = [0,0,0]
	
	for body in overlapping:
		if body != self:
			#get shared thoughts
			for n in 3:
				shared_thoughts_input[n] += body.shared_thoughts[n]
				
			# calculate forces from nearby particles
			var body3 = body.global_transform.origin
			
			# make the forces independent of particle size  
			var distance_offset = 2 * original_size - get_size() - body.get_size()
			var distance = self.global_transform.origin.distance_to(body3)
			
			total_distance += target.global_transform.origin.distance_squared_to(body.global_transform.origin)
			
			# enforce 0.5^2 as the closest 2 particles can be
			var rsq = max(0.25, pow(distance + distance_offset, 2))
			var r3 = self.global_transform.origin.direction_to(body3)
			
			var acc3 = r3 * ((g * body.fmass * self.fmass)/(rsq)) 
			totalInstAcc += acc3
			
			var act3 = r3.normalized()
			act3 = act3 * body.state
			totalActivation += act3
			
	if (overlapping.size() - 1 > 0):
		var aveLength = total_distance/(overlapping.size() - 1)
		relative_distance = length - aveLength
		if relative_distance < 0:
			pass

	self.add_central_force(totalInstAcc)
	
	think(
	[   state,
		#share info but don't  create infinite loops
		shared_thoughts_input[0] / 20, shared_thoughts_input[1]/20, shared_thoughts_input[2]/20,
		relative_distance,
		totalInstAcc.length(),
		totalActivation
		 ], 
	[   state,
		0,0,0,
		age, parent.hp, gen ],
	delta)

#decide what action to perform (expand, contract or nothing)
func think(inputs: Array, sb_inputs: Array, delta: float):
	if think_elapsed_seconds < think_seconds:
		think_elapsed_seconds += delta
	else:
		think_elapsed_seconds = 0
		var outputs = brain.predict(inputs)
		# biggest output wins
		if outputs[0] > 0.75:
			_expand()
		if outputs[0] < 0.25:
			_contract()
			
		shared_thoughts = outputs.slice(1, 3, 1, true)
			
		var spawn_outputs = spawn_brain.predict(sb_inputs)
		
		# spawn new particle if this fires
		#if spawn_outputs[0] > 0.75 && spawn_time > spawn_cooldown:
		#	parent.spawn_at_child(self, 
		#	(spawn_outputs[1] - 0.5) / 3,
		#	(spawn_outputs[2] - 0.5) / 3,
		#	(spawn_outputs[3] - 0.5) / 3, gen + 1)
		#	spawn_time = 0
			
func kill():
	is_dead = true
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	set_material()
	pass


