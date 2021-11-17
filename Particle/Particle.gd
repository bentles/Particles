extends RigidBody

# Declare member variables here.
var vel3 = Vector3.ZERO
export var fmass = 1.4

# maybe can make these asymmetric later if it makes things cooler
const cooldown_seconds = 0.5
var cooldown_elapsed_seconds = 0
const action_seconds = 0.2
var action_elapsed_seconds = action_seconds

const size_factor = 0.25;

const State = { STATE_IDLE = 0, STATE_EXPANDING = 1, STATE_EXPANDED = 3, STATE_CONTRACTING = 2}

var state = State.STATE_IDLE

func _act(from_state, to_state):
	if state == from_state && cooldown_elapsed_seconds >= cooldown_seconds:
		state = to_state
		action_elapsed_seconds = 0
		cooldown_elapsed_seconds = 0
		
func _resize_model():
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
	
	$CollisionShape.shape.radius = size
	$Body.radius = size
	$InfluenceArea/CollisionShape.shape.radius = size

func _expand():
	_act(State.STATE_IDLE, State.STATE_EXPANDING)

func _contract():
	_act(State.STATE_EXPANDED, State.STATE_CONTRACTING)

const NN = preload("./ParticleBrain.gd")

func _ready():
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

	var overlapping = $InfluenceArea.get_overlapping_bodies()
	
	var pos = self.global_transform.origin

	var directions = [ \
		Vector3(1,0,0), Vector3(-1,0,0), \
		Vector3(0,1,0), Vector3(0,-1,0), \
		Vector3(0,0,1), Vector3(0,0,-1), \
	]
	
	# assume for now all particles are the same mass so i just pick a
	# value for G*m1*m2	
	
	var gmm = 5.0
	
	var totalInstAcc = Vector3.ZERO;
	
	var nearby_particles = [ 0, 0, 0, 0, 0, 0 ]

	for body in overlapping:
		for i in range(6):
			if body != self:
				var body3 = body.global_transform.origin

				var rsq = self.global_transform.origin.distance_squared_to(body3)
				var r3 = self.global_transform.origin.direction_to(body3)
				
				var dot_prod = directions[i].dot(r3)
				dot_prod = 0 if dot_prod < 0 else dot_prod
				
				nearby_particles[i] += dot_prod
				
				var acc3 = r3 * (gmm * body.fmass * self.fmass)/(rsq)

				totalInstAcc += acc3
	self.add_central_force(totalInstAcc)
	

var rand_time = 0;
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	_resize_model()


