// ============================================================================
// Parametric 3D-Printable Enclosure for ESP32 + TI CC1101 433MHz RF Bridge
// Designed for zero-support FDM printing (Bambu Lab A1 / PLA / PETG)
//
// Features:
//  - Dedicated ESP32 DevKit bay (fits 30-pin & 38-pin CH340 boards up to 55x29.2mm)
//  - Dedicated TI CC1101 8-pin SMA transceiver bay with anti-rotation PCB cradle
//  - Rear 6.6mm SMA antenna bulkhead port + outer hex nut/washer flat
//  - Front USB-C / Micro-USB port cutout with deep overmold plug relief
//  - Generous 28mm internal height for female-to-female Dupont jumper routing
//  - Snap-fit ventilated lid with status LED window & pry slot
//  - Optional rear/bottom M3 keyhole mounting slots
// ============================================================================

$fn = 36;

// Render mode selector (overridden via CLI: -D mode=0 / 1 / 2 / 3)
// 0 = plate (both parts laid flat), 1 = bottom, 2 = lid, 3 = assembly
mode = 0;

// ── Enclosure Dimensions (mm) ───────────────────────────────────────────────
wall       = 2.4;
floor_t    = 2.2;
lid_t      = 2.2;
corner_r   = 4.0;

// Internal cavity:
// X = 64.0 mm (fits 55mm ESP32 + clearance)
// Y = 54.0 mm (ESP32 bay Y=0..31, jumper channel, CC1101 bay Y=34..54)
// Z = 28.0 mm (fits seated PCB + vertical Dupont connectors + wire bend radius)
inner_x    = 64.0;
inner_y    = 54.0;
inner_z    = 28.0;

outer_x    = inner_x + 2 * wall;   // 68.8 mm
outer_y    = inner_y + 2 * wall;   // 58.8 mm
outer_z    = inner_z + floor_t;    // 30.2 mm

// ── ESP32 DevKit Cradle Parameters ──────────────────────────────────────────
esp_len    = 55.2;  // Accommodates 51.5mm - 54.8mm 30/38-pin ESP32 boards
esp_wid    = 29.2;  // Accommodates 28.0mm - 28.8mm wide ESP32 boards
esp_ledge  = 3.5;   // Height of PCB support rails above floor (clears bottom pins/solder)
esp_rail_w = 2.0;   // Width of support ledge under PCB edges
esp_y0     = wall + 2.0; // Y start of ESP32 pocket

// USB Cutout (Left wall X = 0, centered on ESP32 Y center)
usb_y_center = esp_y0 + esp_wid / 2;
usb_z_center = floor_t + esp_ledge + 1.6; // PCB top + USB receptacle center
usb_cut_w    = 12.6;
usb_cut_h    = 7.6;
usb_rel_w    = 16.5;
usb_rel_h    = 11.5;
usb_rel_d    = 1.2;

// ── CC1101 Transceiver Bay Parameters ───────────────────────────────────────
// CC1101 PCB is ~17.0mm wide x 31mm long (plus SMA threads protruding out X=outer_x)
cc_wid     = 17.8;  // 17.0mm PCB + 0.8mm clearance
cc_len     = 33.0;
cc_ledge   = 5.0;   // Elevates CC1101 so SMA center aligns nicely with rear wall
cc_y0      = outer_y - wall - 3.0 - cc_wid; // Y start of CC1101 pocket
cc_y_center = cc_y0 + cc_wid / 2;
sma_z_center = floor_t + cc_ledge + 2.5;
sma_hole_d   = 6.7;  // Standard 1/4"-36 UNS SMA bulkhead thread clearance

