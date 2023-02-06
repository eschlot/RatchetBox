// Ratchet Box inlay 3D printing
// configurable model for OpenSCAD
//



include <BOSL2/std.scad>
include <BOSL2/fnliterals.scad>

$fn=40;

boxWidth=237;      // Width of the box in mm (x-dimension)
boxDepth=112;      // depth of the box (y-dimension)
boxHeight = 34;    // Inner height of the box (z-dimension). Used to align all items 1mm below this height. 
baseHeight = 27;   // The height of the base layer resp. top visible layer.

//-------bore hole preparation and drawing ------------------------------------------------------------------------

// Input format: [outer diameter of the hexNuts, comment, hexNutHeight]
// Output format: [x,y,diameter,comment,hexNutHeight]
function boreHoleCalculationAlongXAxis(arr) = [for (x=arr[0][0]/2+1, // start value for x 
						      i=0; // iterator var      
						    i<len(arr);  // termination
						    // current x+ half of current diameter + half of next diameter (if existing)
						    x= x + arr[i][0]/2 + arr[i+1<len(arr)-1?i+1:i][0]/2+1, 
						      i=i+1) // next iteration
    // [x, 1+ half diameter, diameter,  text,           hexNutHeight]
    [x,    1+arr[i][0]/2,    arr[i][0], str(arr[i][1]), arr[i][2]]];


// Input format: [outer diameter of the hexNuts, comment, hexNutHeight]
// Output format: [x,y,diameter,comment,hexNutHeight]
function boreHoleCalculationAlongYAxis(arr) = [for (y=arr[0][0]/2+1, // start value for y 
						      i=0; // iterator var      
						    i<len(arr);  // termination
						    // current y + half of current diameter + half of next diameter (if existing)
						    y= y + arr[i][0]/2 + arr[i+1<len(arr)-1?i+1:i][0]/2+1, 
						      i=i+1) // next iteration
    // [1+ half diameter, y , diameter,  text,           hexNutHeight]
    [1+arr[i][0]/2,       y , arr[i][0], str(arr[i][1]), arr[i][2]]];



// Input format: [x,y,diameter,comment,hexNutHeight]
module boreHoleDrawing(parameters)
{
  x=parameters[0];
  y=parameters[1];
  d=parameters[2];    // diaMeter
  name=parameters[3];
  hexNutHeight=parameters[4];
    
  lenOfHexNutAboveBaseLayer=(boxHeight-baseHeight)-1;
  boreDepth=hexNutHeight-lenOfHexNutAboveBaseLayer;

  textSize=5; // Posible variation point for the numbers in the bore holes. 
  
  translate([x,y,baseHeight+.01]) // .01 prevents from artifact generation at the top of the cyl generated. 
    cyl(h=boreDepth, d=d, rounding2=-1, anchor=TOP);

  translate([x,y,baseHeight])
    translate([0,-textSize/2,-boreDepth-2])
    color("blue")
    linear_extrude(height=3)
    text(name,size=textSize,halign="center");
}

//-------------- helper mechanisms to calculate and draw tubes in a queue -------------------------------------------------------

// in: [[startPos,dia],[nextPos,dia],...[lastPos,dia]]
// output:[[startDia,endDia,len,pos],...]
function calcContinousTubes(arr) = 
  [for (
        i=1,
	  d1=arr[0][1],
	  d2=arr[1][1],
	  h= arr[1][0] - arr[0][0],
	  pos=arr[0][0];
        i<len(arr);
        i=i+1,
	  d1= arr[i-1][1],
	  d2= arr[i][1], 
	  h=  arr[i][0] - arr[i-1][0],
	  pos=arr[i-1][0]
	  
	) [d1,d2,h,pos]];


//input: [[startDia,endDia,len,pos],...],maxDia
module continousTubes(griffTubes,maxDia) 
  for(p=griffTubes) {
    startDia=p[0]+.5;
    endDia=p[1]+.5;
    length=p[2]+.5;
    pos=p[3];
    spaceAboveBaseLayer=(boxHeight-baseHeight);
    centerPointBelowLid=(maxDia/2)+1;

    translate([0,0,pos]) {
      cyl(l=length,d1=startDia,d2=endDia,anchor=BOTTOM);

      if (centerPointBelowLid>spaceAboveBaseLayer)
	translate([-centerPointBelowLid/2,0,0])
	  {
	    prismoid(size1=[centerPointBelowLid,startDia],
		     size2=[centerPointBelowLid,endDia],
		     h=length);
	  }
    }
}

