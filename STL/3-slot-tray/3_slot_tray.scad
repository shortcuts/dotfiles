// 3 Slot Tray: parametric rebuild of an Onshape design ("3 Slot Tray.stl").
// Units: mm. Origin: front-left corner of the plate, z = 0 on the bed.
// With the default values the model matches the original STL to within ~0.1 mm.

/* [Slots] */
// Clear width of slot 1, measured at the wall root.
slot_1 = 76.43;
// Clear width of slot 2.
slot_2 = 76.43;
// Clear width of slot 3.
slot_3 = 76.43;

/* [Height] */
// Height of the end lips (the tallest part).
wall_h = 22;       // [10:1:60]
// The dividers stand this much lower than the lips.
stem_drop = 4;     // [0:1:10]

/* [Pattern] */
// "original" keeps the hand-placed hexagons and pockets of the Onshape design.
// "auto" fills each slot with the hexagon lattice, so any slot width works.
layout = "original"; // [original, auto]

/* [Hidden] */
plate_x_def = 241.5;
plate_y = 169;
plate_t = 3;          // floor thickness
wall_t = 3.05;        // wall thickness at the root
draft = 3.74;         // inner faces lean outward by this angle: the lips hold the items
fillet_r = 4;         // concave fillet at the wall root, and the rounding of the lip ends
side_r = 1;           // rounding of the long top edges
corner_r = 5;         // plate corner radius
plate_edge_r = 0.5;   // rounding of the plate's top edge
cell_r = 1;           // rounding of the hole and pocket edges in the floor
corner_vr = 0.8;      // radius of the vertical wall corners
stem_len = 35;        // divider length, from the plate edge
bar_half = 16.5;      // half length of the lip on a divider
end_bar = 18;         // length of the lip on the outer wall
hex_a = 8;            // hexagon apothem (flat to flat = 16)
hex_R = hex_a / cos(30);
pocket_r = 5.5;
slot_def = 76.43;
slots = [slot_1, slot_2, slot_3];
plate_x = slot_1 + slot_2 + slot_3 + 4 * wall_t;

function slot_x0(i, s = slots) = i == 0 ? wall_t : slot_x0(i - 1, s) + s[i - 1] + wall_t;
function shift(i) = slot_x0(i) - slot_x0(i, [slot_def, slot_def, slot_def]);
function stem_c(i) = slot_x0(i) - wall_t / 2;   // centre line of divider i (1 or 2)
// Which default slot holds a default-layout x.
function slot_of(x) = x < slot_x0(1, [slot_def, slot_def, slot_def]) ? 0
                    : x < slot_x0(2, [slot_def, slot_def, slot_def]) ? 1 : 2;

// Hexagon lattice of the original: 4 sites per 33 x 36 cell (not a regular lattice).
// [type, k, j] -> centre. Types: 0 = A, 1 = A', 2 = B, 3 = C.
lat_x = [21.605, 21.69, 38.0, 38.42];
lat_y = [45.5, 63.5, 20.0, 38.0];
function site(h) = [lat_x[h[0]] + 33 * h[1], lat_y[h[0]] + 36 * h[2]];

hex_original = [
  [0,0,0],[0,0,1],[0,0,2],[1,0,0],[1,0,1],[2,0,0],[2,0,1],[2,0,2],[2,0,3],[3,0,0],[3,0,1],[3,0,2],[3,0,3],
  [0,1,0],[0,1,1],[0,1,2],[1,1,0],[1,1,1],[2,1,1],[2,1,2],[2,1,3],[3,1,0],[3,1,1],[3,1,2],
  [0,2,0],[0,2,1],[0,2,2],[1,2,0],[1,2,1],[2,2,1],[2,2,2],[3,2,0],[3,2,1],[3,2,2],
  [0,3,0],[0,3,1],[0,3,2],[1,3,-1],[1,3,0],[1,3,1],[1,3,2],[2,3,1],[2,3,2],[3,3,0],[3,3,1],[3,3,2],
  [0,4,0],[0,4,1],[0,4,2],[1,4,0],[1,4,1],[2,4,1],[2,4,2],[2,4,3],[3,4,0],[3,4,1],[3,4,2],
  [0,5,0],[0,5,1],[0,5,2],[1,5,0],[1,5,1],[2,5,0],[2,5,1],[2,5,2],[2,5,3],[3,5,0],[3,5,1],[3,5,2],[3,5,3],
  [0,6,0],[0,6,1],[0,6,2],[1,6,0],[1,6,1]
];

