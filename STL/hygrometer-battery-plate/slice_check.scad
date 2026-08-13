use <mount_plate.scad>
intersection() {
    door();
    translate([-5, 3.58-0.05, -5]) cube([40, 0.1, 20]);
}
