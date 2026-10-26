// ============================================================================
// Parametric 3D-Printable Enclosure for ESP32 + TI CC1101 433MHz RF Bridge
// v2: Engineered specifically for Female-to-Female Dupont Jumper Wire Clearance
//
// How the Boards Mount (with Dupont Jumper Wires Attached):
//  1. ESP32 DevKit (Center-Spine Pedestal + Dual 21mm Deep Pin Trenches):
//     - Standard ESP32 DevKits have two rows of male pins pointing DOWN along
//       the long edges (25.4mm apart; 22.8mm inner clearance between plugged-in
//       female Dupont housings).
//     - Instead of side ledges that would crash into the header pins, the ESP32
//       PCB rests on a 14.6mm-wide x 21.0mm-tall CENTER SPINE PEDESTAL that runs
//       right between the two pin rows!
//     - Flanking the center spine are two 8.5mm-wide, 21mm-deep open trenches
//       so 14mm female Dupont connectors + 7mm wire bends hang freely below the
//       ESP32 with zero interference.
//     - Corner alignment posts at the pin-free USB/antenna corners + side walls
//       outside the Dupont housings keep the ESP32 locked in alignment with the
//       USB port.
//  2. TI CC1101 8-Pin SMA Module (Slide-In Side Grooves + Open Header Bay):
//     - The CC1101 has no pins on its long edges; all 8 pins are at the rear.
//     - Elevated side C-channel rails hold the CC1101 PCB at Z=18mm while the
//       threaded brass SMA barrel passes through the 6.7mm hole in the right wall
//       (secured from outside by the SMA hex nut / antenna).
//     - The entire rear & underside of the CC1101 2x4 header is 100% open into
//       a wide central jumper-wire routing bay (18mm clearance below AND above).
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
// X = 68.0 mm (fits 55mm ESP32 + USB clearance + jumper routing)
// Y = 64.0 mm (ESP32 bay with dual trenches + central jumper bay + CC1101 bay)
// Z = 36.0 mm (21mm below ESP32 PCB for downward Duponts + 15mm above PCB)
inner_x    = 68.0;
inner_y    = 64.0;
inner_z    = 36.0;

outer_x    = inner_x + 2 * wall;   // 72.8 mm
outer_y    = inner_y + 2 * wall;   // 68.8 mm
outer_z    = inner_z + floor_t;    // 38.2 mm

// ── ESP32 Center-Spine Pedestal Parameters ──────────────────────────────────
esp_len        = 55.0;  // Fits 30-pin (51.5mm) to 38-pin (54.8mm) ESP32 boards
esp_wid        = 29.4;  // Outer width including plugged Dupont housing clearance
esp_spine_w    = 14.4;  // Center pedestal width (fits easily inside 22.8mm gap between Dupont rows)
esp_spine_h    = 21.0;  // 21mm deep trenches on both sides for 14mm Duponts + 7mm wire bend!
esp_y_center   = wall + 3.0 + esp_wid / 2; // Y = 20.1 mm
esp_pcb_z      = floor_t + esp_spine_h;    // Z = 23.2 mm (underside of ESP32 PCB)

// USB Cutout (Left wall X = 0, aligned with ESP32 PCB at Z = esp_pcb_z)
usb_y_center   = esp_y_center;
usb_z_center   = esp_pcb_z + 1.8;
usb_cut_w      = 12.8;
usb_cut_h      = 8.0;
usb_rel_w      = 16.8;
usb_rel_h      = 12.0;
usb_rel_d      = 1.2;