// "auto" layout: lattice rows between the two pocket rows, kept clear of the wall root fillets and centred in each slot.
auto_margin = fillet_r + 1;
auto_y_min = 38;
auto_y_max = plate_y - auto_y_min;
auto_pocket_y = 19.78;

// Floor pockets of the original, as [x from the slot's left wall root, y]. Slot 3 mirrors nothing: they were placed by hand.
pockets_original = [
  [[16.615, 19.78], [56.205, 19.78], [19.095, 134.825], [52.475, 134.825]],
  [[15.795, 19.78], [58.555, 19.78], [17.14, 134.825], [58.805, 134.825]],
  [[18.215, 19.78], [62.365, 19.78], [25.115, 134.825], [58.78, 134.825]]
];
auto_pocket_inset = 19;

function in_slot_x(x, i) = x - hex_R >= slot_x0(i) + auto_margin && x + hex_R <= slot_x0(i) + slots[i] - auto_margin;
// Lattice sites that fit slot i with the lattice flush against its left wall.
function auto_fit(i) = [for (k = [-2:8], h = [0:3], j = [-2:4])
    let (p = [lat_x[h] + 33 * k + shift(i), lat_y[h] + 36 * j])
    if (p.y >= auto_y_min && p.y <= auto_y_max && in_slot_x(p.x, i)) p];
function auto_sites(i) =
    let (f = auto_fit(i), xs = [for (p = f) p.x],
         free = slots[i] - 2 * auto_margin - (max(xs) - min(xs) + 2 * hex_R))
    [for (p = f) [p.x + free / 2 - (min(xs) - hex_R - slot_x0(i) - auto_margin), p.y]];

function hex_sites() =
    layout == "original"
    ? [for (h = hex_original) let (p = site(h)) [p.x + shift(slot_of(p.x)), p.y]]
    : [for (i = [0:2], p = auto_sites(i)) p];

function top_pockets() =
    layout == "original"
    ? [for (i = [0:2], p = pockets_original[i]) [slot_x0(i) + p[0], p[1]]]
    : [for (i = [0:2], x = [slot_x0(i) + min(auto_pocket_inset, slots[i] / 4), slot_x0(i) + slots[i] - min(auto_pocket_inset, slots[i] / 4)], y = [auto_pocket_y, plate_y - auto_pocket_y]) [x, y]];

// Blind pockets in the underside, under each wall root.
function bottom_pockets() =
    [for (x = [8, plate_x / 2, plate_x - 8], y = [8, plate_y - 8]) [x, y]];

// ---------- floor ----------
module outline() { offset(r = corner_r) offset(delta = -corner_r) square([plate_x, plate_y]); }

module floor_plate() {
  n = 4;
  hull() {
    linear_extrude(plate_t - plate_edge_r) outline();
    for (i = [1:n]) {
      u = plate_edge_r * i / n;
      e = plate_edge_r - sqrt(plate_edge_r ^ 2 - u ^ 2);
      translate([0, 0, plate_t - plate_edge_r + u - 0.001])
        linear_extrude(0.001) offset(delta = -e) outline();
    }
  }
}

