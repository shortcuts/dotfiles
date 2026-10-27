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
//   without tilting it. The two hooks sit 40 mm apart in one slot row. A quarter-round
//   flare (`fillet_r`) joins each stem to the disc. It lies in front of the board, so the
//   slot never sees it.
//
// CHARGER TRAY
//   The dongle (32 x 12 x 12 mm) docks on the reader's back, not its edge. The tray sits
//   below the disc, in the disc plane, with the dongle behind the reader. A short leg
//   joins disc and tray. The tray front is flush with the disc face, so the reader's
//   back lies flat on it. Two thin lips hold the dongle's top and bottom edges. A crush
//   rib presses it against them. Both ends stay open: slide the dongle in from either
//   side, and the cable leaves on that side. A small catch at each end, top and bottom,
//   stops the dongle sliding out when the cable comes off. The thin tray walls flex
//   past it. The cable plug in the middle of the end face passes between the catches. `port_drop` = 43 mm is the user's
//   measurement. `lip_t` leaves a 0.8 mm gap between the dongle face and the reader.
//
// PADS
//   The hooks form a 15 mm cantilever. The reader's weight would tip the disc
//   forward. Four pads press on the board front and hold the disc parallel. They
//   sit at (+-18, +-18) mm. That point is solid board if the slot rows are 20 mm
//   apart and alternate rows shift 20 mm sideways. A pad over a slot would sink in.
//   The pads touch the board with no gap, because play already lets the hooks slide.
//
// PRINTING
//   Print flipped: the disc face on the bed, the hooks and pads pointing up. The
//   `.3mf` is already rotated that way. Printed upright, the 61 mm disc floats 23 mm above
//   the bed and needs a support tower (about 5x the support volume of the flipped print).
//   Flipped, the supports are three small areas:
//   - the 1.5 mm ring pocket, which bridges 56 mm over air;
//   - the two hook feet, which overhang their stems by 9 mm;
//   - the tray's back wall, which bridges 14 mm and needs no support.
//   Use more perimeters on the stems: they are loaded across the layer lines.
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
// Flare at the disc end of the stem. Printed flipped, bending pulls the stem root apart across layers.
fillet_r = 5;          // [0:0.5:8] Fillet radius where the stem meets the disc; 0 for none (mm)

// Charger dongle: a 32 x 12 x 12 mm box behind the reader's back, under the disc.
chg_w = 32;            // Dongle width, along the reader's width (mm)
chg_h = 12;            // Dongle height, vertical (mm)
chg_d = 12;            // Dongle depth, front to back (mm)
// Unplugging USB-C pulls the dongle with 8-20 N, so the catches need `fit` small: the dongle must
// overlap most of `bump_h`, or the cable slides it out.
fit = 0.1;             // Clearance around the dongle so it slides in (mm)
port_drop = 43;        // Ring center to the dongle center, measured on the reader (mm)
wall = 2.4;            // Tray wall (mm)
lip_t = 0.8;           // Lip thickness: the dongle face sits this far behind the disc face (mm)
lip_o = 1.4;          // Lip overlap on the dongle face, top and bottom (mm)
dongle_r = 2;          // [0:0.5:5] Dongle edge radius: the pocket corners match it so the lips hug the curve (mm)
pin_w = 20;            // Width reserved for the pins, from the dongle's left end seen from the disc face (mm)
bump_h = 0.6;         // End catch height: the tray walls flex this far when the dongle slides past (mm)
bump_len = 2.5;        // End catch length, mostly ramp (mm)
tongue_w = 20;         // Leg width between disc and tray (mm)

// Shift the tray so the pin area's center sits under the disc center, in line with the charging coil.
tray_dx = chg_w / 2 - pin_w / 2;

disc_d = ring_od + 2 * rim;
hook_w = slot_w - 0.4;
stem_len = board_t + play;
plate_z = foot_t + stem_len + standoff; // disc back face, standoff mm in front of the board
// Foot + stem must stay shorter than the slot, or the dock cannot come off.
assert(stem_h + foot_drop < slot_h, "hook taller than slot");
// The flare must stay in front of the board, or the stem cannot pass the slot.
assert(plate_z - fillet_r > foot_t + stem_len, "fillet reaches the board");

