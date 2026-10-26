// ============================================================================
// Minimal-Volume Narrow In-Line Enclosure for ESP32 + TI CC1101 (v3)
//
// Design Plan & Geometry:
//  - Layout: Narrow single-file in-line stick (Outer: 94.0 x 33.2 x 26.0 mm)
//    -> 58% smaller volume than side-by-side layout!
//  - ESP32 DevKit Orientation: PROCESSOR / WROOM-32 SHIELD FACE-DOWN
//    * The two black plastic header strips along the long edges rest on 1.5mm
//      floor rails along the inner Y walls, giving 4.0mm of clearance in the
//      25.6mm-wide center channel for the 3.2mm WROOM-32 shield & buttons.
//    * All 30/38 male header pins point straight UP (+Z) for easy Dupont
//      jumper connection.
//    * USB port sits low at the front wall (X = 0) right above the floor.
//  - CC1101 + SMA Module Orientation: In-line at the rear wall (X = outer_x)
//    * Centered in a low-profile 17.6mm-wide floor cradle.
//    * Brass SMA threaded bulkhead exits the rear wall (X = outer_x) and locks
//      with the external SMA nut/antenna.
// ============================================================================

$fn = 36;

// Render mode selector (overridden via CLI: -D mode=0 / 1 / 2 / 3)
// 0 = plate (both parts laid flat), 1 = bottom, 2 = lid, 3 = assembly
mode = 0;

// ── Minimal Enclosure Dimensions (mm) ───────────────────────────────────────
wall       = 2.0;
floor_t    = 1.8;
lid_t      = 1.8;
corner_r   = 3.0;

// Internal cavity:
// Y = 29.2 mm (snug fit for 28.5mm wide ESP32 DevKit!)
// X = 90.0 mm (54.5mm ESP32 + 4.5mm gap + 31.0mm CC1101 in-line)
// Z = 24.2 mm (4.0mm processor clearance + 1.6mm PCB + 14mm Dupont + 4.6mm wire arch)
inner_x    = 90.0;
inner_y    = 29.2;
inner_z    = 24.2;

outer_x    = inner_x + 2 * wall;   // 94.0 mm
outer_y    = inner_y + 2 * wall;   // 33.2 mm
outer_z    = inner_z + floor_t;    // 26.0 mm

// ── ESP32 Face-Down Parameters (X = wall .. wall + 54.5) ────────────────────
esp_len    = 54.5;
esp_rail_w = 1.8;   // Supports the outer 1.8mm plastic header strips on both Y sides
esp_rail_h = 1.5;   // + 2.5mm plastic header strip = 4.0mm center clearance for WROOM-32 shield

// USB Cutout (Left wall X = 0, low near floor since ESP32 is face-down)
usb_y_center = outer_y / 2;
usb_cut_w    = 12.4;
usb_cut_h    = 6.8;
usb_z0       = floor_t + 0.4; // Right above the floor where the face-down USB receptacle sits

// ── CC1101 In-Line Parameters (X = outer_x - wall - 31.0 .. outer_x - wall) ─
cc_len       = 31.0;
cc_wid       = 17.6; // 17.0mm PCB + 0.6mm clearance
cc_rail_h    = 3.2;  // Clears bottom solder joints on CC1101
sma_z_center = floor_t + cc_rail_h + 2.5;
sma_hole_d   = 6.7;  // 1/4"-36 UNS SMA bulkhead thread clearance

// ── Fast 2D Clipper + linear_extrude Helper ─────────────────────────────────
module rounded_box(x, y, z, r) {
    cr = min(r, min(x, y) / 2 - 0.05);
    linear_extrude(height = z, convexity = 4)
        translate([cr, cr])
            offset(r = cr)
                square([x - 2 * cr, y - 2 * cr]);
}

// ── Bottom Case Body ────────────────────────────────────────────────────────
module case_bottom() {
    difference() {
        // Outer shell
        rounded_box(outer_x, outer_y, outer_z, corner_r);

        // Main interior cavity
        translate([wall, wall, floor_t])
            rounded_box(inner_x, inner_y, outer_z, max(0.8, corner_r - wall));

        // Top step rabbet for lid alignment (1.0mm wide x 2.0mm deep)
        translate([wall - 0.9, wall - 0.9, outer_z - 2.0])
            rounded_box(inner_x + 1.8, inner_y + 1.8, 2.5, max(1.0, corner_r - wall + 0.9));

        // Snap-fit receiver grooves on front & back inner walls
        for (y_pos = [wall - 1.2, outer_y - wall + 0.2]) {
            translate([outer_x * 0.25, y_pos, outer_z - 1.4])
                cube([outer_x * 0.50, 1.0, 0.8]);
        }

        // 1. Face-Down ESP32 USB Cutout (Left Wall X = 0)
        translate([-1, usb_y_center - usb_cut_w / 2, usb_z0])
            cube([wall + 3, usb_cut_w, usb_cut_h]);
        // Outer USB plug overmold recess
        translate([-0.1, usb_y_center - 15.6 / 2, usb_z0 - 1.0])
            cube([0.9, 15.6, usb_cut_h + 2.4]);

        // 2. SMA Antenna Bulkhead Hole (Right Wall X = outer_x)
        translate([outer_x - wall - 1, outer_y / 2, sma_z_center])
            rotate([0, 90, 0])
                cylinder(d = sma_hole_d, h = wall + 3);

        // 3. Lid Pry Notch on Left Wall top edge
        translate([-0.5, outer_y / 2 - 5, outer_z - 1.0])
            cube([wall + 1, 10, 1.5]);
    }