// ── Helper Modules (Fast 2D Clipper + linear_extrude) ───────────────────────
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
        union() {
            // Outer shell
            rounded_box(outer_x, outer_y, outer_z, corner_r);
        }

        // Main interior cavity
        translate([wall, wall, floor_t])
            rounded_box(inner_x, inner_y, outer_z, max(1.0, corner_r - wall));

        // Top step rabbet for lid alignment (1.2mm deep x 2.2mm tall)
        translate([wall - 1.1, wall - 1.1, outer_z - 2.4])
            rounded_box(inner_x + 2.2, inner_y + 2.2, 3.0, max(1.5, corner_r - wall + 1.1));

        // Snap-fit receiver grooves on front & back inner walls
        for (y_pos = [wall - 1.4, outer_y - wall + 0.2]) {
            translate([outer_x * 0.25, y_pos, outer_z - 1.6])
                cube([outer_x * 0.50, 1.2, 0.9]);
        }

        // 1. USB Cutout (Left Wall X = 0)
        translate([-1, usb_y_center - usb_cut_w / 2, usb_z_center - usb_cut_h / 2])
            cube([wall + 3, usb_cut_w, usb_cut_h]);
        // USB Overmold Plug Relief on outside of Left Wall
        translate([-0.1, usb_y_center - usb_rel_w / 2, usb_z_center - usb_rel_h / 2])
            cube([usb_rel_d, usb_rel_w, usb_rel_h]);

        // 2. SMA Antenna Bulkhead Hole (Right Wall X = outer_x)
        translate([outer_x - wall - 1, cc_y_center, sma_z_center])
            rotate([0, 90, 0])
                cylinder(d = sma_hole_d, h = wall + 3);
        // Flat washer/nut seating recess on exterior of Right Wall
        translate([outer_x - 0.6, cc_y_center, sma_z_center])
            rotate([0, 90, 0])
                cylinder(d = 11.5, h = 1.0);

        // 3. Lid Pry Notch on Left Wall top edge
        translate([-0.5, outer_y / 2 - 6, outer_z - 1.2])
            cube([wall + 1, 12, 2.0]);

        // 4. Two M3 Keyhole Mounting Slots in Floor
        for (kx = [outer_x * 0.28, outer_x * 0.72]) {
            translate([kx, outer_y / 2, -0.5]) {
                cylinder(d = 6.4, h = floor_t + 1);
                translate([0, -1.7, 0])
                    cube([5.5, 3.4, floor_t + 1]);
            }
        }
    }

    // ── Internal ESP32 Cradle Rails ─────────────────────────────────────────
    // Left edge stop (keeps USB flush with inner X=wall)
    // Two long Y rails supporting the long edges of the ESP32 PCB
    for (ry = [esp_y0 - 1.2, esp_y0 + esp_wid - esp_rail_w]) {
        translate([wall, ry, floor_t])
            cube([esp_len, esp_rail_w, esp_ledge]);
    }
    // Guide walls outside ESP32 long edges
    translate([wall, esp_y0 - 1.6, floor_t])
        cube([esp_len, 1.6, esp_ledge + 3.2]);
    translate([wall, esp_y0 + esp_wid, floor_t])
        cube([esp_len, 1.8, esp_ledge + 3.2]);
    // End stop at X = wall + esp_len
    translate([wall + esp_len, esp_y0 - 1.6, floor_t])
        cube([2.0, esp_wid + 3.4, esp_ledge + 2.5]);

    // ── Internal CC1101 Transceiver Cradle ──────────────────────────────────
    cc_x0 = outer_x - wall - cc_len;
    // Two support rails under CC1101 long edges (leaves center open for bottom header solder joints)
    translate([cc_x0, cc_y0, floor_t])
        cube([cc_len, 2.0, cc_ledge]);
    translate([cc_x0, cc_y0 + cc_wid - 2.0, floor_t])
        cube([cc_len, 2.0, cc_ledge]);
    // Side guide walls to prevent CC1101 rotation when tightening SMA antenna
    translate([cc_x0, cc_y0 - 1.8, floor_t])
        cube([cc_len, 1.8, cc_ledge + 3.5]);
    translate([cc_x0, cc_y0 + cc_wid, floor_t])
        cube([cc_len, 1.8, cc_ledge + 3.5]);
    // Backstop behind CC1101 2x4 header (with cutout for jumper wires)
    translate([cc_x0 - 2.0, cc_y0 - 1.8, floor_t])
        cube([2.0, 4.5, cc_ledge + 2.5]);
    translate([cc_x0 - 2.0, cc_y0 + cc_wid - 2.7, floor_t])
        cube([2.0, 4.5, cc_ledge + 2.5]);
}

// ── Snap-Fit Ventilated Lid ─────────────────────────────────────────────────
// Designed in printable orientation (top face on Z=0 build plate, lip facing +Z)
module case_lid() {
    lip_x = inner_x + 1.8; // 0.2mm clearance per side inside rabbet
    lip_y = inner_y + 1.8;
    lip_r = max(1.2, corner_r - wall + 0.9);
    lip_h = 2.2;
    lip_wall = 1.6;

    difference() {
        union() {
            // Outer top cap plate
            rounded_box(outer_x, outer_y, lid_t, corner_r);

            // Inner rabbet skirt
            translate([(outer_x - lip_x) / 2, (outer_y - lip_y) / 2, lid_t])
                difference() {
                    rounded_box(lip_x, lip_y, lip_h, lip_r);
                    translate([lip_wall, lip_wall, -0.1])
                        rounded_box(lip_x - 2 * lip_wall, lip_y - 2 * lip_wall, lip_h + 0.5, max(0.5, lip_r - lip_wall));
                }

            // Snap ridges on front & back of skirt
            for (sy = [(outer_y - lip_y) / 2 - 0.25, (outer_y + lip_y) / 2 - 0.35]) {
                translate([outer_x * 0.30, sy, lid_t + lip_h - 0.9])
                    cube([outer_x * 0.40, 0.6, 0.7]);
            }
        }

        // Ventilation louver slots across the top (fast 2D offset + linear_extrude)
        for (i = [0 : 6]) {
            translate([14 + i * 6.5, 12, -0.5])
                linear_extrude(height = lid_t + 1.0, convexity = 2)
                    offset(r = 1.3)
                        square([0.01, outer_y - 24]);
        }

        // Status LED pinhole above ESP32 onboard LED area
        translate([wall + 8.0, usb_y_center, -0.5])
            cylinder(d = 2.4, h = lid_t + 1);
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
    translate([0, outer_y + 8.0, 0])
        case_lid();
}
