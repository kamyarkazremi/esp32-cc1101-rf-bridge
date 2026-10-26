// ============================================================================
// Minimal-Volume Narrow In-Line Enclosure for ESP32 + TI CC1101 (v4)
// With Positive Mechanical Retention (Snap-In PCB Clips + C-Channel + Lid Pillars)
//
// How Both Boards Are Mechanically Locked (No Loose Friction Fit):
//  1. ESP32 DevKit (Processor Face-Down):
//     - Front Under-Lip Toe Slots: The front corners of the ESP32 PCB tuck
//       under two solid hold-down ledges flanking the USB cutout (X = wall..wall+4mm).
//     - Rear Cantilever Snap Latches: Two 45-degree chamfered snap hooks at the
//       rear corners (X = wall + esp_len) flex outward as you press the back of
//       the ESP32 down, then click over the top of the PCB to lock it in X/Y/Z.
//     - Lid Corner Hold-Down Pillars: 4 pillars extending down from the lid
//       press onto the 4 pin-free corners of the ESP32 PCB when the lid is closed.
//  2. TI CC1101 8-Pin SMA Module:
//     - Full C-Channel Slide/Snap Rails: Captive top & bottom lips grip the 1.6mm
//       CC1101 PCB along its pin-free long edges so it cannot lift or twist.
//     - Rear Snap Catch: A ramped snap tooth behind the CC1101 PCB prevents the
//       module from sliding backward when threading on the SMA antenna.
//     - Lid Hold-Down Ribs: Two ribs on the underside of the lid positively lock
//       the CC1101 edges from above when closed.
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

inner_x    = 90.0;
inner_y    = 29.2;
inner_z    = 24.2;

outer_x    = inner_x + 2 * wall;   // 94.0 mm
outer_y    = inner_y + 2 * wall;   // 33.2 mm
outer_z    = inner_z + floor_t;    // 26.0 mm

// ── ESP32 Face-Down Parameters (X = wall .. wall + 54.5) ────────────────────
esp_len    = 54.5;
esp_rail_w = 1.8;
// When ESP32 is face-down, its PCB underside rests at Z = floor_t + 3.8mm
// (clearing the 3.2mm WROOM-32 shield & USB port), and PCB top is at +1.6mm:
esp_seat_h = 3.8;   // Height of corner/edge support ledges above floor
esp_pcb_t  = 1.7;   // 1.6mm PCB + 0.1mm clearance
esp_top_z  = floor_t + esp_seat_h + esp_pcb_t; // Z = 7.3 mm

// USB Cutout (Left wall X = 0)
usb_y_center = outer_y / 2;
usb_cut_w    = 12.4;
usb_cut_h    = 6.8;
usb_z0       = floor_t + 0.4;

// ── CC1101 In-Line Parameters (X = outer_x - wall - 31.0 .. outer_x - wall) ─
cc_len       = 31.0;
cc_wid       = 17.6; // 17.0mm PCB + 0.6mm clearance
cc_rail_h    = 3.4;  // Clears bottom solder joints on CC1101
cc_pcb_t     = 1.8;  // 1.6mm PCB + 0.2mm clearance
cc_top_z     = floor_t + cc_rail_h + cc_pcb_t; // Z = 7.0 mm
sma_z_center = floor_t + cc_rail_h + 2.5;
sma_hole_d   = 6.7;

// ── Fast 2D Clipper + linear_extrude Helper ─────────────────────────────────
module rounded_box(x, y, z, r) {
    cr = min(r, min(x, y) / 2 - 0.05);
    linear_extrude(height = z, convexity = 4)
        translate([cr, cr])
            offset(r = cr)
                square([x - 2 * cr, y - 2 * cr]);
}

// 45-degree printable snap overhang hook along X (points in +X or -X)
module snap_hook_x(width_y, hook_dx, hook_dz) {
    // Prints without supports: 45-deg bottom ramp, flat locking ledge, 45-deg top lead-in
    polyhedron(
        points = [
            [0, 0, 0],                        // 0: base bottom
            [0, width_y, 0],                  // 1
            [hook_dx, 0, hook_dz * 0.45],     // 2: tip bottom (45-deg printable overhang)
            [hook_dx, width_y, hook_dz * 0.45],// 3
            [hook_dx, 0, hook_dz * 0.65],     // 4: tip top
            [hook_dx, width_y, hook_dz * 0.65],// 5
            [0, 0, hook_dz],                  // 6: base top (45-deg lead-in)
            [0, width_y, hook_dz]             // 7
        ],
        faces = [
            [0, 2, 3, 1],
            [2, 4, 5, 3],
            [4, 6, 7, 5],
            [0, 1, 7, 6],
            [0, 6, 4, 2],
            [1, 3, 5, 7]
        ]
    );
}

