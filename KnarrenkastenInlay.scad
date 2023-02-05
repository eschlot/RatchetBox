include <BOSL2/std.scad>
include <BOSL2/fnliterals.scad>

$fn=40;
aufbauHoehe = 27;
boxHeight = 34;
boxWidth=237;
boxDepth=112;
//-----------------------------------------------------------------------------------------


// Idee: cumsum aus der Doku
function bohrungen(arr) = [for (x=arr[0][0]/2+1, // start value for x 
				  i=0; // iterator var      
				i<len(arr);  // termination
                                // current x+ half of current diameter + half of next diameter (if existing)
                                x= x + arr[i][0]/2 + arr[i+1<len(arr)-1?i+1:i][0]/2, 
				  i=i+1) // next iteration
    // [x, 1+ half diameter, diameter, text]
    [x,1+arr[i][0]/2,arr[i][0],str(arr[i][1])]];



module bohrung(parameters)
{
  x=parameters[0];
  y=parameters[1];
  d=parameters[2];
  name=parameters[3];

  hexNutHeight=25.5;

  lenOfHexNutAboveAufbauhoehe=(boxHeight-aufbauHoehe)-1;
  boreDepth=hexNutHeight-lenOfHexNutAboveAufbauhoehe;

  echo("boreDepth",boreDepth);
  textSize=5;
  
  translate([x,y,aufbauHoehe])
    cyl(h=boreDepth, d=d, rounding2=-2, anchor=TOP);

  translate([x,y,aufbauHoehe])
    translate([0,-textSize/2,-boreDepth-1])
    color("blue")
    linear_extrude(height=2)
    text(name,size=textSize,halign="center");
}

//---------------------------------------------------------------------------------------

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
    platzOben=(boxHeight-aufbauHoehe);
    mittelpunktUnterDeckel=(maxDia/2)+1;

    translate([0,0,pos]) {
      cyl(l=length,d1=startDia,d2=endDia,anchor=BOTTOM);

      if (mittelpunktUnterDeckel>platzOben)
	translate([-mittelpunktUnterDeckel/2,0,0])
	  {
	    prismoid(size1=[mittelpunktUnterDeckel,startDia],
		     size2=[mittelpunktUnterDeckel,endDia],
		     h=length);
	  }
    }
}

//-------------------------------------------------------------------------------------

module liegendeNuesse(x,y,rot,nutDefinitions)
{
  echo("liegendeNuesse Start");
  l=[ for (nutDef = nutDefinitions[0],
	     i=0,
	     x_cur=x,
	     maxDia=max([for (p = nutDefinitions[0][1]) last(p)]),
	     echo("Init: Name:",nutDef[0]," maxDia:",str(maxDia)," x_cur:",str(x_cur));
	   
	   i<len(nutDefinitions);

	   echo("Pre:",str(i)," x_cur:",str(x_cur)," maxDia:",str(maxDia)),
	     i=i+1,
	     x_cur=x_cur+1.5+max([for (p = nutDefinitions[i][1]) last(p)])/2+maxDia/2,
	     maxDia=max([for (p = nutDefinitions[i][1]) last(p)]),
	     echo("Post:",str(i)," x_cur:",str(x_cur)," maxDia:",str(maxDia))
	   )
      [nutDefinitions[i][0],nutDefinitions[i][1],x_cur,maxDia]];
  for (nutDef=l)
    {
      name=nutDef[0];
      nutTubes=nutDef[1];
      x_cur=nutDef[2];
      maxDia=nutDef[3];
      liegendeNuss(x_cur,y,rot,name,nutTubes,maxDia);
    };
}  

// [x,y,[rotation_x,rotation_y,rotation_z]]
module liegendeNuss(x,y,rot,name,continousTubes,maxDia)
{
  echo("liegendeNuss:",name);
  translate([x,y,boxHeight-maxDia/2-.5])
    rotate(rot){
    griffTubes=calcContinousTubes(continousTubes);
    echo(griffTubes);
    continousTubes(griffTubes,maxDia);

    translate([(maxDia/2)+1,0,1])
      rotate([0,270,0])
      linear_extrude(height=(maxDia/2)+1)
      color("blue")
      text(name, size = maxDia/2.5,halign="left",valign="center"); 
  }
}

