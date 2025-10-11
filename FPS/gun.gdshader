shader_type spatial;

uniform vec4 clr: source_color;

void vertex() {
	// https://www.youtube.com/watch?v=1WCibEaJFc0
	POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX.xyz, 1.0);
	POSITION.z = mix(POSITION.z, 0.0, 0.99);
}

void fragment() {
	ALBEDO = clr.rgb;
	ALPHA = clr.a;
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