//-------------------------------------------------------------------------------------

module horizontalHexNuts(x,y,rot,nutDefinitions)
{
  l=[ for (nutDef = nutDefinitions[0],
	     i=0,
	     x_cur=x, // initialize the start position
	     maxDia=max([for (p = nutDefinitions[0][1]) last(p)]); // calculate the maximal Diameter of all tubes of the nut
	   
	   i<len(nutDefinitions);

	   i=i+1, // Order is crucial. First increment the counter to update the variables. 
	     x_cur=x_cur+1.5+max([for (p = nutDefinitions[i][1]) last(p)])/2+maxDia/2, // calculate the advanced position
	     maxDia=max([for (p = nutDefinitions[i][1]) last(p)]) // calculate the maximal Diameter of all tubes of the nut
	   )
      [nutDefinitions[i][0],nutDefinitions[i][1],x_cur,maxDia]]; // build the temporary information
  for (nutDef=l)
    {
      name=nutDef[0];
      nutTubes=nutDef[1];
      x_cur=nutDef[2];
      maxDia=nutDef[3];
      horizontalHexNut(x_cur,y,rot,name,nutTubes,maxDia);
    };
}  

// [x,y,[rotation_x,rotation_y,rotation_z]]
module horizontalHexNut(x,y,rot,name,continousTubes,maxDia)
{
  translate([x,y,boxHeight-maxDia/2-.5])
    rotate(rot){
    tubes=calcContinousTubes(continousTubes);
    continousTubes(tubes,maxDia);

    translate([(maxDia/2)+1,0,1])
      rotate([0,270,0])
      color("blue")
      linear_extrude(height=(maxDia/2)+1)
      text(name, size = maxDia/2.5,halign="left",valign="center"); 
  }
}

//--------------------------------------------------------------------------------------
// x,y and orientation in the room
// The head consists of two simple bore holes and a pie which also can be used as a third bore hole.
// The center axle of the whole ratchet is positioned "positionBelowBaseLayer".

module ratchet(x,y,rotation,
	       headDiameter1,headDepth1,
	       headDiameter2,headDepth2,
	       pieDiameter,pieDepth,pieAngle,
	       positionBelowBaseLayer,
	       gripData)
{
  translate([x,y,baseHeight-positionBelowBaseLayer])
    rotate(rotation)
    {
      additionalHeight=boxHeight-baseHeight+positionBelowBaseLayer;

      translate([0,0,additionalHeight])
	cyl(h=headDepth1+additionalHeight,d=headDiameter1,rounding1=1,anchor=TOP);
      translate([0,0,additionalHeight])
	cyl(h=headDepth2+additionalHeight,d=headDiameter2,rounding1=2,anchor=TOP);
      translate([0,0,-pieDepth])
	{
	  pie_slice(h=pieDepth+additionalHeight,r=pieDiameter/2,
		    ang=pieAngle,spin=[0,0,-pieAngle/2]);
	}
            
      rotate([0,90,0])
	{
	  tubes=calcContinousTubes(gripData);
	  maxDia=max(concat([for (p = tubes) p[0]],[for (p = tubes) p[1]]));
	  continousTubes(tubes,maxDia);
	}
    }
}

//----------------------------------------------------------------------------------------

// offset from the turning center
// diameter at that offset
gripData=[
	    [12,22],
	    [19,22],
	    [20,21],
	    [27,17],
	    [30,17],
	    [35,12],
	    [55,12],
	    [56,22],
	    [60,22],
	    [68,15],
	    [81,21],
	    [92,22],
	    [105,27],
	    [118,22],
	    [129,19],
	    [136,18],
	    [138,0]
	    ];