module hook() {
    y0 = -slot_h / 2;
    translate([-hook_w / 2, 0, 0]) {
        // foot on the bed, hangs below the stem, behind the board
        translate([0, y0 - foot_drop, 0]) cube([hook_w, stem_h + foot_drop, foot_t]);
        // stem through the slot, then across the standoff into the disc
        translate([0, y0, 0]) cube([hook_w, stem_h, plate_z + 0.05]);
        // concave quarter-round flare: widens toward the disc and prints without support
        if (fillet_r > 0) for (k = [0 : 7]) hull() for (j = [k, k + 1]) {
            t = fillet_r * j / 8;
            translate([0, y0, plate_z - t])
                linear_extrude(0.05) offset(r = fillet_r - sqrt(fillet_r ^ 2 - (fillet_r - t) ^ 2))
                    square([hook_w, stem_h]);
        }
    }
}

// Tray geometry, local frame of the disc: z = 0 is the disc back, z = plate_t is the disc face.
dz1 = plate_t - lip_t;                // dongle front face
dz0 = dz1 - chg_d - fit;              // pocket back
py0 = -port_drop - chg_h / 2 - fit;   // pocket bottom
py1 = -port_drop + chg_h / 2 + fit;   // pocket top

module tray() {
    translate([tray_dx, 0, 0]) difference() {
        translate([-chg_w / 2 - bump_len, py0 - wall, dz0 - wall])
            cube([chg_w + 2 * bump_len, py1 - py0 + 2 * wall, plate_t - dz0 + wall]);
        // pocket: open at both ends, so the dongle slides in from either side
        // rounded corners follow the dongle's edges (2D x = world y, 2D y = world z, extrusion = world x)
        translate([-chg_w, 0, 0]) rotate([90, 0, 90]) linear_extrude(2 * chg_w)
            translate([py0, dz0]) offset(r = dongle_r) offset(delta = -dongle_r) square([py1 - py0, dz1 - dz0]);
        // window in front: the reader's back sees the dongle face, the lips hold its edges
        translate([-chg_w, py0 + lip_o, dz1 - 0.01]) cube([2 * chg_w, py1 - py0 - 2 * lip_o, lip_t + 1]);
    }
    // end catches: a hook just past each end of the dongle, top and bottom. They sit
    // beside the end face, so the cable plug in the middle passes between them.
    for (sx = [-1, 1], sy = [[py0, 1], [py1, -1]])
        translate([tray_dx, 0, dz0]) linear_extrude(dz1 - dz0)
            polygon([[sx * chg_w / 2, sy[0]], [sx * (chg_w / 2 + 0.3), sy[0] + sy[1] * bump_h],
                     [sx * (chg_w / 2 + bump_len), sy[0]]]);
    // crush rib pushes the dongle against the lips
    translate([tray_dx - 0.75, py0, dz0]) cube([1.5, py1 - py0, 0.3]);
}

translate([0, 0, plate_z]) {
    difference() {
        union() {
            cylinder(d = disc_d, h = plate_t, $fn = 120);
            // leg: runs down in the disc plane to the top of the tray
            translate([-tongue_w / 2, py1 + wall - 0.5, 0])
                cube([tongue_w, -26 - py1 - wall + 0.5, plate_t]);
        }
        translate([0, 0, plate_t - ring_depth]) cylinder(d = ring_od, h = ring_depth + 0.01, $fn = 120);
        if (cable_d > 0) translate([0, 0, -0.01]) cylinder(d = cable_d, h = plate_t + 0.02, $fn = 80);
    }
    tray();
}
for (s = [-1, 1]) translate([s * slot_pitch / 2, 0, 0]) hook();

// Pads sit on solid board between slots and carry the load the hooks cannot.
for (sx = [-1, 1], sy = [-1, 1])
    translate([sx * pad_xy, sy * pad_xy, foot_t + board_t])
        cylinder(d = pad_d, h = plate_z - foot_t - board_t + 0.05, $fn = 48);
