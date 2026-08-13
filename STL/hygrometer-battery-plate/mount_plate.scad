// Battery cover + car-grid mount, built on the snap-fit door in battery_plate.stl.
// The leg is a stadium (capsule) outline — rounded end pads plus two straight
// side rails — open through the middle so it doesn't cover the hygrometer's
// sensor vent on the housing underside. The door stacks on top of it (2mm leg
// + 2mm door base = 4mm at the joint). Both tie holes sit in the leg's
// rounded ends, clear of the 45mm housing footprint so a rope/zip-tie never
// presses against the hygrometer body.
housing_r = 19.5;      // [10:0.5:40] Hygrometer housing radius (45mm dia)
door_mid_y = 8.23;      // Vertical center of the door part, from its bounding box
leg_thickness = 2;       // [1:0.1:4] Leg + tab thickness (mm)
hole_d = 4;                // [3:0.5:8] Zip-tie / rope hole diameter (mm)
hole_edge_margin = 4;       // [2:0.5:8] Hole center distance from nearest material edge (mm)
standoff = 1;                 // [0:0.5:5] Gap between the housing edge and where the rounded end begins (mm)
rail_width = 1.5;                // [1:0.5:4] Width of each side rail once the leg middle is hollowed (mm)

cy = door_mid_y;
pad_r = hole_edge_margin + hole_d / 2; // rounded end radius = leg width / 2, flush with the straight sides
near_x = -pad_r - standoff;             // rounded-end center, outside the housing on the near side
far_x = 2 * housing_r + pad_r + standoff; // rounded-end center, outside the housing on the far side

module leg() {
    translate([0, cy, -0.05])
        linear_extrude(leg_thickness + 0.1)
            difference() {
                hull() {
                    translate([near_x, 0]) circle(r = pad_r, $fn = 48);
                    translate([far_x, 0]) circle(r = pad_r, $fn = 48);
                }
                // Hollow the straight middle section, leaving the two rounded
                // end pads fully solid (round, for the zip-tie) and a
                // rail_width-wide rail on each side so the housing's sensor
                // vent stays clear. Window stops at the pad edges, not the
                // pad centers, so it never bites into the circles.
                translate([near_x + pad_r + 18.8, -(pad_r - rail_width)])
                    square([far_x - near_x - 2 * pad_r -18.8, 2 * (pad_r - rail_width)]);
            }
}

module near_hole() {
    translate([near_x, cy, -1])
        cylinder(h = leg_thickness + 4, d = hole_d, $fn = 32);
}

module far_hole() {
    translate([far_x, cy, -1])
        cylinder(h = leg_thickness + 4, d = hole_d, $fn = 32);
}

module door() {
    // Raised so its base stacks on top of the leg (2mm leg + 2mm door base = 4mm).
    // The raised rib along the curved edge (x<8) stands ~0.9mm proud of the
    // main plate — useless, and stops the battery sitting flat. Sliced flush
    // with the plate's top surface (z=1.82 in source part).
    //
    // Two more raised features sit between x=8 and the far edge: a nub at
    // x 8.2-8.8 next to the center hole, and two barb tabs at x>14.8 that
    // spike ~1.3mm above the plate's top — too tall to seat in the device's
    // slot. The gap between them (x 8.8-14.8) is already flat, so both are
    // flattened with one cube instead of two — a cut boundary landing near
    // a feature's rail edge leaves a degenerate zero-volume sliver that
    // CGAL's full render shows as a thin seam (invisible in preview).
    translate([0, 0, leg_thickness])
        union() {
            difference() {
                import("battery_plate.stl");
                translate([-1, -1, 1.82]) cube([5, 18, 2]);
                translate([2, 0, 2.1]) cube([20, 20, 20]);
                translate([10, 0, 1.2]) cube([25, 1.53, 5]);
                translate([10, 14.94, 1.2]) cube([25, 1.53, 5]);
            }
            grip_tabs();
        }
}

// Two small overhangs at the plate's far corners (y near 0 and y near
// 16.4) that key into the device's groove. The corner there is rounded,
// so a short embed used to leave the true corner's natural point poking
// out past it at an angle — read as "pointing outward" instead of
// straight down the leg's direction (+x). The embed now reaches back to
// x=14, inside the plate's plain flat region (confirmed uniform, no
// rounding), and the tip runs past the plate's true max edge (19.55) —
// so this flat spine is the outermost feature, squares off the corner,
// and both overhangs read as one straight continuation of the plate
// pointing +x, not a nub angled off the curve.
// It sits 0.5mm below the plate's top surface (grooves are up near the
// top, where the battery sits, not down at the bottom) — a thin lip
// hanging just under the top, not a block resting on the bed.
corner_embed_x = 14;        // Where the spine starts — inside the plate's plain flat region
corner_tip_x = 18.6;           // [17:0.1:21] Where the spine ends — just past the corner's real edge (18.09)
overhang_width = 2.2;             // [0.5:0.5:4] Overhang width — y (mm)
overhang_drop = -0.5;             // [0.2:0.1:1] How far below the plate's top surface the lip sits — z (mm)
overhang_thickness = 0.5;    // [0.3:0.1:1] Lip thickness — z (mm)
corner_y = [2.7, 13.8];       // Overhang centers, near each corner's true outer y

module grip_tabs() {
//    for (y = corner_y)
//        translate([corner_embed_x, y - overhang_width / 2, 1.82 - overhang_drop - overhang_thickness])
//            cube([corner_tip_x - corner_embed_x, overhang_width, overhang_thickness]);
}

difference() {
    union() {
        door();
        leg();
    }
    near_hole();
    far_hole();
}
