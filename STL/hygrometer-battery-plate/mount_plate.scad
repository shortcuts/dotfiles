// Battery cover + car-grid mount, built on the snap-fit door in battery_plate.stl.
// The leg is a single stadium (capsule) shape — straight sides, rounded ends,
// no overhanging tabs — sitting flat on the bed. The door stacks on top of
// it (2mm leg + 2mm door base = 4mm at the joint). Both tie holes sit in the
// leg's rounded ends, clear of the 45mm housing footprint so a rope/zip-tie
// never presses against the hygrometer body.
housing_r = 22.5;      // [10:0.5:40] Hygrometer housing radius (45mm dia)
door_mid_y = 8.23;      // Vertical center of the door part, from its bounding box
leg_thickness = 2;       // [1:0.1:4] Leg + tab thickness (mm)
hole_d = 4;                // [3:0.5:8] Zip-tie / rope hole diameter (mm)
hole_edge_margin = 4;       // [2:0.5:8] Hole center distance from nearest material edge (mm)
standoff = 1;                 // [0:0.5:5] Gap between the housing edge and where the rounded end begins (mm)

cy = door_mid_y;
pad_r = hole_edge_margin + hole_d / 2; // rounded end radius = leg width / 2, flush with the straight sides
near_x = -pad_r - standoff;             // rounded-end center, outside the housing on the near side
far_x = 2 * housing_r + pad_r + standoff; // rounded-end center, outside the housing on the far side

module leg() {
    translate([0, cy, -0.05])
        linear_extrude(leg_thickness + 0.1)
            hull() {
                translate([near_x, 0]) circle(r = pad_r, $fn = 48);
                translate([far_x, 0]) circle(r = pad_r, $fn = 48);
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
        difference() {
            import("battery_plate.stl");
            translate([-1, -1, 1.82]) cube([5, 18, 2]);
            translate([7, -1, 1.82]) cube([14, 18, 2]);
        }
}

difference() {
    union() {
        door();
        leg();
    }
    near_hole();
    far_hole();
}
