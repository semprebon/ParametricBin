include <OpenScadLibraries/Association.scad>

// Parametric Bins

// Inside dimensions of drawer (mm) in large Korean medicine chest: 202 x 120.5 x 72
// Inside dimensions of drawer (mm) in small Korean medicine chest: 180 x 71 x 43

// Large Chest
//LENGTH = 98; // two trays per layer
//HEIGHT = 35; // 2 trays high in drawer
//WIDTH = 119; // 1 tray across

// Small Chest small drawers

LENGTH = 87; // two trays per layer
HEIGHT = 40; // 1 trays high in drawer
WIDTH = 69; // 1 tray across

//LABEL_WIDTH = 12.5;
LABEL_WIDTH = 0;

THICKNESS = 1.6;
BEVEL = 2.4;

TOLERANCE = 0.2;
SLOP = 0.001;

module beveler(size) {
    union() {
        cylinder(h=size, r1=size, r2=0, center=false);
        rotate([180,0,0]) cylinder(h=size, r1=size, r2=0, center=false);
    }
}

module beveled_block(size, bevel=THICKNESS/4) {
    base_size = size - [2*bevel,2*bevel,2*bevel];
     translate([0, 0, base_size.z/2+bevel]) {
        minkowski() {
            cube(base_size, center=true);
            beveler(size=bevel);
        }
     }
}

module stacking_block(size) {
    difference() {
        beveled_block([size.x, size.y, size.z+BEVEL], bevel=BEVEL);
        children();
        translate([0,0,size.z-0.8*BEVEL]) beveled_block(size*(1+SLOP), bevel=BEVEL);
        translate([0,0,size.z+THICKNESS]) cube([size.x*1.5,size.y*1.5,2*THICKNESS], center=true);
    }
}

module label_pad(size, label_width) {
    intersection() {
        translate([-size.x/2, 0, size.z-0.5*BEVEL-TOLERANCE]) rotate([-90,0,0]) linear_extrude(height=size.y, center=true) {
            polygon([[0,0], [label_width, 0], [0, label_width],[0,0]]);
        }
        beveled_block(size, bevel=BEVEL);
    }
}

module base_tray(size) {
    stacking_block(size) {
        translate([0,0,THICKNESS]) beveled_block([size.x-2*THICKNESS, size.y-2*THICKNESS, 2*size.z], bevel=BEVEL);
    }
}

// Distribute items with given size over a specific span, returning the number of items
function distribution_count(size, gap, span) =
    floor((span + gap) / (size + gap));
//function distribution_count(size, gap, span) = 1;

// Distribute items with given size over a specific span, returning the offset of the first item
function distribution_offset(size, gap, span) =
    (span - (distribution_count(size, gap, span) * (size + gap) - gap)) / 2;

/**
 Creates a square array of square prisms that fit into a cube of the
 specified size. The prisms are parallel to the Z-axis. The bounding cube is
 centered on the z axis and rises up from the x/y plane.
*/
module mesh_cutter(size, hole_size=2, solid_size) {
    d = hole_size + solid_size;
    counts = [ for (i = [0,1]) distribution_count(hole_size, solid_size, size[i]) ];
    offsets = [ for (i = [0,1]) distribution_offset(hole_size, solid_size, size[i]) - size[i]/2 ];
    echo(size=hole_size, gap=solid_size, spans=size, counts=counts, offsets=offsets);
    echo(check_x=counts.x*hole_size + (counts.x-1)*solid_size + 2*offsets.x, check_y=counts.y*hole_size + (counts.y-1)*solid_size + 2*offsets.y);
    for (i = [0:(counts.x-1)]) {
        for (j = [0:(counts.y-1)]) {
            translate([offsets.x + d*i, offsets.y + d*j]) cube([hole_size, hole_size, size.z]);
        }
    }
}

/**
 Creates a square array of diamond-shaped prisms that fit into a cube of the
 specified size. The prisms are parallel to the x-axis. The bounding cube is
 centered on the z axis and rises up from the x/y plane.
*/
module diagonal_mesh_cutter(size, hole_size=2, solid_size) {
    new_size_2d = ((size.x+size.z)/sqrt(2) * [1,1,0]);
    new_size = new_size_2d + [0,0,size.y];
    echo("diagonal_mesh_cutter: ", size=size, new_size_2d=new_size_2d, new_size=new_size);
    translate([0,0,size.z/2]) intersection() {
        rotate([0,90,0])
            rotate([0,0,45]) translate([0,0,-new_size.z/2]) mesh_cutter(new_size, hole_size, solid_size);
        cube(size, center=true);
    }
}

