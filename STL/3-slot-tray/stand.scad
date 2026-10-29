// Stand for the 3 slot tray, in two pieces that print without support: a base (four-leg floor and stem) and a plate (the Y that lies flush on the tray's back). Two M3 screws join them. The tray hangs on two hooks that grip honeycomb webs and rests on two ledges.
// Units: mm. World frame: X across the tray, Y toward the back, Z up, floor at Z = 0.
//
// Parts (set `part`):
//   assembly  the stand with the tray, for viewing
//   base      print-ready: stands on its floor
//   plate     print-ready: back face on the bed, hooks up
//   stand     base and plate in the assembly pose, for exports and diffs
//   check, hang, joint  regression checks: each must render "Current top level object is empty."
//
// Findings (why two pieces):
//   - The one-piece stand printed upright had 2633 mm2 of faces steeper than 45 deg. Sources:
//     hooks and lips (75 deg from vertical), ledge arms (a 96 mm span, 10 deg below horizontal), upper arms (51 deg from vertical).
//   - The stem was 16 x 8 mm and printed upright: layer lines ran across its weak axis, and a tap on the tray bends it there.
//   - Printed upright, the hooks were short pegs on a tilted face, with layers across the load.
//   - Now: base 37 mm2 (the ceilings of two 2.6 mm pilot holes), plate 72 mm2 (two lip shelves, a 3.2 mm bridge each).
//     Measure: faces with normal z < -0.707 above the bed, from the exported STL.
//
// Constraints:
//   - The tray position, hooks and ledges do not change. Do not edit them to suit the joint: `check` and `hang` prove the tray still seats and slides on.
//   - The stem front stays at Y = Ys. The stem must not enter the cable column in front of it.
//   - The legs keep the old stem centre (yj), so the floor footprint does not change.
//   - The lap face is parallel to the plate. It leans back by `tilt`, so the base prints without support. Any other angle adds an overhang.
//   - The hub and its fillets reach down to v = 17. The lap face starts at v_lap = 15 so no base material pokes into the plate.
//   - A pilot hole keeps 2 mm of wall: an assert at the end of this file enforces it.
//   - Do not add features that point toward the tray, such as pins or tabs on the base. In the print pose they are near-horizontal bridges.
//
// Requirements:
//   - Bed: 206 x 102 mm for the plate, 132 x 102 mm for the base.
//   - Hardware: two M3 countersunk self-tapping screws, 16 mm long (8 mm plate, 8 mm thread in the stem).
//   - Fit the screws before you hang the tray: the heads sit flush with the plate face, under the tray.
//   - Print the plate with the hooks up. The layers then run along the arms, and the hooks are vertical pegs.
//   - Cooling on the lip shelves. Check that the web still slides between the lip and the plate face (lip_gap).
//   - Not tested on a real print: the pilot hole size (pilot_d) and the hole fit (screw_d) may need a trim.
//
// Verify after every change (each must report an empty object, except where noted):
//   openscad -D 'part="check"' -o /tmp/o.stl stand.scad   seated on the ledges: the stand touches the tray only at the plate face
//   openscad -D 'part="hang"'  -o /tmp/o.stl stand.scad   the tray slides onto the hooks
//   openscad -D 'part="joint"' -o /tmp/o.stl stand.scad   the two pieces touch only at the lap face
//   openscad -D 'part="joint"' -D 'probe=-0.1' ...        not empty: the lap faces do touch
part = "assembly"; // [assembly, stand, base, plate, check, hang, joint]

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
stem_d = 20;          // stem depth along Y: the lap face needs 8 mm of wall behind the plate
v_lap = 15;           // the lap face starts here along the tray: the fillets between the hub and the ledge arms reach down to v = 17
v_top = 38;           // the stem ends here along the tray: just above the hub's top, v_j + stem_w / 2 = 36
screw_d = 3.4;        // M3 clearance
csk_d = 6.4;          // countersink: the head sits flush with the plate face, the tray rests on that face
csk_h = 1.7;
pilot_d = 2.6;        // self-tapping M3 core hole in the stem
pilot_depth = 9;
probe = 0.02;         // part = "joint": gap between the lap faces
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
screws = [[xc - 4, 24.5], [xc + 4, 32]];  // tray coordinates; offset in x so the two screws also stop the plate from twisting