//--------------------------------------------------------------------------------------
// []
module knarre(x,y,rotation,
	      durchmesserKopf,tiefeKopf,
	      durchmesserKopf2,tiefeKopf2,
	      durchmesserPie,tiefePie,winkelPie,
	      griffDaten)
{
  belowAufbauHoehe=7;
  echo("aufbauHoehe-belowAufbauHoehe",aufbauHoehe-belowAufbauHoehe);
  translate([x,y,aufbauHoehe-belowAufbauHoehe])
    rotate(rotation)
    {
      additionalHeight=boxHeight-aufbauHoehe+belowAufbauHoehe;
      echo("additionalHeight",additionalHeight);

      echo("tiefeKopf+additionalHeight",tiefeKopf+additionalHeight);
      echo("tiefeKopf2+additionalHeight",tiefeKopf2+additionalHeight);
      
      translate([0,0,additionalHeight])
	cyl(h=tiefeKopf+additionalHeight,d=durchmesserKopf,rounding1=1,anchor=TOP);
      translate([0,0,additionalHeight])
	cyl(h=tiefeKopf2+additionalHeight,d=durchmesserKopf2,rounding1=2,anchor=TOP);
      translate([0,0,-tiefePie])
	{
	  pie_slice(h=tiefePie+additionalHeight,r=durchmesserPie/2,
		    ang=winkelPie,spin=[0,0,-winkelPie/2]);
	}
            
      rotate([0,90,0])
	{
	  griffTubes=calcContinousTubes(griffDaten);
	  echo("griffTubes:",griffTubes);
	  // output:[[startDia,endDia,len,pos],...]

	  maxDia=max(concat([for (p = griffTubes) p[0]],[for (p = griffTubes) p[1]]));

	  echo("maxDia:",maxDia);
	  continousTubes(griffTubes,maxDia);
	}
    }
}

//----------------------------------------------------------------------------------------

griffDaten=[
	    [12,21],
	    [19,21],
	    [20,20],
	    [27,16],
	    [29,16],
	    [35,11],
	    [55,11],
	    [56,21],
	    [60,21],
	    [68,14],
	    [81,20],
	    [92,21],
	    [105,26],
	    [118,21],
	    [129,18],
	    [134,17],
	    [139,0]
	    ];

// real diameter, comment
bohrungenInit=[
	       [12.5,4],
	       //[12.5,4.5],
	       [12.5,5],
	       [12.5,5.5],
	       //[12.5,6.5],
	       //[12.5,6],
	       [12.5,7],
	       [12.5,8],
	       //[13.7,9],
	       [15,10],
	       [16.5,11],
	       [17.5,12],
	       [18,13],
	       ];
bohrungenRaw =bohrungen(bohrungenInit);

// Output format: x,y,diameter,comment
//bohrungenRaw =[
//[30,10,6,"6mm"],
//[30,20,7,"7mm"],
//[30,30,8,"8mm"]
//];

eNuesse=[["E10",[[0,14],[32,14],[32.1,13],[50,13]]],
	 ["E8",[[0,12],[32,12],[32.1,10],[50,10]]],
	 //["E7",[[0,12],[32,12],[32.1,9],[50,9]]],
	 ["E6",[[0,12],[32,12],[32.1,8],[50,8]]],
	 ["E5",[[0,12],[32,12],[32.1,7.2],[50,7.2]]],
	 ["E4",[[0,12],[32,12],[32.1,6.1],[50,6.1]]]
	 ];

