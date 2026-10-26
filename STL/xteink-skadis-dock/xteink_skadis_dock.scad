// MagSafe dock for Xteink readers (X4, X4 Pro, X4C, X3) on an IKEA Skadis board.
//
// INTENT
//   The reader hangs on the board by its built-in MagSafe magnet and charges over USB-C
//   while it hangs. A MagSafe ring sits in the pocket on the disc front. The reader's
//   back touches the ring, so the magnetic grip stays at full strength.
//
// REQUIREMENTS (from the user)
//   1. The ring face is flush with the disc face. A raised lip or a deep pocket adds
//      distance between ring and reader and weakens the grip.
//   2. The USB-C port stays free. The disc (61 mm) is narrower than the reader (69 mm
//      wide), so the port at the reader edge stays clear of the disc.
//   3. 15 mm of free space between the disc back and the board front, for a charger
//      or cable behind the device (see `standoff`).
//   4. The disc stays parallel to the board under the reader's weight (see PADS).
//
// ORIGIN OF THE DIMENSIONS
//   - Disc 61 mm, 40 mm hook pitch: taken from the Skadis MagSafe model
//     (MAKERWORLD 773103, file MAGSAFE.step). Its pocket (56 mm, 5.4 mm deep) holds a
//     charger puck. This design needs a ring, so the pocket is shallow instead.
//   - The Xteink model (MAKERWORLD 3477734) is a ribbed stand with no MagSafe ring.
//     Nothing from it is copied.
//   - Skadis slots: 5 x 15 mm, board 5 mm. Standard values, not measured on the
//     user's board.
//
// HOOKS
//   Each hook is an L. The stem goes through a slot and rests on the slot's lower
//   edge. The foot lies behind the board and hangs below the stem. Stem + foot is
//   14 mm tall and the slot is 15 mm, so mounting is a straight push, then a drop.
//   To unhook, lift 9 mm (`foot_drop`) and pull. A taller hook could not be removed
//   without tilting it. The two hooks sit 40 mm apart in one slot row.
//
// PADS
//   The hooks form a 15 mm cantilever. The reader's weight would tip the disc
//   forward. Four pads press on the board front and hold the disc parallel. They
//   sit at (+-18, +-18) mm. That point is solid board if the slot rows are 20 mm
//   apart and alternate rows shift 20 mm sideways. A pad over a slot would sink in.
//   The pads touch the board with no gap, because play already lets the hooks slide.
//
// PRINTING
//   Print as modeled: hook feet on the bed, pocket up. The hooks need no supports.
//   The pads start mid-air, so they need supports. Use more perimeters on the stems.
//
// NOT VERIFIED (no test print yet)
//   - ring_od and ring_depth are guesses: measure the ring.
//   - The pad positions against the real slot layout.
//   - Stem strength under the reader's load (74 g at 15 mm lever).
//   - Hook clearance `play`.
ring_od = 56;          // [40:0.5:70] MagSafe ring outer diameter (mm)
ring_depth = 1.5;      // [0:0.1:8] Pocket depth: set equal to the ring thickness so the ring sits flush (mm)
rim = 2.5;             // [1:0.5:6] Wall around the pocket (mm)
plate_t = 4;           // [2:0.5:14] Disc thickness (mm)
cable_d = 0;           // [0:0.2:30] Center hole, 0 for none (mm)

slot_w = 5;            // Skadis slot width (mm)
slot_h = 15;           // Skadis slot height (mm)
slot_pitch = 40;       // Slots in one row repeat every 40 mm
board_t = 5;           // Skadis board thickness (mm)
standoff = 15;         // [0:1:30] Gap between disc back and board front, for a charger or cable (mm)
pad_d = 8;             // Pad diameter, pads press on the board so the disc stays parallel (mm)
pad_xy = 18;           // Pad offset from the disc center on both axes, clear of every Skadis slot (mm)
play = 0.4;            // Clearance so the hook slides in (mm)
stem_h = 5;            // Stem height, rests on the slot's lower edge (mm)
foot_t = 2.4;          // Foot thickness behind the board (mm)
foot_drop = 9;         // Foot length below the stem; lift this far to unhook (mm)

disc_d = ring_od + 2 * rim;
hook_w = slot_w - 0.4;
stem_len = board_t + play;
plate_z = foot_t + stem_len + standoff; // disc back face, standoff mm in front of the board
// Foot + stem must stay shorter than the slot, or the dock cannot come off.
assert(stem_h + foot_drop < slot_h, "hook taller than slot");

module hook() {
    y0 = -slot_h / 2;
    translate([-hook_w / 2, 0, 0]) {
        // foot on the bed, hangs below the stem, behind the board
        translate([0, y0 - foot_drop, 0]) cube([hook_w, stem_h + foot_drop, foot_t]);
        // stem through the slot, then across the standoff into the disc
        translate([0, y0, 0]) cube([hook_w, stem_h, plate_z + 0.05]);
    }
}

translate([0, 0, plate_z]) difference() {
    cylinder(d = disc_d, h = plate_t, $fn = 120);
    translate([0, 0, plate_t - ring_depth]) cylinder(d = ring_od, h = ring_depth + 0.01, $fn = 120);
    if (cable_d > 0) translate([0, 0, -0.01]) cylinder(d = cable_d, h = plate_t + 0.02, $fn = 80);
}
for (s = [-1, 1]) translate([s * slot_pitch / 2, 0, 0]) hook();

// Pads sit on solid board between slots and carry the load the hooks cannot.
for (sx = [-1, 1], sy = [-1, 1])
    translate([sx * pad_xy, sy * pad_xy, foot_t + board_t])
        cylinder(d = pad_d, h = plate_z - foot_t - board_t + 0.05, $fn = 48);
