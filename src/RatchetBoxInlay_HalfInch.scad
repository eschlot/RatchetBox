// Ratchet Box inlay 3D printing
// configurable model for OpenSCAD
//



include <BOSL2/std.scad>
include <BOSL2/fnliterals.scad>

$fn=40;

boxWidth=440;      // Width of the box in mm (x-dimension)
boxDepth=149;      // depth of the box (y-dimension)
boxHeight = 44;    // Inner height of the box (z-dimension). Used to align all items 1mm below this height. 
baseHeight = 32.5;   // The height of the base layer resp. top visible layer.

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


//input: [[startDia,endDia,len,pos],...]
module continousTubesManual(griffTubes) 
  for(p=griffTubes) {
    startDia=p[0]+.5;
    endDia=p[1]+.5;
    length=p[2]+.5;
    pos=p[3];

    translate([0,0,pos]) {
      cyl(l=length,d1=startDia,d2=endDia,anchor=BOTTOM);
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
	       handleData)
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
	  tubes=calcContinousTubes(handleData);
	  maxDia=max(concat([for (p = tubes) p[0]],[for (p = tubes) p[1]]));
	  continousTubes(tubes,maxDia);
	}
    }
}

//----------------------------------------------------------------------------------------

// offset from the turning center of the ratchet
// diameter of the handle at that offset
handleData=[
	    [0,44],
	    [36,37],
	    [49,16],
	    [137,16],
	    [137.1,21],
	    [163,25],
	    [185,32],
	    [210,34],
	    [244,31],
	    [246,24],
	    [248,14],
	    [254,0],
	    ];

// outer diameter of the hexNuts, comment, length of the hexNut
boreHoles1=[
	    [24,"11",36.5],
	    [24.2,"12",38.3],
	    [23.8,"13",36.5],
	    [24,"14",36.8],
	    [24,"15",36.8],
	    [27,"17",38.65],
	    [27.6,"18",40],
	    [28,"19",38.65],
	    [29.6,"21",38],
	    [32,"22",38.4],
	    [34,"24",38.4],
	    [38,"27",40],
	    [42,"30",40.2],
	    [44,"32",40.2],
	    ];

// outer diameter of the hexNuts, comment, length of the hexNut
boreHoles2=[
	    [25,"3/8",36.2],
	    ];

// outer diameter of the hexNuts, comment, length of the hexNut
boreHoles3=[
	    [24.7,"10",37.7],
	    ];


// [Comment,[[pos, diameter@position],[pos, diameter@position],...     ]
metricHexNuts1=[
		["13",[[0,23],[41.5,23],[46,21],[81,21]]],
		["16",[[0,24],[26,24],[27,24],[66,24]]],
		["17",[[0,26],[82,26]]],
		["21",[[0,28],[14,28],[14.1,29],[64,29]]],
		];

metricHexNuts2=[
		["1/4",[[0,17],[21,17.5],[25,11],[41,11],[48,8],[71,8]]],
		];

metricHexNuts3=[

	       ["Gelenk",[[0,26],[54,26],[56,17],[75,17]]],	      
	       ];

metricHexNuts4=[
	       ["VZ8",[[0,24],[22,24],[26.5,16],[39.0,16.0],[39.1, 8],[55,8]]],
	       ["HX12",[[0,25],[22,25],[24.5,23.5],[39.9,23.5],[40, 14.5],[62,14.5]]],
		];

metricHexNuts5=[

	       ["HX6",[[0,23],[20.5,23],[25,17],[39,17],[39.1,10],[45,10],[48,8],[57,8]]],
		];


extension125=[
	      ["125",[[0,24],[21,24],[28,16],[99,16],[99.1,18],[125,18]]]
	      ];

extension250=[
	      ["250",[[0,25],[23,25],[29,16],[226,16],[226.1,18],[252,18]]]
	      ];


fixedHandle=
	     [[0,15],[292,15]]
	     ;
fixedHandleMiddlePart=
  [[0,25],[27,25],[27.1,18],[43,18]];


	     

