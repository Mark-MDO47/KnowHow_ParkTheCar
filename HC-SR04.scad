/* HC-SR04 enclosure
   2017-01-20 Mark Olson

*/


// VERY handy routine from WarrantyVoider, published May 26, 2011
use<roundCornersCube.scad> // http://www.thingiverse.com/thing:8812

/*

plate = top of box, rectangle
uson  = ultrasonic sensor HC-SR04
led   = LED strip (8 LEDs)
pot   = trimmer pot in UXcell type package 3362P-103

uson:
    Measured total rectangle skinny 20.25 mm (without connectors)
    Measured total rectangle skinny 26.68 mm (with connectors)
    Measured connector sticks out    6.43 mm (use 10 for room in box)
    Measured total rectangle long   45.55 mm
    Measured center circle to end of connector sticks out = 16.555 mm

    measured inner circle is 16.0
    measured make circle 16.4 mm diameter; 8.2 mm radius
    measured outer edge to outer edge circle 42.3 mm
    measured center circle to circle = 42.3 - 16.4 = 25.9

    measured rect hole bottom to top circle is 16.9 mm us 
    measured rect skinny is 3.6 mm use 3.7 mm
    measured true rect hole nearest to top circle is 16.9 - 3.6 = 13.3 mm
    measured true rect hole center to center circle = 16.9 - (16+3.7)/2 = 7.05 mm
    measured rect wide is 10 mm use 11

*/

wall_width = 2; // mm for plate and for slot and for box
h_slot_clearance       = 1.0;   // mm height clearance for lid fitting with box
w_slot_clearance       = 0.5;   // mm width clearance for lid fitting with box

// Bounding dimensions of entire top plate

plate_totl_height =  8;   // mm including eyes, width of plate, and everything
plate_slot_height =  wall_width;   // mm 
plate_totl_long   = 83.0; // mm 
plate_totl_skinny = 43;   // mm 

box_totl_height   = 25;   // mm including plate_slot_height but not plate_totl_height
box_totl_long     = plate_totl_long + wall_width;
box_totl_skinny   = plate_totl_skinny+2*wall_width;

// position offset of ultrasonic sensor with respect to plate center-to-center

uson_length_offset    =  0.0;   // mm
uson_width_offset     = -6.0;   // mm

// dimensions of ultrasonic sensor portion of plate

uson_otr_eye_radius   = 13.5;  // mm outer_eye
uson_inr_eye_radius   =  8.2;  // mm inner_eye - room for device
uson_otr_eye_nwby     =  4;    // mm factor for outer eye
uson_inr_eye_wdby     =  1;    // mm slope factor for inner eye
uson_eye_ctr2ctr      = 25.9;  // mm center eye circle to circle
uson_rect_skinny      =  3.7;  // mm skinny dimension rectangle hole - room for device
uson_rect_long        = 11;    // mm long dimension rectangle hole - room for device
uson_rect_cnctr_clear = 10;    // mm clearance in skinny direction - includes 2 mm for box slide
uson_eye_rect_ctr2ctr =  7.05; // mm center eye to rect

// position offset of ultrasonic sensor with respect to plate center-to-center

leds_length_offset    = 0.0;   // mm
leds_width_offset     = 12.0;  // mm

// dimensions of LED strip portion of plate

leds_rect_skinny      =  8.45; // mm
leds_rect_long        = 67.1;  // mm
leds_holes_ctr2ctr    = 35.15; // mm (on bottom)
leds_holes_radius     =  1.7;  // mm
leds_cnctr_skinny     =  5.56; // mm (on bottom)
leds_cnctr_long       = leds_rect_long; // mm
leds_cnctr_justone    =  4.5;  // mm (one on each side)
leds_led_skinny       =  5.4;  // mm (on top)
leds_led_long         = 53.9;  // mm

// dimensions of 3362P package trimmer pot

