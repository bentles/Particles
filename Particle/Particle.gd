extends RigidBody

# Declare member variables here.
var vel3 = Vector3.ZERO
export var fmass = 1

# maybe can make these asymmetric later if it makes things cooler
const cooldown_seconds = 0.5
var cooldown_elapsed_seconds = cooldown_seconds
const action_seconds = 0.5
var action_elapsed_seconds = action_seconds

const size_factor = 0.5;

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
		
	var size = 1 + size_factor * size_state
	# figure out how to scale properly

func _expand():
	_act(State.STATE_IDLE, State.STATE_EXPANDING)

func _contract():
	_act(State.STATE_EXPANDED, State.STATE_CONTRACTING)

# var rng = RandomNumberGenerator.new()
# Called when the node enters the scene tree for the first time.
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

var rand_time = 0;
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	_process_state(delta)
	
	_resize_model()
	
	
	
	# assume for now all particles are the same mass so i just pick a
	# value for G*m1*m2
	
	
	var gmm = 5.0
	
	var overlapping = $InfluenceArea.get_overlapping_bodies()	
	var totalInstAcc = Vector3.ZERO;

	for body in overlapping:
		if body != self: #not myself lol
			var bodylist = [body.global_transform.origin]
			if body.is_in_group("Muscle"):
				bodylist = body.get_offsets()
				for body3 in bodylist:
					var rsq = self.global_transform.origin.distance_squared_to(body3)
					var r3 = self.global_transform.origin.direction_to(body3)

					var acc3 = r3 * (body.fmass * self.fmass)/(rsq)
					totalInstAcc -= acc3 #repel the middle of the muscle

			var biggestEffect = Vector3.ZERO
			for body3 in bodylist:
				var rsq = self.global_transform.origin.distance_squared_to(body3)
				var r3 = self.global_transform.origin.direction_to(body3)
				var acc3 = r3 * (gmm * body.fmass * self.fmass)/(rsq)
				if acc3.length_squared() > biggestEffect.length_squared():
					biggestEffect = acc3

			totalInstAcc += biggestEffect
	self.add_central_force(totalInstAcc)
	


