// Stand for the 3 slot tray, in one piece: a four-leg floor, and an upright Y that lies flush on the tray's back. The tray hangs on two hooks that grip honeycomb webs and rests on two ledges.
// Units: mm. World frame: X across the tray, Y toward the back, Z up, floor at Z = 0.
// part = "assembly" shows the stand with the tray; "stand" is print-ready.

part = "assembly"; // [assembly, stand, check, hang]

/* [Pose] */
// Tilt of the tray back from vertical.
tilt = 15;        // [5:1:30]
// Floor to the lowest edge of the tray: room for the charging cables.
clearance = 50;   // [30:1:80]

/* [Fit] */
// Play between a hook and the hexagon hole that it passes through, per side.
hook_fit = 0.25;

/* [Hidden] */
// Tray constants (3_slot_tray.scad).
plate_x = 241.49;
plate_t = 3;
hex_a = 8;                          // hexagon apothem: flats face the tray's long axis
hex_R = hex_a / cos(30);
heads = [[54.61, 81.5], [186.6, 81.5]];  // hexagon centres at 50 % of the tray's height, mirrored about its centre

s = sin(tilt);
c = cos(tilt);

t = 8;                // thickness of the plate that lies on the tray's back
arm_w = 14;
leg_tip_w = 10;       // legs taper from the hub to this width
r_soft = 5;           // radius of the rounded inner and outer corners
stem_w = 16;
pad_w = 20;           // pad around each hexagon
pad_len = 20;
hook_in = 0.5;        // the hook sinks into the plate, so the parts fuse
neck_len = 3.2;       // height of the hook neck along the tray, measured down from the hexagon's upper flat
neck_gap = 0.4;       // the neck stops this far below the flat: the ledges carry the weight
web = 2;              // width of a honeycomb web in the tray
lip_over = 0.8;       // the hook lip reaches this far past the web
lip_t = 0.9;          // lip thickness: it stands this high above the tray face, under the phone
lip_gap = 0.25;       // play between the lip and the tray face
// Lifting the tray by this much clears the lips: hang it on the hooks, then lower it onto the ledges.
lift_to_hang = hex_a + web + lip_over - (hex_a - neck_gap) + 0.5;
ledge_x = [25, plate_x - 25];  // clear of the cable plugs at the slot centres
ledge_w = 11;
ledge_len = 8;        // the ledge reaches this far below the tray's lower edge
ledge_up = 1.5;       // and rises this far into the plate's thickness
v_j = 28;             // where the arms meet, along the tray
xc = plate_x / 2;

floor_t = 7;
// Four legs: the long rear pair resists taps that push the tray backward, the wide front pair resists sideways swipes.
front_span = 80;      // front legs reach this far to each side of the stem
front_off = 20;       // and this far forward of it
rear_span = 60;
rear_len = 100;
Ys = round(v_j * s);  // front face of the vertical stem: behind the tray, clear of the cable column
yj = Ys + t / 2;
z_stem = 74;          // the stem ends inside the plate

// Rounds the convex and concave corners of a 2D shape.
module soften(r = r_soft) {
  offset(r = r) offset(delta = -r) offset(r = -r) offset(delta = r) children();
}

// Tray coordinates (x, y, z: z = 0 on the underside) to world.
module tray_frame() {
  multmatrix([[1, 0, 0, 0], [0, s, -c, 0], [0, c, s, clearance], [0, 0, 0, 1]]) children();
}

// In hexagon coordinates (origin at the hole centre, flats at +-hex_a along v).
module hex_2d(d = 0) { offset(delta = d) scale(hex_a) circle(r = 1 / cos(30), $fn = 6); }

// The neck fills the hole's upper corner and follows its slanted sides, so it holds the tray sideways.
module neck_2d() {
  intersection() {
    hex_2d(-hook_fit);
    translate([-hex_R, hex_a - neck_gap - neck_len]) square([2 * hex_R, neck_len]);
  }
}
module lip_2d() {
  w = 2 * (hex_R - (hex_a - neck_gap) * tan(30) - hook_fit) - 0.4;
  translate([-w / 2, hex_a - 1]) square([w, 1 + web + lip_over]);
}

// A hook: the neck passes through the hole and bears on its upper flat; the lip covers the web above.
module hook() {
  translate([0, 0, -hook_in]) linear_extrude(plate_t + lip_gap + hook_in) neck_2d();
  translate([0, 0, plate_t + lip_gap]) linear_extrude(lip_t) lip_2d();
}

// The Y that lies flush on the tray's back, in tray coordinates.
module plate_2d() soften(4) {
  for (p = heads) {
    translate([p.x - pad_w / 2, p.y - pad_len / 2]) square([pad_w, pad_len]);
    hull() {
      translate([xc, v_j]) circle(r = stem_w / 2, $fn = 48);
      translate(p) circle(r = arm_w / 2, $fn = 48);
    }
  }
  for (x = ledge_x) {
    translate([x - ledge_w / 2, -ledge_len]) square([ledge_w, ledge_len + pad_len]);
    hull() {
      translate([xc, v_j]) circle(r = stem_w / 2, $fn = 48);
      translate([x, pad_len / 2]) circle(r = arm_w / 2, $fn = 48);
    }
  }
}

module plate() {
  tray_frame() {
    translate([0, 0, -t]) linear_extrude(t) plate_2d();
    for (x = ledge_x) translate([x - ledge_w / 2, -ledge_len, -0.01]) cube([ledge_w, ledge_len, ledge_up]);
    for (p = heads) translate([p.x, p.y, 0]) hook();
  }
}

module stem_2d() { translate([xc, Ys + t / 2]) offset(r = 3) square([stem_w - 6, t - 6], center = true); }

module stand() {
  tips = [for (m = [-1, 1]) each [[xc + m * front_span, yj - front_off], [xc + m * rear_span, yj + rear_len]]];
  linear_extrude(floor_t) soften(6) for (p = tips) hull() {
    translate([xc, yj]) circle(r = stem_w / 2 + 1, $fn = 48);
    translate(p) circle(r = leg_tip_w / 2, $fn = 48);
  }
  linear_extrude(z_stem) stem_2d();
  // Flared foot: a stiff, soft-looking joint between the stem and the floor.
  hull() {
    linear_extrude(floor_t) offset(r = 7) stem_2d();
    translate([0, 0, floor_t + 12]) linear_extrude(0.01) stem_2d();
  }
  plate();
}

// Offsets the tray along its own axes. Coplanar contact faces would read as overlap, so checks never use 0.
module tray(dv = 0, dz = 0) { tray_frame() translate([0, dv, dz]) import("3_slot_tray.stl"); }

if (part == "assembly") {
  color("khaki") tray();
  color("steelblue") stand();
} else if (part == "stand") stand();
else if (part == "check") {
  // Empty result = seated on the ledges, the stand touches the tray only at the plate face.
  intersection() { tray(0.02, 0.02); stand(); }
} else if (part == "hang") {
  // Empty result = lifted by lift_to_hang, the tray slides onto the hooks without touching them.
  for (dz = [0.02, 1, 2, 3, 4.2]) intersection() { tray(lift_to_hang, dz); stand(); }
}
