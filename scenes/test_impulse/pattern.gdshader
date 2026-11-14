shader_type spatial;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 st = fract(UV * 100.);
	vec3 color = vec3(0.3, 0.2, 0.5);
	float pct = step(distance(st, vec2(0.5, 0.5)), 0.1);
	color *= pct;
	ALBEDO = color;
	ROUGHNESS = pct;
	METALLIC = 1. - pct;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
