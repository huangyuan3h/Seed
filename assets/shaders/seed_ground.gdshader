shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;
// Stylised alien-prairie ground. Vertex colour carries the large shapes; this
// shader adds world-space break-up, a worn landing pad, and slope rock.

uniform vec3 grass_colour : source_color = vec3(0.34, 0.46, 0.26);
uniform vec3 dry_colour : source_color = vec3(0.60, 0.54, 0.34);
uniform vec3 dirt_colour : source_color = vec3(0.39, 0.32, 0.23);
uniform vec3 rock_colour : source_color = vec3(0.46, 0.45, 0.40);
uniform float pad_radius = 8.0;
uniform float pad_fade = 9.0;

varying vec3 v_world;
varying vec3 v_normal_world;
varying vec3 v_colour;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(13.7, 29.3);
		a *= 0.5;
	}
	return v;
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal_world = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_colour = COLOR.rgb;
}

void fragment() {
	float macro = fbm(v_world.xz * 0.045);
	float mid = fbm(v_world.xz * 0.23 + 7.0);
	float fine = vnoise(v_world.xz * 3.1);
	float slope = 1.0 - clamp(v_normal_world.y, 0.0, 1.0);

	// Base is the vertex colour painted by the terrain builder.
	vec3 col = mix(v_colour, grass_colour, 0.35);

	// Broad dry-grass patches.
	float dryness = smoothstep(0.48, 0.78, macro * 0.6 + mid * 0.4);
	col = mix(col, dry_colour, dryness * 0.55);

	// Worn dirt around the landing site, then a fainter trail ring.
	float r = length(v_world.xz);
	float pad = 1.0 - smoothstep(pad_radius, pad_radius + pad_fade, r);
	float ring = (1.0 - smoothstep(0.0, 2.4, abs(r - 15.0))) * 0.22;
	col = mix(col, dirt_colour, clamp(pad * (0.42 + mid * 0.22) + ring * (0.4 + mid), 0.0, 0.9));

	// Rock shows through on steep ground.
	float rock = smoothstep(0.24, 0.62, slope + (mid - 0.5) * 0.18);
	col = mix(col, rock_colour * mix(0.78, 1.12, fine), rock);

	// Small-scale break-up so large triangles do not read as flat cards.
	col *= mix(0.86, 1.13, fine * 0.55 + mid * 0.45);

	ALBEDO = col;
	ROUGHNESS = mix(0.99, 0.84, clamp(pad + slope, 0.0, 1.0) * 0.7);
	SPECULAR = 0.18;
}
