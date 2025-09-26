// Customizable Spinning Ring
// by pikafoop (www.pikaworx.com)

/* [Basic Options] */

// : U.S. Ring Size (see Advanced Options to specify diameter in mm)
ring_size = 10; //[0:0.25:16]

//
parts_to_print = 0; // [0:Both, 1:Inner, 2:Outer, 3:Cat]

/* [Advanced Options] */

// (mm)
ring_height = 8;

// (mm) : Override ring size and specify inner diameter; 0 means use ring size
ring_diameter = 16;

// Cat scale; Make sure the cat is aligned to the center of the space
cat_scale = 0.035;

// (mm) : How thin can we print a layer on your printer?
thinnest_layer = 0.8;

// (mm) : Height of the "bump" on the inner ring
bearing_intrusion = 0.6;

// (mm) : Average distance between inner and outer
bearing_gap = 0.4;

/* [Hidden] */

// : How many facets should our rings have?
resolution = 180; // [30:30:180]

// if we don't override the ring size, calculate using https://en.wikipedia.org/wiki/Ring_size#Equations
inner_diameter = ring_diameter ? ring_diameter : 11.63 + 0.8128*ring_size;
echo(inner_diameter=inner_diameter);

ring_thick = thinnest_layer*2 + bearing_gap + bearing_intrusion;
echo(ring_thick=ring_thick);

inner_thin = thinnest_layer;
inner_thick = thinnest_layer+bearing_intrusion;
inner_diff = bearing_intrusion;
inner_ring_poly_points = [
    [0,0], [inner_thin,0], [inner_thick,inner_diff], // increase
    [inner_thick, inner_diff*2], //bend
    [inner_thin, inner_diff*3],
    [inner_thick, ring_height / 2],
    [inner_thin, ring_height-inner_diff*3],
    [inner_thick, ring_height-inner_diff*2],
    [inner_thick,ring_height-inner_diff], // end bend
    [inner_thin,ring_height], [0, ring_height], [0,0] // decrease & return
];

echo(inner_thick=inner_thick);

outer_displacement = inner_thin + bearing_gap;
outer_thick = ring_thick - outer_displacement;
outer_thin = max(outer_thick - bearing_intrusion, 1.0);
outer_diff = bearing_intrusion;
outer_ring_poly_points = [
    [0,0], [outer_thin,0], [outer_thick,outer_diff], // outer increase
    [outer_thick,ring_height-outer_diff], // outer bump
    [outer_thin, ring_height], [0, ring_height], // outer decrease
    
    [outer_diff, ring_height-outer_diff], // inner decrease
    [outer_diff, ring_height-outer_diff*2],
    [0, ring_height-outer_diff*3], //bend
    [outer_diff, ring_height / 2],
    [0, outer_diff*3],
    [outer_diff, outer_diff*2],
    [outer_diff, outer_diff], [0, 0] // inner increase and return
];

echo(outer_displacement=outer_displacement);


if (parts_to_print == 1 || parts_to_print == 0) {
    translate([-inner_diameter/2-ring_thick,0,0]) inner_ring();
}

if (parts_to_print == 2 || parts_to_print == 0) {
    translate([inner_diameter/2+ring_thick,0,0]) custom_outer_ring();
}

if (parts_to_print == 3) {
    // This must be aligned to the center of the space!
    cat_plank();
}

module inner_ring() {
    rotate_extrude($fn=resolution)
        translate([inner_diameter/2,0,0])
        polygon(inner_ring_poly_points);
}

module outer_ring() {
    rotate_extrude($fn=resolution)
        translate( [inner_diameter/2+outer_displacement, 0, 0] )
        polygon(outer_ring_poly_points);
}

// This module creates a single cat.
// It requires you to tell it the radius of the ring it will be placed on.
// This module just creates a long, straight 3D extrusion of the cat SVG.
// We make it longer and taller than the ring to ensure it passes through completely.
module cat_plank() {
    linear_extrude(height = ring_height * 2, center = true) {
         translate([-cat_scale * 104.8, -cat_scale * 104.8, 0]) { 
            scale([cat_scale, cat_scale, 1]) {
                import("cat.svg");
            }
        }
    }
}

module custom_outer_ring() {
    // Use union() to merge the base ring with the cats.
    union() {
        // 1. Start with the original, unmodified outer ring.
        outer_ring();
        
        // --- Add the cats ---
        number_of_cats = 9;
        // Calculate the radius to place the center of the cat plank
        cat_placement_radius = inner_diameter/2 + outer_displacement + outer_thick/2;

        // 2. Loop and add each cat.
        for(i = [0:number_of_cats-1]) {
            
            // For each cat, calculate the intersection of the ring and the cat plank.
            // The result is a cat shape that is perfectly conformed to the ring's surface.
            intersection() {
                
                // Object A: The ring itself. This will act as our mold.
                scale([1.03, 1.03, 1]){
                    outer_ring();
                }
                
                // Object B: The cat plank, transformed into its final position.
                // It is rotated and translated to pass through the ring wall.
                rotate([0, 0, i * 360/number_of_cats]) {
                    translate([cat_placement_radius, 0, ring_height/2]) {
                        rotate([90, 0, -90]) {
                            cat_plank();
                        }
                    }
                }
            }
            
            
        }
    }
}