pot_w_clearance       = 0.2;   // mm clearance width
pot_h_clearance       = 0.2;   // mm clearance width
pot_w_outside         = 6.71 + 0.1; // mm outside dimension
pot_h_outside         = 7.04 + 0.1; // mm outside dimension
pot_lead_to_lead      = 2.54;       // mm vert/horiz between leads in x/y direc
pot_h_low_leads       = 3.53 + 0.5*pot_h_clearance; // mm height two leads
pot_h_hi_lead         = 6.07 + 0.5*pot_h_clearance; // mm height one lead
pot_w_low_lead_1      = (pot_w_outside - 2*pot_lead_to_lead)/2 +0.5*pot_w_clearance; // mm
pot_w_hi_lead         = pot_w_low_lead_1 + pot_lead_to_lead; // mm
pot_w_low_lead_2      = pot_w_hi_lead + pot_lead_to_lead; // mm

// dimensions of USB connector
usb_w_outside = 10.7; // mm outer width  of plug going into nano
usb_h_outside =  8.8; // mm outer height of plug going into nano
// 7.4 mm = top to bottom nano




module eye_outer(radius, narrowby, centertocenter, height, myfn) {
    union() {
        // outer eye of ultrasonic sensor is like to volcano walls
        translate([centertocenter/2.0+uson_length_offset,uson_width_offset,0])
            cylinder(r1=radius, r2=radius-narrowby, h=height, $fn=myfn);
        translate([-centertocenter/2.0+uson_length_offset,uson_width_offset,0])
            cylinder(r1=radius, r2=radius-narrowby, h=height, $fn=myfn);
    }
}   // end module eye_outer()

module eye_inner(radius, narrowby, centertocenter, height, myfn) {
    union() {
        // inner eye of ultrasonic sensor is the cutout to hold the microphone/speaker
        translate([centertocenter/2.0+uson_length_offset,uson_width_offset,-0.5])
            cylinder(r1=radius, r2=radius-narrowby, h=height+1, $fn=myfn);
        translate([-centertocenter/2.0+uson_length_offset,uson_width_offset,-0.5])
            cylinder(r1=radius, r2=radius-narrowby, h=height+1, $fn=myfn);
    }
}   // end module eye_inner()

// this module makes a plate for the top with rounded edges near the slot
//     seems to exceed some OpenSCAD limit; does not draw well
module roundrectplate(platelength,platewidth,plateheight,plateround) {
    rotate(v=[0,1,0], a=90) roundCornersCube(plateheight,platewidth,platelength, 1);
}

module plate(totalheight, platelength, platewidth, plateslotheight, bumpheightfract, nothing_bump_triangle) {
    // either do the raised bump or the triangular cutout or neither
    difference() {
        union() {
            translate([0,0,plateslotheight/2.0])
                // using roundCornersCube here would exceed some limit and gets unwanted faces
                // roundrectplate(platelength,platewidth-w_slot_clearance,plateslotheight,platelength, 1);
                cube(size = [platelength,platewidth-w_slot_clearance,plateslotheight], center = true);
            if (nothing_bump_triangle == 1) {
                translate([-(platelength/2)+3.0,0,0.99*totalheight/bumpheightfract]) roundCornersCube(2,0.8*platewidth,totalheight/bumpheightfract, 1);
            }
        }
            if (nothing_bump_triangle == 2) {
                // $fn=3 forces a triangular shape
                translate([-.85*platelength/2,0,1.01*plateslotheight/2.0]) cylinder(plateslotheight/2.0, 5, 7,$fn=3); // triangular cutout
            }
    }
}   // end module plate()

module side(plateslotheight, platelength, platewidth) {
    union() {
        translate([0,0,0.5*plateslotheight]) cube(size = [platelength,platewidth,plateslotheight], center = true);
        translate([0,0,0.77*plateslotheight]) cube(size = [platelength+plateslotheight-0.1,platewidth,0.46*plateslotheight], center = true);
    }
        translate([0,0.5*platewidth-0.25*plateslotheight,0.75*plateslotheight]) cube(size = [platelength,1,1.5*plateslotheight], center = true);
}   // end module side()