// ── Bottom Case Body ────────────────────────────────────────────────────────
module case_bottom() {
    difference() {
        // Outer shell
        rounded_box(outer_x, outer_y, outer_z, corner_r);

        // Main interior cavity
        translate([wall, wall, floor_t])
            rounded_box(inner_x, inner_y, outer_z, max(0.8, corner_r - wall));

        // Top step rabbet for lid alignment (1.0mm wide x 2.2mm deep)
        translate([wall - 0.9, wall - 0.9, outer_z - 2.2])
            rounded_box(inner_x + 1.8, inner_y + 1.8, 2.7, max(1.0, corner_r - wall + 0.9));

        // Deep positive snap-fit receiver grooves on front & back inner walls
        for (y_pos = [wall - 1.35, outer_y - wall + 0.15]) {
            translate([outer_x * 0.20, y_pos, outer_z - 1.6])
                cube([outer_x * 0.60, 1.2, 1.0]);
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

    // ── 1. ESP32 Face-Down Cradle + Toe-In Under-Lips + Rear Snap Latches ───
    // Four corner seat pads (at X=wall..wall+6 and X=wall+esp_len-6..wall+esp_len)
    // support the PCB corners at Z = floor_t + esp_seat_h (3.8mm), plus 1.5mm
    // full-length side rails under the plastic pin strips.
    for (ry = [wall, outer_y - wall - esp_rail_w]) {
        translate([wall, ry, floor_t])
            cube([esp_len, esp_rail_w, 1.5]);
    }
    for (cy = [wall, outer_y - wall - 4.2]) {
        // Front corner seat pad (next to USB cutout, ahead of Pin 1)
        translate([wall, cy, floor_t])
            cube([4.0, 4.2, esp_seat_h]);
        // Front Toe-In Hold-Down Lip (grips top of PCB front corners at Z = esp_top_z)
        translate([wall, cy, esp_top_z - 0.4])
            snap_hook_x(4.2, 2.2, 2.6);

        // Rear corner seat pad (behind last pin)
        translate([wall + esp_len - 3.5, cy, floor_t])
            cube([3.5, 4.2, esp_seat_h]);
        // Rear Cantilever Snap Post + Snap Hook (clicks over back edge of ESP32 PCB!)
        translate([wall + esp_len, cy, floor_t])
            cube([2.0, 4.2, esp_seat_h + esp_pcb_t + 2.8]);
        translate([wall + esp_len, cy + 4.2, esp_top_z - 0.5])
            rotate([0, 0, 180])
                snap_hook_x(4.2, 1.6, 2.6);
    }

    // ── 2. CC1101 Full C-Channel Slide/Snap Cradle + Rear Snap Catch ────────
    cc_x0 = outer_x - wall - 22.0; // Front 22mm of CC1101; rear 9mm (2x4 header) is open
    cc_y0 = (outer_y - cc_wid) / 2;
    for (side = [0, 1]) {
        ledge_y = (side == 0) ? cc_y0 : (cc_y0 + cc_wid - 1.6);
        guide_y = (side == 0) ? (cc_y0 - 1.8) : (cc_y0 + cc_wid);
        // Bottom support ledge under CC1101 long edges
        translate([cc_x0, ledge_y, floor_t])
            cube([22.0, 1.6, cc_rail_h]);
        // Side wall + C-channel top hold-down rail (captive slot for 1.6mm CC1101 PCB)
        translate([cc_x0, guide_y, floor_t])
            cube([22.0, 1.8, cc_top_z + 1.8]);
        translate([cc_x0 + 4.0, (side == 0) ? (cc_y0 - 0.2) : (cc_y0 + cc_wid - 1.2), cc_top_z])
            cube([18.0, 1.4, 1.6]);
    }
    // Rear snap catch behind CC1101 outer corners (prevents CC1101 sliding back from SMA wall)
    for (cy = [cc_y0 - 1.8, cc_y0 + cc_wid - 2.2]) {
        translate([outer_x - wall - cc_len - 1.8, cy, floor_t])
            cube([1.8, 4.0, cc_top_z + 2.2]);
        translate([outer_x - wall - cc_len, cy, cc_top_z - 0.4])
            snap_hook_x(4.0, 1.4, 2.4);
    }
}

// ── Snap-Fit Ventilated Lid + Positive Hold-Down Corner Pillars ─────────────
module case_lid() {
    lip_x = inner_x + 1.5;
    lip_y = inner_y + 1.5;
    lip_r = max(0.8, corner_r - wall + 0.75);
    lip_h = 2.0;
    lip_wall = 1.4;

    // Height of corner hold-down pillars from underside of lid down to PCB top:
    // Total inner height = 24.2mm; ESP32 PCB top is 5.5mm above floor -> 18.4mm pillar
    esp_pillar_h = inner_z - (esp_seat_h + esp_pcb_t) - 0.3;
    cc_pillar_h  = inner_z - (cc_rail_h + cc_pcb_t) - 0.3;
    cc_y0        = (outer_y - cc_wid) / 2;

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

            // Positive snap-fit locking ridges on front & back of skirt
            for (sy = [(outer_y - lip_y) / 2 - 0.35, (outer_y + lip_y) / 2 - 0.35]) {
                translate([outer_x * 0.25, sy, lid_t + lip_h - 0.8])
                    cube([outer_x * 0.50, 0.7, 0.7]);
            }

            // 4 Hold-Down Standoff Pillars for ESP32 pin-free corners
            for (px = [wall + 0.8, wall + esp_len - 3.2]) {
                for (py = [wall + 0.4, outer_y - wall - 3.6]) {
                    translate([px, py, lid_t])
                        cube([2.8, 3.2, esp_pillar_h]);
                }
            }

            // 2 Hold-Down Standoff Pillars for CC1101 front edges (near SMA wall)
            for (py = [cc_y0, cc_y0 + cc_wid - 2.4]) {
                translate([outer_x - wall - 6.0, py, lid_t])
                    cube([5.0, 2.4, cc_pillar_h]);
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