// outer diameter of the hexNuts, comment
boreHoles1=[
	    [13.5,4,25.5],
	    //[13.5,4.5,25.5],
	    [13.5,5,25.5],
	    [13.5,5.5,25.5],
	    //[13.5,6.5,25.5],
	    //[13.5,6,25.5],
	    [13.5,7,25.5],
	    [13.5,8,25.5],
	    //[14.7,9,25.5],
	    [16,10,25.5],
	    //[17.5,11,25.5],
	    [18.5,12,25.5],
	    [19,13,25.5],
	    ];

boreHoles2=[
	    [9,"",25.5],
	    ];
boreHoles3=[
	    [9,"",25.5],
	    ];
boreHoles4=[
	    [9,"",30.5],
	    ];
boreHoles5=[
	    [9,"",30.5],
	    ];
boreHoles6=[
	    [13.5,"A",25.5],
	    ];



metricHexNuts=[
	       ["4",[[0,12],[32,12],[32.1,6.8],[50.5,6.8]]],
	       ["5",[[0,12],[32,12],[32.1,8],[50.5,8]]],
	       ["5,5",[[0,12],[32,12],[32.1,8.6],[50.5,8.6]]],
	       ["6",[[0,12],[32,12],[32.1,9.4],[50.5,9.4]]],
	       ["7",[[0,12],[32,12],[32.1,10.9],[50.5,10.9]]],
	       ["8",[[0,11.2],[8,11.2],[8.1,12],[50.5,12]]],
	       //["9",[[0,12],[8,12],[8.1,13.2],[50.5,13.2]]],
	       ["10",[[0,12.6],[8,12.6],[8.1,13.9],[50.5,13.9]]],
	       ["11",[[0,14.1],[8,14.1],[8.1,15.9],[50.5,15.9]]],
	       ["12",[[0,15],[8,15],[8.1,16.9],[50.5,16.9]]],
	       ["13",[[0,16.1],[8,16.1],[8.1,18],[50.5,18]]],
	       ];

torxNuts=[
	  ["T20",[[0,12],[18.5,12],[18.6,7.2],[22.5,7.2],[25,4.3],[32.3,4.3]]],
	  ["T25",[[0,12],[18.5,12],[18.6,7.2],[22.5,7.2],[25,4.7],[32.3,4.7]]],
	  ["T27",[[0,12],[18.5,12],[18.6,7.2],[22.5,7.2],[25,5.1],[32.3,5.1]]],
	  ["T30",[[0,12],[18.5,12],[18.6,7.2],[22.5,7.2],[25,5.7],[32.3,5.7]]],
	  ];

normNuts=[
	  ["PH1",[[0,12],[18.5,12],[18.6,7.2],[22.5,7.2],[23.5,4.5],[32.8,4.5]]],
	  ["PH2",[[0,12],[18.5,12],[18.6,7.2],[22.5,7.2],[22.6,6],[32.5,6]]],
	  ["FD4",[[0,12],[18.5,12],[18.6,7.2],[22.5,7.2],[23.7,4],[32.88,4]]],
	  ["FD5,5",[[0,12],[18.5,12],[18.6,7.2],[22.5,7.2],[23.4,5.5],[32.72,5.5]]],
	  ];

hexNuts=[
	 ["Gelenk",[[0,14.1],[28,14.1],[28.1,8.6],[35,8.6]]],
	 ["HX3",[[0,12],[18.5,12],[18.6,7.2],[22.5,7.2],[28.8,3.3],[32.72,3.3]]],
	 ["HX4",[[0,12],[18.5,12],[18.6,7.2],[22.5,7.2],[25,4.6],[32.3,4.6]]],
	 ["HX5",[[0,12],[18.5,12],[18.6,7.2],[22.5,7.2],[25,5.66],[32.3,5.66]]],
	 ["HX6",[[0,12],[18.5,12],[18.6,7.2],[22.5,7.2],[25,6.85],[32.3,6.85]]],
	 ];


extension150=[
	      ["150",[[0,13],[18,13],[18.1,9],[151,9]]]
	      ];

extension100=[
	      ["100",[[0,13],[18,13],[18.1,9],[101,9]]]
	      ];

extension50=[
	     ["50",[[0,13],[18,13],[18.1,9],[51,9]]]
	     ];


