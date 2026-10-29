// Stand for the 3 slot tray, in one piece: a four-leg floor, and an upright Y that lies flush on the tray's back and clamps into two honeycomb holes at mid height.
// Units: mm. World frame: X across the tray, Y toward the back, Z up, floor at Z = 0.
// part = "assembly" shows the stand with the tray; "stand" is print-ready.

part = "assembly"; // [assembly, stand, check]

/* [Pose] */
// Tilt of the tray back from vertical.
tilt = 15;        // [5:1:30]
// Floor to the lowest edge of the tray: room for the charging cables.
clearance = 50;   // [30:1:80]

/* [Fit] */
// The cross tips press into the hexagon hole by this much per side.
tab_fit = 0.15;

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
tab_w = 3;            // arm width of the cross
tab_in = 0.5;         // the cross sinks into the plate, so the parts fuse
v_j = 22;             // where the two arms meet, along the tray
xc = plate_x / 2;

floor_t = 7;
// Four legs: the long rear pair resists taps that push the tray backward, the wide front pair resists sideways swipes.
front_span = 80;      // front legs reach this far to each side of the stem
front_off = 20;       // and this far forward of it
rear_span = 60;
rear_len = 100;
Ys = 6;               // front face of the vertical stem: behind the tray, clear of the cable column
yj = Ys + t / 2;
z_stem = 70;          // the stem ends inside the plate

// Rounds the convex and concave corners of a 2D shape.
module soften(r = r_soft) {
  offset(r = r) offset(delta = -r) offset(r = -r) offset(delta = r) children();
}

// Tray coordinates (x, y, z: z = 0 on the underside) to world.
module tray_frame() {
  multmatrix([[1, 0, 0, 0], [0, s, -c, 0], [0, c, s, clearance], [0, 0, 0, 1]]) children();
}

module cross() {
  // Vertical tips press on the hexagon's flats and carry the weight; horizontal tips sit in its corners.
  translate([0, 0, -tab_in]) linear_extrude(tab_in) cross_2d();
  linear_extrude(plate_t - 0.2, scale = 0.94) cross_2d();
}
module cross_2d() {
  square([2 * (hex_R - 0.9 + tab_fit), tab_w], center = true);
  square([tab_w, 2 * (hex_a + tab_fit)], center = true);
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
}

module plate() {
  tray_frame() {
    translate([0, 0, -t]) linear_extrude(t) plate_2d();
    for (p = heads) translate([p.x, p.y, 0]) cross();
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

// Lifts the tray off the stand by `lift` along its own axes: coplanar contact faces would read as overlap.
module tray(lift = 0) { tray_frame() translate([0, lift, lift]) import("3_slot_tray.stl"); }

if (part == "assembly") {
  color("khaki") tray();
  color("steelblue") stand();
} else if (part == "stand") stand();
else if (part == "check") {
  // Empty result = the stand touches the tray only at the plate face and the cross tips.
  intersection() { tray(0.02); stand(); }
}
