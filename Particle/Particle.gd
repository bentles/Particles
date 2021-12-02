extends RigidBody

# Declare member variables here.
var vel3 = Vector3.ZERO
export var fmass = 0.6

# maybe can make these asymmetric later if it makes things cooler
const cooldown_seconds = 0.3
var cooldown_elapsed_seconds = 0
const action_seconds = 0.2
var action_elapsed_seconds = action_seconds

const think_seconds = 0.1
var think_elapsed_seconds = think_seconds

const size_factor = 0.3;

# state
const State = { STATE_IDLE = 0, STATE_EXPANDING = 3, STATE_EXPANDED = 9, STATE_CONTRACTING = 6}
var state = State.STATE_IDLE

const NeuralNetwork = preload("../Neural Network/Brain.gd")
var brain: NeuralNetwork;

func _act(from_state, to_state):
	if state == from_state && cooldown_elapsed_seconds >= cooldown_seconds:
		state = to_state
		action_elapsed_seconds = 0
		cooldown_elapsed_seconds = 0

var total = 0
func _resize_model(delta):
	var percent = action_elapsed_seconds / action_seconds
	var size_state = 0
	
	if state == State.STATE_EXPANDED:
		size_state = 1
	elif state == State.STATE_IDLE:
		size_state = 0
	elif state == State.STATE_CONTRACTING:
		size_state = (1 - percent)
	elif state == State.STATE_EXPANDING:
		size_state = percent
		
	var size = 0.5 + size_factor * size_state
	# figure out how to scale properly
	total += delta
	#if (total < 3):
	#	$CollisionShape.shape.radius = total
	$Particles.scale.x = size
	$Particles.scale.y = size
	$Particles.scale.z = size
	$InfluenceArea/CollisionShape.shape.radius = size

func _expand():
	_act(State.STATE_IDLE, State.STATE_EXPANDING)
	$CollisionShape.shape.radius = 0.75
	

func _contract():
	_act(State.STATE_EXPANDED, State.STATE_CONTRACTING)
	$CollisionShape.shape.radius = 0.5

func _ready():
	assert(brain != null)
	pass
	
func _process_state(delta):
	# TODO: might need to think about order here
	if state == State.STATE_EXPANDING || state == State.STATE_CONTRACTING:
		action_elapsed_seconds += delta
		if action_elapsed_seconds >= action_seconds:
			action_elapsed_seconds = action_seconds
			state = State.STATE_IDLE if state == State.STATE_CONTRACTING else State.STATE_EXPANDED
		return
	if (state == State.STATE_IDLE || state == State.STATE_EXPANDED) && \
	cooldown_elapsed_seconds < cooldown_seconds:
		cooldown_elapsed_seconds += delta
		

func _physics_process(delta):
	_process_state(delta)
	_resize_model(delta)

	var overlapping = $InfluenceArea.get_overlapping_bodies()
	
	# assume for now all particles are the same mass so i just pick a
	# value for G*m1*m2	
	
	var gmm = 5.0
	
	var totalInstAcc = Vector3.ZERO;
	var totalActivation = Vector3.ZERO;
	
	for body in overlapping:
		for i in range(6):
			if body != self:
				# calculate forces from nearby particles
				var body3 = body.global_transform.origin
				var rsq = self.global_transform.origin.distance_squared_to(body3)
				var r3 = self.global_transform.origin.direction_to(body3)
				var acc3 = r3 * (gmm * body.fmass * self.fmass)/(rsq)
				totalInstAcc += acc3
				
				var act3 = r3.normalized()
				act3 = act3 * body.state
				totalActivation += act3
				
	self.add_central_force(totalInstAcc)
	
	think([
		state, 
		totalInstAcc.x, totalInstAcc.y, totalInstAcc.z, 
		totalActivation.x, totalActivation.y, totalActivation.z
	], delta)

#decide what action to perform (expand, contract or nothing)
func think(inputs: Array, delta: float):
	if think_elapsed_seconds < think_seconds:
		think_elapsed_seconds += delta
	else:
		think_elapsed_seconds = 0
		var outputs = brain.predict(inputs)
		# biggest output wins
		if outputs[0] > 0.75 && outputs[0] > outputs[1]: 
			_expand()
		if outputs[1] > 0.75:
			_contract()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