module compartment_cutter(size) {
    echo("compartment_cutter: ", size=size);
    translate([0,0,THICKNESS]) beveled_block([size.x, size.y, 2*size.y], bevel=BEVEL);
    translate([0,0,-SLOP]) mesh_cutter([size.x, size.y-THICKNESS, 2*size.y],
        hole_size=4, solid_size=1);
    translate([size.x/2,0,BEVEL+THICKNESS]) {
        diagonal_mesh_cutter([size.x, size.y-THICKNESS, size.z-2*BEVEL-THICKNESS],
            hole_size=4, solid_size=1);
    }
}

module basic_tray(size) {
    bin_size = [ size.x-2*THICKNESS, size.y - 2*THICKNESS, size.z ];
    label_pad(size, LABEL_WIDTH);
    stacking_block(size) {
        translate([0,0,0]) compartment_cutter(bin_size);
    }
}

module divided_tray(size) {
    bin_length = (size.x-3*THICKNESS)/2;
    bin_offset = (bin_length + THICKNESS) / 2;
    label_pad(size, LABEL_WIDTH);
    stacking_block(size) {
        translate([bin_offset,0,0]) compartment_cutter([bin_length, size.y-2*THICKNESS]);
        translate([-bin_offset,0,0]) compartment_cutter([bin_length, size.y-2*THICKNESS]);
    }
}

module divided_tray2(size) {
    bin_size = [ size.x-2*THICKNESS, (size.y - 3*THICKNESS) / 2 ];
    bin_offset = [ 0, (bin_size.y + THICKNESS) / 2 ];
    stacking_block(size) {
        translate([bin_offset.x, bin_offset.y]) compartment_cutter(bin_size);
        translate([bin_offset.x, -bin_offset.y, 0]) compartment_cutter(bin_size);
    }
}

module quad_tray(size) {
    bin_size = [ for (v = size) v-3*THICKNESS ] / 2;
    bin_offset = [ for (v = bin_size) (v + THICKNESS) / 2 ];
    stacking_block(size) {
        translate([bin_offset.x, bin_offset.y, 0]) compartment_cutter(bin_size);
        translate([-bin_offset.x, bin_offset.y, 0]) compartment_cutter(bin_size);
        translate([bin_offset.x, -bin_offset.y, 0]) compartment_cutter(bin_size);
        translate([-bin_offset.x, -bin_offset.y, 0]) compartment_cutter(bin_size);
    }
}

//translate([LENGTH/2,0,0]) cube([LENGTH, WIDTH, HEIGHT]);
//beveled_block([LENGTH, WIDTH, HEIGHT], bevel=BEVEL);

//stacking_block([LENGTH, WIDTH, HEIGHT]);
//divided_tray2([WIDTH, LENGTH, HEIGHT]);
//label_pad([10, LENGTH, 10]);
//basic_tray([LENGTH, WIDTH, HEIGHT]);
// time with mesh: 45s;  no mesh: 0s

//diagonal_mesh_cutter(size=[LENGTH, WIDTH, HEIGHT], hole_size=3, solid_size=2);
//quad_tray([WIDTH, LENGTH, HEIGHT]);
//divided_tray([WIDTH, LENGTH, HEIGHT]);
//divided_tray([25, 20, 7]);

// Pencil holder
// with side, bottom mesh: render: 2:22; print: 10:22:00, $1.39
// with just bottom mesh: render: 0:02; print: 9:16:00, $1.69
basic_tray([30,40,40]);

//gap = 2;
//size = 2;
//span = 10;
//count = distribution_count(size, gap, span);
//offset = distribution_offset(size, gap, span);
//echo(size=size, gap=gap, span=span, count=count, offset=offset, check=count*size + (count-1)*gap);
//mesh_cutter([span, span, 100], hole_size=size, solid_size = gap);
////#cube([span, span, 100]);
//#translate([0,0,50]) cube([span, span, 100], center=true);