mNuesse=[
	 ["4",[[0,12],[32,12],[32.1,6.8],[50.5,6.8]]],
	 ["5",[[0,12],[32,12],[32.1,8],[50.5,8]]],
	 ["5,5",[[0,12],[32,12],[32.1,8.6],[50.5,8.6]]],
	 ["6",[[0,12],[32,12],[32.1,9.4],[50.5,9.4]]],
	 ["7",[[0,12],[32,12],[32.1,10.9],[50.5,10.9]]],
	 ["8",[[0,11.2],[8,11.2],[8.1,12],[50.5,12]]],
	 ["9",[[0,12],[8,12],[8.1,13.2],[50.5,13.2]]],
	 ["10",[[0,12.6],[8,12.6],[8.1,13.9],[50.5,13.9]]],
	 ["11",[[0,14.1],[8,14.1],[8.1,15.9],[50.5,15.9]]],
	 ["12",[[0,15],[8,15],[8.1,16.9],[50.5,16.9]]],
	 ["13",[[0,16.1],[8,16.1],[8.1,18],[50.5,18]]],
	 ];

tNuesse=[
		["T20",[[0,12],[18.5,12],[18.6,7.2],[25,4.3],[32.3,4.3]]],
		["T25",[[0,12],[18.5,12],[18.6,7.2],[25,4.7],[32.3,4.7]]],
		["T27",[[0,12],[18.5,12],[18.6,7.2],[25,5.1],[32.3,5.1]]],
		["T30",[[0,12],[18.5,12],[18.6,7.2],[25,5.7],[32.3,5.7]]],
		];

normNuesse=[
		 ["PH1",[[0,12],[18.5,12],[18.6,7.2],[23.5,4.5],[32.8,4.5]]],
		 ["PH2",[[0,12],[18.5,12],[18.6,7.2],[22.6,6],[32.5,6]]],
		 ["FD4",[[0,12],[18.5,12],[18.6,7.2],[23.7,4],[32.88,4]]],
		 ["FD5,5",[[0,12],[18.5,12],[18.6,7.2],[23.4,5.5],[32.72,5.5]]],
		 ];

hexNuesse=[
		 ["Gelenk",[[0,14.1],[28,14.1],[28.1,8.6],[35,8.6]]],
		 ["HX3",[[0,12],[18.5,12],[18.6,7.2],[28.8,3.3],[32.72,3.3]]],
		 ["HX4",[[0,12],[18.5,12],[18.6,7.2],[25,4.6],[32.3,4.6]]],
		 ["HX5",[[0,12],[18.5,12],[18.6,7.2],[25,5.66],[32.3,5.66]]],
		 ["HX6",[[0,12],[18.5,12],[18.6,7.2],[25,6.85],[32.3,6.85]]],
		 ];


verlaengerung150=[
		 ["150",[[0,13],[18,13],[18.1,9],[151,9]]]
		 ];

verlaengerung100=[
		  ["100",[[0,13],[18,13],[18.1,9],[101,9]]]
		  ];

verlaengerung50=[
		  ["50",[[0,13],[18,13],[18.1,9],[51,9]]]
		  ];


module innerBodies ()
{
  for (b =bohrungenRaw) {
    bohrung(b);
  }


  liegendeNuesse(7.5,110.5,[90,90,0],mNuesse);
  liegendeNuesse(182,110.5,[90,90,0],tNuesse);
  liegendeNuesse(175,52,[270,90,0],normNuesse);  
  liegendeNuesse(162,14,[270,90,0],hexNuesse);
  
  // x,y,rot,len_long,radius_long,len_short,radius_short
  liegendeNuesse(2,51,[0,90,1],verlaengerung150);
  liegendeNuesse(132.5,8.5,[0,90,0],verlaengerung100);
  liegendeNuesse(229,66,[0,90,270],verlaengerung50);    

  knarre(165-45/2-1.75,32.5,[0,0,180],
	 9,17,
	 25,8,
	 32,6,220,
	 griffDaten);


}


left = false;

if (false) {
  //translate([0,0,boxHeight]) cube([237,112,0.5]);
  innerBodies();
 }
 else {

   difference() {
     {
       difference(){
	 { // Basiskoerper
	   diff() cube([boxWidth,boxDepth,aufbauHoehe]) edge_profile() mask2d_roundover(r=1);
	 }
	 innerBodies();
       }
     }
     
     translate([left?boxWidth/2:0,-1,-1])
       cube([boxWidth/2,boxDepth+2,aufbauHoehe+2]);
       //   translate([0,0,boxHeight]) cube([237,112,0.5]);
       }
 }