// This sets up the complete model: The positive bodies in the
// box. The difference is build below in the main.
module innerBodies ()
{
  boreHoleRawData1 = boreHoleCalculationAlongXAxis(boreHoles1);
  for (b = boreHoleRawData1) {
    boreHoleDrawing(b);
  }

  line_x1=157;
  line_x2=154;
  line_y_inc=11;

  line_y1=51;
  line_y2=line_y1+line_y_inc;
  line_y3=line_y2+line_y_inc;
  line_y4=line_y3+line_y_inc;
  line_y5=line_y4+line_y_inc;
  
  translate([line_x1,line_y1,0])
    {
      boreHoleRawData2 = boreHoleCalculationAlongYAxis(boreHoles2);
      for (b = boreHoleRawData2) {
	boreHoleDrawing(b);
      }
    }
  translate([line_x2,line_y2,0])
    {
      boreHoleRawData3 = boreHoleCalculationAlongYAxis(boreHoles3);
      for (b = boreHoleRawData3) {
	boreHoleDrawing(b);
      }
    }

  translate([line_x1,line_y3,0])
    {
      boreHoleRawData4 = boreHoleCalculationAlongYAxis(boreHoles4);
      for (b = boreHoleRawData4) {
	boreHoleDrawing(b);
      }
    }
  
  translate([line_x2,line_y4,0])
    {
      boreHoleRawData5 = boreHoleCalculationAlongYAxis(boreHoles5);
      for (b = boreHoleRawData5) {
	boreHoleDrawing(b);
      }
    }
  
  translate([line_x1,line_y5,0])
    {
      boreHoleRawData6 = boreHoleCalculationAlongYAxis(boreHoles6);
      for (b = boreHoleRawData6) {
	boreHoleDrawing(b);
      }
    }


  horizontalHexNuts(7.5,110.5,[90,90,0],metricHexNuts);
  horizontalHexNuts(182,110.5,[90,90,0],torxNuts);
  horizontalHexNuts(175,52,[270,90,0],normNuts);  
  horizontalHexNuts(162,14,[270,90,0],hexNuts);
  
  // x,y,rot,len_long,radius_long,len_short,radius_short
  horizontalHexNuts(2,51,[0,90,1],extension150);
  horizontalHexNuts(132.5,8.5,[0,90,0],extension100);
  horizontalHexNuts(229,66,[0,90,270],extension50);    

  ratchet(165-45/2-1.75,32.5,[0,0,180],
	  9,17,
	  25,8,
	  32,6,220,
	  8,
	  gripData);
}


// Main processing from here:

suppressLeft = false;  // For smaller printers: supresses the left half of the model if set to true.
suppressRight = false; // For smaller printers: supresses the right half of the model if set to true.

if (false) { // set this to true to see the positive. Usefull for checking many things
  //  translate([0,0,boxHeight]) cube([boxWidth,boxDepth,0.5]); // Uncomment this to check if the lid of the box is touched by anything.
  translate([0,0,baseHeight]) cube([boxWidth,boxDepth,0.1]); // Uncomment this to check if the lid of the box is touched by anything. 
  innerBodies();
 }
 else {
   difference() {
     {
       difference(){
	 { // Base body
	   diff() cube([boxWidth,boxDepth,baseHeight]) edge_profile() mask2d_roundover(r=1);
	 }
	 innerBodies();
       }
     }

     // masking for smaller printers. 
     if (suppressRight)
       {
	 translate([boxWidth/2,-1,-1])
	   cube([boxWidth/2,boxDepth+2,baseHeight+2]);
	 translate([(boxWidth/2)+1,-1,-1])
	    cube([boxWidth/2,boxDepth+2,baseHeight+2]);
       }
     if (suppressLeft)
       {
	 translate([0,-1,-1])
	   cube([boxWidth/2,boxDepth+2,baseHeight+2]);
	 translate([-1,-1,-1])
	   cube([boxWidth/2,boxDepth+2,baseHeight+2]);
       }
     
     //   translate([0,0,boxHeight]) cube([boxWidth,boxDepth,0.5]); // Uncomment this to check if the lid of the box is touched by anything. 
   }
 }