// This sets up the complete model: The positive bodies in the
// box. The difference is build below in the main.
module innerBodies () {
  translate([boxWidth-2,boxDepth-2,0]) {
    rotate([0,0,180]) {
      boreHoleRawData1 = boreHoleCalculationAlongXAxis(boreHoles1);
      for (b = boreHoleRawData1) {
        boreHoleDrawing(b);
      }
    }
  }

  translate([345,2,0]) {
    boreHoleRawData2 = boreHoleCalculationAlongYAxis(boreHoles2);
    for (b = boreHoleRawData2) {
      boreHoleDrawing(b);
    }
  }
  
  translate([302,93,0]) {
    boreHoleRawData3 = boreHoleCalculationAlongYAxis(boreHoles3);
    for (b = boreHoleRawData3) {
      boreHoleDrawing(b);
    }
  }

  translate([boxWidth-2,98,0]) rotate([0,0,270])  horizontalHexNuts(0,0,[0,90,270],metricHexNuts1);
  translate([290,80,0]) rotate([0,0,0]) horizontalHexNuts(0,0,[0,90,0],metricHexNuts2);
  translate([132,39,0]) rotate([0,0,90]) horizontalHexNuts(0,0,[0,90,270],metricHexNuts3);
  translate([335,65,0]) rotate([0,0,180]) horizontalHexNuts(0,0,[0,90,90],metricHexNuts4);
  translate([284,2,0]) rotate([0,0,90]) horizontalHexNuts(0,0,[0,90,0],metricHexNuts5);

  
  // A ratchet
  ratchet(256,67,[0,0,180],
	  18,27,
	  44,10,
	  1,1,1,
	  5,
	  handleData);

  // Extensions are also modelled in the same way    
  horizontalHexNuts(128,39,[0,90,180],extension125);    

  // Extensions are also modelled in the same way
  horizontalHexNuts(2,15,[0,90,0],extension250);    

  // ------------------------------------------------------------------------
  pos_x=8;
  pos_y=91;
  pos2_x=pos_x+ 255;
  pos2_y=pos_y;

  rotate([0,0,2.9]){
    translate([pos_x,pos_y,baseHeight]){
      rotate([0,90,0]){
	tubes=calcContinousTubes(fixedHandle);
	continousTubesManual(tubes);
      }
    }
    translate([pos2_x,pos2_y,baseHeight+7.5+6.5]){
      rotate([180,0,0]){
	tubes=calcContinousTubes(fixedHandleMiddlePart);
	continousTubesManual(tubes);
      }
    }
  }
  
}


// Main processing from here:

numPartsX = 3;
numPartsY = 1;

showPartXColumn = -1; // For smaller printers: supresses all part but the one numered here Range: [0 , numPartsX-1]. -1 --> nothing is suppressed
showPartYRow = -1;    // For smaller printers: supresses all part but the one numered here.Range: [0 , numPartsY-1]. -1 --> nothing is suppressed

if (false) { // set this to true to see the positive. Usefull for checking many things
  //translate([0,0,boxHeight]) cube([boxWidth,boxDepth,0.5]); // Uncomment this to check if the lid of the box is touched by anything.
  //translate([0,0,baseHeight]) cube([boxWidth,boxDepth,0.1]); 
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
     
     if ((showPartYRow!=-1) && (showPartXColumn!=-1)) {
       difference(){
	 {
	   cube([boxWidth,boxDepth,50]);
	 }
	 translate ([boxWidth/numPartsX*showPartXColumn,boxDepth/numPartsY*showPartYRow,0]) cube([boxWidth/numPartsX,boxDepth/numPartsY,100]);
       }
       //translate([0,0,boxHeight]) cube([boxWidth,boxDepth,0.5]); // Uncomment this to check if the lid of the box is touched by anything. 
     }
   }
   
   // translate ([boxWidth/numPartsX*showPartXColumn,boxDepth/numPartsY*showPartYRow,0]) cube([boxWidth/numPartsX,boxDepth/numPartsY,100]);
 }

