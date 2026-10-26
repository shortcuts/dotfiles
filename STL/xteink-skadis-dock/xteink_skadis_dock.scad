// MagSafe dock for Xteink readers on an IKEA Skadis board.
// A MagSafe ring or puck sits in the pocket and the reader's magnet clings to it.
// The disc is narrower than the reader, so the USB-C port stays free.
// Print as modeled: hook feet on the bed, pocket up. No supports needed.
// Disc, pocket and hook pitch match the "Magsafe IKEA Skadis" model (MAGSAFE.step).
ring_od = 56;          // [40:0.5:70] MagSafe ring or puck outer diameter (mm)
ring_depth = 5.4;      // [0:0.1:8] Pocket depth, set to the puck or sticker thickness (mm)
rim = 2.5;             // [1:0.5:6] Wall around the pocket (mm)
plate_t = 11;          // [4:0.5:14] Disc thickness (mm)
cable_d = 22.4;        // [0:0.2:30] Center hole for a puck cable, 0 for none (mm)

slot_w = 5;            // Skadis slot width (mm)
slot_h = 15;           // Skadis slot height (mm)
slot_pitch = 40;       // Slots in one row repeat every 40 mm
board_t = 5;           // Skadis board thickness (mm)
play = 0.4;            // Clearance so the hook slides in (mm)
stem_h = 5;            // Stem height, rests on the slot's lower edge (mm)
foot_t = 2.4;          // Foot thickness behind the board (mm)
foot_drop = 9;         // Foot length below the stem; lift this far to unhook (mm)

disc_d = ring_od + 2 * rim;
hook_w = slot_w - 0.4;
stem_len = board_t + play;
plate_z = foot_t + stem_len; // disc back face, flat against the board front
// Foot + stem must stay shorter than the slot, or the dock cannot come off.
assert(stem_h + foot_drop < slot_h, "hook taller than slot");

module hook() {
    y0 = -slot_h / 2;
    translate([-hook_w / 2, 0, 0]) {
        // foot on the bed, hangs below the stem, behind the board
        translate([0, y0 - foot_drop, 0]) cube([hook_w, stem_h + foot_drop, foot_t]);
        // stem through the slot, up into the disc
        translate([0, y0, 0]) cube([hook_w, stem_h, plate_z + 0.05]);
    }
}

translate([0, 0, plate_z]) difference() {
    cylinder(d = disc_d, h = plate_t, $fn = 120);
    translate([0, 0, plate_t - ring_depth]) cylinder(d = ring_od, h = ring_depth + 0.01, $fn = 120);
    if (cable_d > 0) translate([0, 0, -0.01]) cylinder(d = cable_d, h = plate_t + 0.02, $fn = 80);
}
for (s = [-1, 1]) translate([s * slot_pitch / 2, 0, 0]) hook();