    // ── 1. Face-Down ESP32 Side Rails & End Stop ────────────────────────────
    // Two slim 1.8mm x 1.5mm rails along the Y walls support the ESP32's plastic
    // header strips while leaving a 25.6mm wide x 4.0mm deep center pocket for
    // the face-down WROOM-32 processor shield & EN/BOOT buttons.
    for (ry = [wall, outer_y - wall - esp_rail_w]) {
        translate([wall, ry, floor_t])
            cube([esp_len, esp_rail_w, esp_rail_h]);
    }
    // Low stop ridge at X = wall + esp_len so ESP32 stays flush against USB wall
    for (ry = [wall, outer_y - wall - 5.0]) {
        translate([wall + esp_len, ry, floor_t])
            cube([1.8, 5.0, esp_rail_h + 4.2]);
    }

    // ── 2. In-Line CC1101 Cradle (Right End near SMA Hole) ──────────────────
    cc_x0 = outer_x - wall - 22.0; // Supports front 22mm of CC1101; rear 2x4 header is open
    cc_y0 = (outer_y - cc_wid) / 2;
    for (side = [0, 1]) {
        ledge_y = (side == 0) ? cc_y0 : (cc_y0 + cc_wid - 1.6);
        guide_y = (side == 0) ? (cc_y0 - 1.6) : (cc_y0 + cc_wid);
        // Bottom support ledge under CC1101 long edges
        translate([cc_x0, ledge_y, floor_t])
            cube([22.0, 1.6, cc_rail_h]);
        // Side anti-rotation guide wall (keeps CC1101 straight when tightening SMA nut)
        translate([cc_x0, guide_y, floor_t])
            cube([22.0, 1.6, cc_rail_h + 3.5]);
    }
}

// ── Snap-Fit Ventilated Lid ─────────────────────────────────────────────────
module case_lid() {
    lip_x = inner_x + 1.5;
    lip_y = inner_y + 1.5;
    lip_r = max(0.8, corner_r - wall + 0.75);
    lip_h = 1.8;
    lip_wall = 1.4;

    difference() {
        union() {
            // Outer top cap plate
            rounded_box(outer_x, outer_y, lid_t, corner_r);

            // Inner rabbet skirt
            translate([(outer_x - lip_x) / 2, (outer_y - lip_y) / 2, lid_t])
                difference() {
                    rounded_box(lip_x, lip_y, lip_h, lip_r);
                    translate([lip_wall, lip_wall, -0.1])
                        rounded_box(lip_x - 2 * lip_wall, lip_y - 2 * lip_wall, lip_h + 0.5, max(0.4, lip_r - lip_wall));
                }

            // Snap ridges on front & back of skirt
            for (sy = [(outer_y - lip_y) / 2 - 0.2, (outer_y + lip_y) / 2 - 0.3]) {
                translate([outer_x * 0.30, sy, lid_t + lip_h - 0.7])
                    cube([outer_x * 0.40, 0.5, 0.6]);
            }
        }

        // Ventilation louver slots across the top
        for (i = [0 : 8]) {
            translate([14 + i * 8.0, 7.5, -0.5])
                linear_extrude(height = lid_t + 1.0, convexity = 2)
                    offset(r = 1.1)
                        square([0.01, outer_y - 15.0]);
        }
    }
}

// ── Output Selector ─────────────────────────────────────────────────────────
if (mode == 1) {
    case_bottom();
} else if (mode == 2) {
    case_lid();
} else if (mode == 3) {
    color("#2b303c") case_bottom();
    color("#3d85c6")
        translate([0, outer_y, outer_z + lid_t])
            rotate([180, 0, 0])
                case_lid();
} else {
    // Default mode == 0 ("plate"): Both parts laid flat side-by-side for single-plate printing
    case_bottom();
    translate([0, outer_y + 6.0, 0])
        case_lid();
}
