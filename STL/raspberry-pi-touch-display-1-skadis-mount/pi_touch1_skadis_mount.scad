// Raspberry Pi Touch Display 1 (7", DSI) - IKEA SKADIS mount
// Adapted from printables.com/model/1396822 (Touch Display 2 version).
// Same overall structure as the original: two interlocking halves,
// open frame ring, SKADIS pegs on the back. Original's inner edge has
// clip teeth that grip Display 2's case channel directly -- Display 1
// has no such channel, only 4 keyhole slots on the PCB back, so the
// clip teeth are replaced with molded keyhole legs (you slide the leg
// into the slot, that's the whole attachment -- no hardware).
// SKADIS pegs use a standard drop-lock nub (round peg, slides down
// into the slot's narrow channel) at the 40mm pitch measured from the
// original model -- that pitch has to match the pegboard grid exactly.

// ---- Display 1 mounting spec (user-measured / user-confirmed) ----
hole_spacing_x = 115;  // mm, horizontal spacing between keyhole legs
hole_spacing_y = 57;   // mm, vertical spacing between keyhole legs
slot_narrow_w  = 5;    // mm, narrow (locked) part of keyhole slot
slot_wide_h    = 7;    // mm, wide (entry) part of keyhole slot
slot_depth     = 3;    // mm, gap between frame and leg head (board thickness clearance)

// ---- Frame (open ring, like the original) ----
frame_w  = hole_spacing_x + 35;  // 150mm
frame_h  = hole_spacing_y + 33;  // 90mm
frame_t  = 4;                    // frame thickness
border   = 15;                   // ring wall width

// ---- Molded keyhole leg (mushroom standoff) ----
leg_neck_d = slot_narrow_w - 0.6;  // clearance to slide in narrow slot
leg_head_d = slot_wide_h - 0.6;    // must pass wide entry, catch on narrow slot
leg_head_h = 1.6;
leg_neck_h = slot_depth;

// ---- SKADIS peg (back face) ----
skadis_pitch = 40;   // measured from original model -- must match pegboard grid
skadis_peg_d = 4.5;  // mm, drop-lock nub diameter
skadis_peg_h = 6;    // mm, length poking through the pegboard

// ---- Half-interlock tab ----
tab_w = 3; tab_h = 10; tab_t = frame_t;

module keyhole_leg() {
    translate([0, 0, frame_t])
        cylinder(d = leg_neck_d, h = leg_neck_h, $fn = 24);
    translate([0, 0, frame_t + leg_neck_h])
        cylinder(d = leg_head_d, h = leg_head_h, $fn = 24);
}

module skadis_drop_peg() {
    rotate([180, 0, 0])
        cylinder(d = skadis_peg_d, h = skadis_peg_h, $fn = 20);
}

module frame_ring() {
    difference() {
        cube([frame_w, frame_h, frame_t], center = true);
        cube([frame_w - 2*border, frame_h - 2*border, frame_t + 1], center = true);
    }
}

module full_assembly() {
    union() {
        frame_ring();

        for (x = [-hole_spacing_x/2, hole_spacing_x/2])
            for (y = [-hole_spacing_y/2, hole_spacing_y/2])
                translate([x, y, -frame_t/2])
                    keyhole_leg();

        for (hx = [-frame_w/4, frame_w/4])
            for (x = [-skadis_pitch/2, skadis_pitch/2])
                translate([hx + x, frame_h/2 - 12, -frame_t/2])
                    skadis_drop_peg();

        // interlock tab (left half) / slot is cut from right half below
        translate([-tab_w/2, -tab_h/2, -tab_t/2])
            cube([tab_w, tab_h, tab_t]);
    }
}

module left_half() {
    intersection() {
        full_assembly();
        translate([-frame_w, -frame_h, -frame_t*2])
            cube([frame_w, frame_h*2, frame_t*4]);
    }
}

module right_half() {
    difference() {
        intersection() {
            full_assembly();
            translate([0, -frame_h, -frame_t*2])
                cube([frame_w, frame_h*2, frame_t*4]);
        }
        // slot for left half's interlock tab
        translate([-tab_w/2 - 0.2, -tab_h/2 - 0.2, -tab_t/2 - 0.2])
            cube([tab_w + 0.4, tab_h + 0.4, tab_t + 0.4]);
    }
}

// preview: both halves laid out side by side with a gap
translate([-5, 0, 0]) left_half();
translate([5, 0, 0]) right_half();