// ── CC1101 Transceiver Bay Parameters ───────────────────────────────────────
// CC1101 PCB is ~17.0mm wide; 2x4 header is at the back (towards X=0), SMA is at X=outer_x
cc_wid         = 17.6;  // 17.0mm PCB + 0.6mm clearance
cc_guide_len   = 20.0;  // Supports only the front 20mm of CC1101; rear 12mm (2x4 header) is 100% open!
cc_ledge_h     = 17.0;  // Elevates CC1101 to Z=19.2mm so 17mm is open below header AND 17mm above!
cc_y_center    = outer_y - wall - 5.0 - cc_wid / 2; // Y = 52.6 mm
sma_z_center   = floor_t + cc_ledge_h + 2.4;
sma_hole_d     = 6.7;   // Standard 1/4"-36 UNS SMA bulkhead thread clearance

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
            rounded_box(inner_x, inner_y, outer_z, max(1.0, corner_r - wall));

        // Top step rabbet for lid alignment (1.1mm wide x 2.4mm deep)
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
                cylinder(d = 12.0, h = 1.0);

        // 3. Lid Pry Notch on Left Wall top edge
        translate([-0.5, outer_y / 2 - 6, outer_z - 1.2])
            cube([wall + 1, 12, 2.0]);

        // 4. Two M3 Keyhole Mounting Slots in Floor
        for (kx = [outer_x * 0.28, outer_x * 0.72]) {
            translate([kx, outer_y / 2 + 4, -0.5]) {
                cylinder(d = 6.4, h = floor_t + 1);
                translate([0, -1.7, 0])
                    cube([5.5, 3.4, floor_t + 1]);
            }
        }
    }

    // ── 1. ESP32 Center-Spine Pedestal & Open Pin Trenches ──────────────────
    // Center Spine supports the middle of the ESP32 PCB (between the 2 pin rows).
    // Two arches are cut through the bottom of the spine so jumper wires from
    // the outer pin row can pass right underneath the spine to the CC1101!
    difference() {
        translate([wall, esp_y_center - esp_spine_w / 2, floor_t])
            cube([esp_len, esp_spine_w, esp_spine_h]);

        // Two generous wire pass-through tunnels under the center spine
        for (tx = [wall + 10, wall + 30]) {
            translate([tx, esp_y_center - esp_spine_w / 2 - 1, floor_t])
                cube([13.0, esp_spine_w + 2, 12.0]);
        }
    }

    // Outer containment walls outside the ESP32 PCB edges (at Z = esp_pcb_z..esp_pcb_z+3.5)
    // Supported by narrow vertical ribs at X=wall (USB end, ahead of Pin 1) and X=wall+esp_len (antenna end)
    for (side = [-1, 1]) {
        y_wall = esp_y_center + side * (esp_wid / 2) + (side > 0 ? 0 : -2.0);
        // Front corner post (at USB end, X = wall .. wall+3.5, ahead of header pins)
        translate([wall, y_wall, floor_t])
            cube([3.5, 2.0, esp_spine_h + 4.0]);
        // Rear corner post (at antenna end, X = wall + esp_len - 2.0 .. wall + esp_len + 2.0)
        translate([wall + esp_len - 1.5, y_wall, floor_t])
            cube([3.5, 2.0, esp_spine_h + 4.0]);
    }

    // Rear PCB end-stop on top of the center spine (at X = wall + esp_len)
    translate([wall + esp_len, esp_y_center - esp_spine_w / 2, floor_t])
        cube([2.2, esp_spine_w, esp_spine_h + 3.8]);

    // ── 2. CC1101 Transceiver Cradle (Open Rear for 2x4 Dupont Header) ──────
    // Supports only the front 20mm of the CC1101 long edges near the SMA port,
    // leaving the rear 2x4 pin header completely open above and below!
    cc_x0 = outer_x - wall - cc_guide_len;
    for (side = [-1, 1]) {
        rail_y = cc_y_center + side * (cc_wid / 2 - 1.8) + (side > 0 ? 0 : 0);
        wall_y = cc_y_center + side * (cc_wid / 2) + (side > 0 ? 0 : -2.0);
        // Under-edge support ledge (1.8mm wide along pin-free long edges)
        translate([cc_x0, (side < 0) ? (cc_y_center - cc_wid / 2) : (cc_y_center + cc_wid / 2 - 1.8), floor_t])
            cube([cc_guide_len, 1.8, cc_ledge_h]);
        // Outer anti-rotation guide wall (prevents CC1101 twisting when tightening SMA nut)
        translate([cc_x0, wall_y, floor_t])
            cube([cc_guide_len, 2.0, cc_ledge_h + 4.5]);
        // Top hold-down lip over the front 8mm near SMA barrel (locks PCB vertically)
        translate([outer_x - wall - 8.0, (side < 0) ? (cc_y_center - cc_wid / 2 - 0.5) : (cc_y_center + cc_wid / 2 - 1.3), floor_t + cc_ledge_h + 2.0])
            cube([8.0, 1.8, 1.8]);
    }
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
            translate([15 + i * 7.0, 14, -0.5])
                linear_extrude(height = lid_t + 1.0, convexity = 2)
                    offset(r = 1.3)
                        square([0.01, outer_y - 28]);
        }

        // Status LED pinhole above ESP32 onboard LED area
        translate([wall + 8.0, usb_y_center, -0.5])
            cylinder(d = 2.6, h = lid_t + 1);
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