// Cutter whose top edge is rounded like a fillet: children() is a unit-size 2D shape.
module rounded_cut(size, z0 = -1) {
  n = 8;
  zb = plate_t - cell_r;
  translate([0, 0, z0]) linear_extrude(zb - z0 + 0.001) scale(size) children();
  for (i = [0:n - 1]) {
    u0 = cell_r * i / n;
    u1 = cell_r * (i + 1) / n;
    e0 = cell_r - sqrt(cell_r ^ 2 - u0 ^ 2);
    e1 = cell_r - sqrt(cell_r ^ 2 - u1 ^ 2);
    translate([0, 0, zb + u0])
      linear_extrude(u1 - u0 + (i == n - 1 ? 0.5 : 0.001), scale = (size + e1) / (size + e0))
        scale(size + e0) children();
  }
}

module floor_cuts() {
  for (p = hex_sites()) translate([p.x, p.y, 0]) rounded_cut(hex_a) circle(r = 1 / cos(30), $fn = 6);
  for (p = top_pockets()) translate([p.x, p.y, plate_t - cell_r]) rounded_cut(pocket_r, 0) circle(r = 1, $fn = 72);
  for (p = bottom_pockets()) translate([p.x, p.y, -1]) cylinder(r = pocket_r, h = 3, $fn = 72);
}

// ---------- walls ----------
// Retreat of a surface that is rounded with radius r under a top at height `top`.
function rr(z, top, r) = z > top - r ? r - sqrt(max(0, r * r - pow(z - (top - r), 2))) : 0;

module rect(x0, x1, y0, y1) { if (x1 > x0 && y1 > y0) translate([x0, y0]) square([x1 - x0, y1 - y0]); }

// Walls on the front edge (y = 0) at height z; the back edge mirrors them.
module front_walls(z) {
  h_stem = wall_h - stem_drop;
  g = (z - plate_t) * tan(draft);
  es = rr(z, wall_h, side_r);
  ee = rr(z, wall_h, fillet_r);
  ss = rr(z, h_stem, side_r);
  st = rr(z, h_stem, fillet_r);
  tb = wall_t + g;
  offset(r = corner_vr) offset(delta = -corner_vr)
  offset(r = -fillet_r) offset(delta = fillet_r) union() {
    // lip and stem of the left outer wall
    rect(es, end_bar - ee, es, tb - es);
    if (z < h_stem) rect(ss, wall_t + g - ss, 0, stem_len - st);
    // right outer wall
    rect(plate_x - end_bar + ee, plate_x - es, es, tb - es);
    if (z < h_stem) rect(plate_x - wall_t - g + ss, plate_x - ss, 0, stem_len - st);
    // dividers
    for (i = [1, 2]) {
      c = stem_c(i);
      rect(c - bar_half + ee, c + bar_half - ee, es, tb - es);
      if (z < h_stem) rect(c - wall_t / 2 - g + ss, c + wall_t / 2 + g - ss, 0, stem_len - st);
    }
  }
}

module wall_layer(z, dz) {
  u = z - plate_t;
  d = u < fillet_r ? fillet_r - sqrt(fillet_r ^ 2 - pow(fillet_r - u, 2)) : 0;
  translate([0, 0, z - dz / 2 - 0.002]) linear_extrude(dz + 0.002)
    intersection() {
      outline();
      union() {
        offset(r = d) front_walls(z);
        translate([0, plate_y]) mirror([0, 1]) offset(r = d) front_walls(z);
      }
    }
}

module walls() {
  // Fine layers on the root fillet, coarse above it (0.25 mm is finer than a print layer).
  fine = 0.1;
  coarse = 0.25;
  nf = ceil(fillet_r / fine);
  for (i = [0:nf - 1]) wall_layer(plate_t + (i + 0.5) * fine, fine);
  z0 = plate_t + nf * fine;
  nc = ceil((wall_h - z0) / coarse);
  dzc = (wall_h - z0) / nc;
  for (i = [0:nc - 1]) wall_layer(z0 + (i + 0.5) * dzc, dzc);
}

module tray() {
  difference() { floor_plate(); floor_cuts(); }
  walls();
}

tray();