module top(totalheight, platelength, platewidth, plateslotheight) {
    difference() {
        union() {
            eye_outer(radius=uson_otr_eye_radius, narrowby=uson_otr_eye_nwby, centertocenter=uson_eye_ctr2ctr, height=totalheight, myfn=64);
            plate (totalheight, platelength, platewidth-plateslotheight/2.0, plateslotheight, bumpheightfract=4.0, nothing_bump_triangle = 1);
            plate (totalheight, platelength, platewidth, plateslotheight/2.0, bumpheightfract=4.0, nothing_bump_triangle = 0);
        }
        union() {
            // cut hole for ultrasonic sensor "eyes"
            eye_inner(radius=uson_inr_eye_radius, narrowby=-uson_inr_eye_wdby, centertocenter=uson_eye_ctr2ctr, height=2+totalheight, myfn=64);
            // cut hole for ultrasonic sensor "can" component
            translate([uson_length_offset,-uson_eye_rect_ctr2ctr+uson_width_offset,0.5*totalheight])
                roundCornersCube(uson_rect_long,uson_rect_skinny,1.1*totalheight,1);
            // cut hole for LED long-skinny rectangle (LEDs shine through this)
            translate([leds_length_offset,leds_width_offset+(leds_rect_skinny-leds_led_skinny)/2+1,0.5*totalheight]) roundCornersCube(leds_led_long+1,leds_led_skinny+1,1.1*totalheight,1);
            // cut two holes to make room for connectors at ends of LEDs
            translate([leds_length_offset+(leds_cnctr_long-leds_cnctr_justone)/2,leds_width_offset-(leds_rect_skinny-leds_cnctr_skinny)/2,0.5*totalheight]) roundCornersCube(leds_cnctr_justone+1,leds_cnctr_skinny+1,1.1*totalheight,1);
            translate([leds_length_offset-(leds_cnctr_long-leds_cnctr_justone)/2,leds_width_offset-(leds_rect_skinny-leds_cnctr_skinny)/2,0.5*totalheight]) roundCornersCube(leds_cnctr_justone+1,leds_cnctr_skinny+1,1.1*totalheight,1);
        }
    }
}   // end module top()


