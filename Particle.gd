extends RigidBody

# Declare member variables here. Examples:
var vel3 = Vector3.ZERO
export var fmass = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# assume for now all particles are the same mass so i just pick a
	# value for G*m1*m2
	var gmm = 5.0
	
	var overlapping = $InfluenceArea.get_overlapping_bodies()	
	var totalInstAcc = Vector3.ZERO;
	
	for body in overlapping:
		if body != self: #not myself lol
			var bodylist = [body.global_transform.origin]
				
			var biggestEffect = Vector3.ZERO
			for body3 in bodylist:
				var rsq = self.global_transform.origin.distance_squared_to(body3)
				var r3 = self.global_transform.origin.direction_to(body3)
				var acc3 = r3 * (gmm * body.fmass * self.fmass)/(rsq)
				if acc3.length_squared() > biggestEffect.length_squared():
					biggestEffect = acc3
				
			totalInstAcc += biggestEffect
	self.add_central_force(totalInstAcc)
	pass
	