floor_t = 7;
// Four legs: the long rear pair resists taps that push the tray backward, the wide front pair resists sideways swipes.
front_span = 80;      // front legs reach this far to each side of the stem
front_off = 20;       // and this far forward of it
rear_span = 60;
rear_len = 100;
Ys = round(v_j * s);  // front face of the vertical stem: behind the tray, clear of the cable column
yj = Ys + t / 2;     // the legs keep the old stem centre, so the floor footprint does not change
z_stem = 100;         // taller than needed: v_top cuts the real top

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

// In tray coordinates.
module plate_body() {
  difference() {
    union() {
      translate([0, 0, -t]) linear_extrude(t) plate_2d();
      for (x = ledge_x) translate([x - ledge_w / 2, -ledge_len, -0.01]) cube([ledge_w, ledge_len, ledge_up]);
      for (p = heads) translate([p.x, p.y, 0]) hook();
    }
    for (p = screws) {
      translate([p.x, p.y, -t - 0.01]) cylinder(d = screw_d, h = t + 0.02, $fn = 24);
      translate([p.x, p.y, -csk_h]) cylinder(d1 = screw_d, d2 = csk_d, h = csk_h + 0.01, $fn = 24);
    }
  }
}

module plate() { tray_frame() plate_body(); }

// Back face on the bed, hooks up.
module plate_print() { translate([0, 0, t]) plate_body(); }

module stem_2d() { translate([xc, Ys + stem_d / 2]) offset(r = 3) square([stem_w - 6, stem_d - 6], center = true); }

// Everything in the tray frame at or past v0 (and past w0).
module tray_region(v0, w0 = -500) { tray_frame() translate([-500, v0, w0]) cube(1000); }

module base() {
  tips = [for (m = [-1, 1]) each [[xc + m * front_span, yj - front_off], [xc + m * rear_span, yj + rear_len]]];
  linear_extrude(floor_t) soften(6) for (p = tips) hull() {
    translate([xc, yj]) circle(r = stem_w / 2 + 1, $fn = 48);
    translate(p) circle(r = leg_tip_w / 2, $fn = 48);
  }
  difference() {
    linear_extrude(z_stem) stem_2d();
    tray_region(v_top);
    tray_region(v_lap, -t);  // the lap face: parallel to the plate, so it leans back and prints without support
    for (p = screws) tray_frame() translate([p.x, p.y, -t - pilot_depth]) cylinder(d = pilot_d, h = pilot_depth + 0.01, $fn = 24);
  }
  // Flared foot: a stiff, soft-looking joint between the stem and the floor.
  hull() {
    linear_extrude(floor_t) offset(r = 7) stem_2d();
    translate([0, 0, floor_t + 12]) linear_extrude(0.01) stem_2d();
  }
}

module stand() { base(); plate(); }

for (p = screws) assert(Ys + stem_d - (s * p.y + c * (t + pilot_depth)) >= 2, "a pilot hole breaks through the stem's back");

// Offsets the tray along its own axes. Coplanar contact faces would read as overlap, so checks never use 0.
module tray(dv = 0, dz = 0) { tray_frame() translate([0, dv, dz]) import("3_slot_tray.stl"); }

if (part == "assembly") {
  color("khaki") tray();
  color("steelblue") base();
  color("indianred") plate();
} else if (part == "stand") stand();
else if (part == "base") base();
else if (part == "plate") plate_print();
else if (part == "check") {
  // Empty result = seated on the ledges, the stand touches the tray only at the plate face.
  intersection() { tray(0.02, 0.02); stand(); }
} else if (part == "hang") {
  // Empty result = lifted by lift_to_hang, the tray slides onto the hooks without touching them.
  for (dz = [0.02, 1, 2, 3, 4.2]) intersection() { tray(lift_to_hang, dz); stand(); }
} else if (part == "joint") {
  // Empty result = the plate and the base touch only at the lap face.
  intersection() { base(); tray_frame() translate([0, 0, probe]) plate_body(); }
}