// cut out snippet of ledge
// make indentation for pot_
module box(totalheight, long, skinny, width) {
    difference() {
        // solid cube - we will cut out as needed
        translate([0,0,totalheight/2]) cube(size = [long,skinny,totalheight], center = true);
        // all the cutouts
        union() {
            // FIXME temporary test print
            // translate([-0.1*long,0,totalheight/2]) cube(size = [long, skinny, totalheight], center = true);
            // cutout view enable - 0=none, 1=X(long), 2=Y(skinny)
            cv_enable = 0;
            // cutout view polarity - +1 = +X or +Y, -1 = -X or -Y
            cv_polarity = -1.0;
            if (cv_enable > 0.5) {
                // view cutout into +X long side - not normally present
                translate([cv_polarity*0.9*long,0,totalheight/2]) cube(size = [long, skinny, totalheight], center = true);
            }
            if (cv_enable < -0.5) {
                // view cutout into +Y skinny side - not normally present
                translate([0,cv_polarity*0.9*skinny,totalheight/2]) cube(size = [long, skinny, totalheight], center = true);
            }
            // max width of walls - 2*width for strength at bottom
            translate([0,0,totalheight/2+width]) cube(size = [long-4*(width+0.1),skinny-4*(width+0.1),totalheight], center = true);
            // middle cutout, wall width = 1*width
            translate([0,0,totalheight/2.0]) cube(size = [long-2*(width+0.1),skinny-2*(width+0.1),totalheight-4*width], center = true);
            // cutout for vertical plate - narrow first
            translate([0,skinny/2-0.5*(width+0.1),totalheight/2+(width+0.1)]) cube(size = [long-2*(width+0.1),1*(width+0.1),totalheight], center = true);
            // cutout for vertical plate - wide
            translate([0,skinny/2-0.75*(width+0.1),totalheight/2+(width+0.1)]) cube(size = [long-1*(width+0.1),0.5*(width+0.1),totalheight], center = true);
            // cutout snippets near top
            translate([0,skinny/2-(width+0.2),totalheight]) cube(size = [long-2*width,2*width,2*width], center = true);
            translate([0,skinny/2-1.1*width,totalheight-width]) cube(size = [long-4*(width+0.1),2*width,2*width], center = true);
            // cutout for top plate - a little wide and high - wide part first
            translate([width,0,totalheight-0.75*width]) cube(size = [plate_totl_long+width,skinny-2*(width+0.1),(width+h_slot_clearance)/2.0], center = true);
            translate([width,0,totalheight-0.25*width]) cube(size = [plate_totl_long+width,skinny-3*(width+0.1),(width+h_slot_clearance)/2.0], center = true);
            // cutout final snippet near top of wall with wire holes
            translate([long/2,skinny/2,totalheight-0.5*width]) cube(size = [3*width,4*width,width+h_slot_clearance/2], center = true);

            // cutout for usb cable
            translate([long/2,skinny/5,2*width+pot_h_clearance+(usb_h_outside+pot_h_clearance)/2]) cube(size = [8*wall_width,usb_w_outside+pot_w_clearance,usb_h_outside+pot_h_clearance], center = true);

            // cutout for pot: Uxcell package type 3362P-103 trimmer potentiometer
            translate([long/2,-skinny/5,(totalheight-2*width)/wall_width]) cube(size = [wall_width,pot_w_outside+pot_w_clearance,pot_h_outside+pot_h_clearance], center = true);
            // through-holes for 3 leads for pot
            lower_left_w = -skinny/5-(pot_w_outside+pot_w_clearance)/2;
            lower_left_h = (totalheight-2*width)/2-(pot_h_outside+pot_h_clearance)/2;
            translate([long/2,lower_left_w+pot_w_low_lead_1,lower_left_h+pot_h_low_leads]) rotate(v=[0,1,0], a=90) cylinder(r=0.6,h=4*wall_width,center=true,$fn=32);
            translate([long/2,lower_left_w+pot_w_hi_lead,lower_left_h+pot_h_hi_lead]) rotate(v=[0,1,0], a=90) cylinder(r=0.6,h=4*wall_width,center=true,$fn=32);
            translate([long/2,lower_left_w+pot_w_low_lead_2,lower_left_h+pot_h_low_leads]) rotate(v=[0,1,0], a=90) cylinder(r=0.6,h=4*wall_width,center=true,$fn=32);
            // through-holes to fit bumps in pot
            pot_bump_halfsize = (1.02+0.2)/2; // mm size of holes for bumps
            translate([long/2,lower_left_w+pot_bump_halfsize,lower_left_h+pot_bump_halfsize]) cube(size = [3*wall_width,2*pot_bump_halfsize,2*pot_bump_halfsize], center = true);
            translate([long/2,lower_left_w+pot_w_outside+pot_w_clearance-pot_bump_halfsize,lower_left_h+pot_bump_halfsize]) cube(size = [3*wall_width,2*pot_bump_halfsize,2*pot_bump_halfsize], center = true);
            translate([long/2,lower_left_w+pot_bump_halfsize,lower_left_h+pot_h_outside+pot_h_clearance-pot_bump_halfsize]) cube(size = [3*wall_width,2*pot_bump_halfsize,2*pot_bump_halfsize], center = true);
            translate([long/2,lower_left_w+pot_w_outside+pot_w_clearance-pot_bump_halfsize,lower_left_h+pot_h_outside+pot_h_clearance-pot_bump_halfsize]) cube(size = [3*wall_width,2*pot_bump_halfsize,2*pot_bump_halfsize], center = true);
        }
    }
}

// top(totalheight = plate_totl_height, plateslotheight = plate_slot_height, platelength=plate_totl_long, platewidth=plate_totl_skinny-1.5*w_slot_clearance);
// box(totalheight = box_totl_height, long=box_totl_long, skinny=box_totl_skinny, width=wall_width);
side(plateslotheight = plate_slot_height, platelength=plate_totl_long-1*(wall_width+0.1), platewidth=box_totl_height-1*(wall_width+0.1));

