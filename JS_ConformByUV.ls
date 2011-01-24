/* ******************************
 * Modeler LScript: Conform By UV
 * Version: 0.1
 * Author: Johan Steen
 * Date: 14 Mar 2010
 * Modified: 14 Mar 2010
 * Description: Conforms the foreground mesh to the background by using the UV coordinates as reference.
 *
 * http://www.artstorm.net
 * ****************************** */

@version 2.4
@warnings
@script modeler
@name "JS_ConformByUV"

// global values go here
reqTitle = "Fix Symmetry v1.2";
// For Tolerance Fix
c1,c2,c3,c4;
totPnts = 0;
selPnts = nil;
toleranceDefault = 0.001;
tolerance = 0.0;
side2Correct = 1;
interactiveMode = true;
changesMade = false;        // To keep track of if an undo is necessary



var pol;
var nTri;		// tris in bg

var uvInd;
var uvMapNames = nil;

// Mina
var iTotBGPnts;
var aBGPntData;			// Array that keeps track of all point coords and UV data in the BG layer
main
{
    var uvMap = VMap(VMTEXTURE, 0) || error("Please select a UV map.");		// By using 0, the modeler selected UV map is acquired.
    selmode(USER);
	// Get the layers
    var fg = lyrfg();
    var bg = lyrbg();
	// If no BG selected, exit plugin
    if(bg == nil) return;
	// if FG is empty, exit plugin
    var mc = pointcount();
    if(mc <= 0) return;

	// Switch to BG
    lyrsetfg(bg);
	
	// Get number of points in BG layer
	iTotBGPnts = pointcount();
	// Create an array with number of points, with 4 containers for x,y,z,uv
	aBGPntData = array(iTotBGPnts,4);
	// Get all info from bg layer
    var abort = GetBGUV(uvMap);
	
	
	for (i=1; i <= iTotBGPnts; i++) {
//		info (aBGPntData[i,4]);
	}

	
	// Restore layer selections
    lyrsetfg(fg);
    lyrsetbg(bg);
	// If aborted during getBGInfo, exit
    if(abort) return;
	
	// Start moving points
    undogroupbegin();
    editbegin();
    var p;
	// loop through all points in fp
    foreach(p,points){
        var uv;
		var uvvec;
        uv = uvMap.getValue(p); if(uv == nil){ pol[i,4] = nil; continue; }
		uvvec = <uv[1],uv[2],0>;
		var uvclose;
		uvclosest = nil;
		var matched;
		matched = nil;
		for (i=1; i <= iTotBGPnts; i++) {
			var getDist = vmag(uvvec - aBGPntData[i,4]);
			if (getDist < uvclosest) {
				uvclosest = getDist;
				matched = i;
			}

// calc distance between 3 vectors
// v1 = <1,3,5.4>;
// v2 = <.054,2,90>;
// t = vmag(v1 - v2);
		
	//		info (aBGPntData[i,4]);
//			if (uvvec == aBGPntData[i,4]) {
//				p.x = aBGPntData[i,1];
//				p.y = aBGPntData[i,2];
//				p.z = aBGPntData[i,3];
//			}
		}
		
		if (matched != nil) {
				p.x = aBGPntData[matched,1];
				p.y = aBGPntData[matched,2];
				p.z = aBGPntData[matched,3];
		}
		
        // var pp = pointinfo(p);
        // var minD = 1.0e+38, duv = nil;
        // var i;
        // for(i = 1;i <= nTri;i++){
            // if(pol[i,4] != nil){
                // var near, uv;
                // (near,uv) = NearestPoint(pol[i],pp);
                // var d = vmag(pp-near);
                // if(d < minD){
                    // minD = d;
                    // duv = uv;
                // }
            // }
            // if(monstep()){
                // monend();
                // editend(ABORT);
                // return;
            // }
        // }
        // if(duv != nil){
            // var uv[2];
            // uv[1] = duv.x; uv[2] = duv.y;
            // uvMap.setValue(p,uv);
        // }
    }
    // monend();
    editend();
    undogroupend();
	

	
}

mainOLD
{
	// Get currently selected UV map
    var uvMap = VMap(VMTEXTURE, 0) || error("Please select a UV map.");		// By using 0, the modeler selected UV map is acquired.
    selmode(USER);
	// Get the layers
    var fg = lyrfg();
    var bg = lyrbg();
	// If no BG selected, exit plugin
    if(bg == nil) return;
	// if FG is empty, exit plugin
    var mc = pointcount();
    if(mc <= 0) return;

	// Switch to BG
    lyrsetfg(bg);
    triple();
	// Selct all tris
    selpolygon(SET,NVEQ,3);
    nTri = polycount(); 
	// Get number of tris
	nTri = nTri[4];			// 1=sel polys, 2=sel 1pt polus, 3=sel 2pt polys, 4=sel 3pt polys, 5=sel quads, 6=sel ngons
    if(nTri == 0){
		// If no tris, undo triple -> set back layers -> exit
        undo();
        lyrsetfg(fg);
        lyrsetbg(bg);
        return;
    }
	// fattar ej?
    pol = array(nTri,13);
	// unweld bg layer
    unweld();
	// number of points in fg * tris in bg ( *nTri är för BGinfo monstep)
    moninit((mc+1)*nTri);
//    var abort = GetBGInfo(uvMap);
    var abort = GetBGUV(uvMap);
	// undo: vet ej?
    undo();
	// undo unweld
    undo();
	// Restore layer selections
    lyrsetfg(fg);
    lyrsetbg(bg);
	// If aborted during getBGInfo, exit
    if(abort) return;
	
	// Start moving points
//    editbegin();
//    var p;
	// loop through all points in fp
//    foreach(p,points){
        // var pp = pointinfo(p);
        // var minD = 1.0e+38, duv = nil;
        // var i;
        // for(i = 1;i <= nTri;i++){
            // if(pol[i,4] != nil){
                // var near, uv;
                // (near,uv) = NearestPoint(pol[i],pp);
                // var d = vmag(pp-near);
                // if(d < minD){
                    // minD = d;
                    // duv = uv;
                // }
            // }
            // if(monstep()){
                // monend();
                // editend(ABORT);
                // return;
            // }
        // }
        // if(duv != nil){
            // var uv[2];
            // uv[1] = duv.x; uv[2] = duv.y;
            // uvMap.setValue(p,uv);
        // }
    // }
    // monend();
    // editend();
	

    //
    // Check so geometry exists in the current layer.
    // --------------------------------------------------------------------------------
    // selmode(USER);
    // if(pointcount() == 0)
        // error("There is no geometry in this layer.");


    // selmode(DIRECT);
    // pnt = pointcount();     // Get number of selected points

    // Decide which funtion to perform
    // switch (pnt)
    // {
        // case 0:
            // SymmetryCheck();
            // break;
        // case 1:
            // info ("Nothing to perform with just one selected point.");
            // break;
        // case 2:             // 2 points selected, enter Quick Mode
            // QuickFix();
            // break;
        // default:            // More than 2 points selected, enter Tolerance Mode.
            // ToleranceFix();
            // break;
    // }
}

NearestPoint: pi,pp
{
    var n = pi[4];
    var p1 = pi[1];
    var p0 = pp-n*dot3d(pp-p1,n);
    var v = p0-p1;
    var g3 = dot3d(v,pi[5]);
    if(g3<0){
        var d = min(1,max(0,dot3d(v,pi[6])));
        var id = 1-d;
        return (p1*id+pi[2]*d, pi[11]*id+pi[12]*d);
    }
    var g2 = dot3d(v,pi[7]);
    if(g2<0){
        var d = min(1,max(0,dot3d(v,pi[8])));
        var id = 1-d;
        return (p1*id+pi[3]*d, pi[11]*id+pi[13]*d);
    }
    v = p0-pi[2];
    var g1 = dot3d(v,pi[9]);
    if(g1<0){
        var d = min(1,max(0,dot3d(v,pi[10])));
        var id = 1-d;
        return (pi[2]*id+pi[3]*d, pi[12]*id+pi[13]*d);
    }
    return (p0, pi[11]*g1+pi[12]*g2+pi[13]*g3);
}


GetBGUV: uvMap
{
    editbegin();
    var i;
	i = 1;
    foreach(p, points)
    {
//		info (p.x);
		aBGPntData[i,1] = p.x;
		aBGPntData[i,2] = p.y;
		aBGPntData[i,3] = p.z;

        var uv;
        uv = uvMap.getValue(p); if(uv == nil){ pol[i,4] = nil; continue; }
		aBGPntData[i,4] = <uv[1],uv[2],0>;

		i++;
    // for(i = 1;i <= iTotBGPnts;i++){
        // var pi = polyinfo(polygons[i]);

        // pol[i,1] = pointinfo(pi[2]);
        // pol[i,2] = pointinfo(pi[3]);
        // pol[i,3] = pointinfo(pi[4]);

        // uv = uvMap.getValue(pi[2]); if(uv == nil){ pol[i,4] = nil; continue; }
        // pol[i,11] = <uv[1],uv[2],0>;
        // uv = uvMap.getValue(pi[3]); if(uv == nil){ pol[i,4] = nil; continue; }
        // pol[i,12] = <uv[1],uv[2],0>;
        // uv = uvMap.getValue(pi[4]); if(uv == nil){ pol[i,4] = nil; continue; }
        // pol[i,13] = <uv[1],uv[2],0>;

		
        // if(monstep()){
            // editend(ABORT);
            // return true;
        // }
    }
    editend();
    return false;
}
// POL: 1,2,3 = pnt coord vec, 4 = poly norm vec, 11,12,13 = UV coords för polyn
GetBGInfo: uvMap
{
    editbegin();
    var i;
    for(i = 1;i <= nTri;i++){
        var pi = polyinfo(polygons[i]);
        var n = polynormal(polygons[i]);
		// vector w poly normal
        pol[i,4] = n;
        if(n == nil) continue;
        pol[i,1] = pointinfo(pi[2]);
        pol[i,2] = pointinfo(pi[3]);
        pol[i,3] = pointinfo(pi[4]);
        var v1 = pol[i,2]-pol[i,1];
        var v2 = pol[i,3]-pol[i,1];
        var v3 = pol[i,3]-pol[i,2];
        var s = 1.0/vmag(cross3d(v1,v2));
        pol[i,5] = cross3d(n,v1)*s;
        pol[i,6] = v1/dot3d(v1,v1);
        pol[i,7] = cross3d(v2,n)*s;
        pol[i,8] = v2/dot3d(v2,v2);
        pol[i,9] = cross3d(n,v3)*s;
        pol[i,10] = v3/dot3d(v3,v3);
        var uv;
        uv = uvMap.getValue(pi[2]); if(uv == nil){ pol[i,4] = nil; continue; }
        pol[i,11] = <uv[1],uv[2],0>;
        uv = uvMap.getValue(pi[3]); if(uv == nil){ pol[i,4] = nil; continue; }
        pol[i,12] = <uv[1],uv[2],0>;
        uv = uvMap.getValue(pi[4]); if(uv == nil){ pol[i,4] = nil; continue; }
        pol[i,13] = <uv[1],uv[2],0>;
        if(monstep()){
            editend(ABORT);
            return true;
        }
    }
    editend();
    return false;
}





















/*
** Function to find Symmetry Errors (When no points are selected)
**
** @returns     Nothing 
*/
SymmetryCheck
{
    totPnts = 0;
    allPnts = nil;
    selmode(USER);
    editbegin();
    // Create an array of all existing points
    foreach(p, points)
    {
        totPnts++;
        allPnts[totPnts] = p;
    }
    editend();

    // Loop through all points and leave does without a syncing symmetry point selected
    selpoint(SET);
    selpolygon(CLEAR);                  // Switch to polygon mode, to speed up drawing of point selections
    moninit(totPnts, "processing...");
    for(i=1; i <= totPnts; i++)
    {
        curPnt = allPnts[i];
        for (j=i; j <= totPnts; j++)
        {
            if (allPnts[j].x <= 0) // Optimization
            {
                if (curPnt.x == -allPnts[j].x && curPnt.y == allPnts[j].y && curPnt.z == allPnts[j].z && i != j || curPnt.x == 0)
                { 
                    selpoint(CLEAR, POINTID, allPnts[i]);
                    selpoint(CLEAR, POINTID, allPnts[j]);
                    j = totPnts;
                }
            } // End If
        } // Next
        if (monstep()) {
            //editend(ABORT);
            return;
        } // End If
    } // Next
    monend();
    selpoint(SET,NPEQ,1000);        // Switch back to point selection mode (Dummy selection value to keep current selection)

    //
    // Show a requester and report the result of the operation
    // --------------------------------------------------------------------------------
    selmode(DIRECT);
    reqbegin(reqTitle);
    reqsize(240,130);
    if (pointcount() == 0) 
        check_str = "All points are in symmetry.";
    if (pointcount() == 1) 
        check_str = "" + pointcount() + " asymmetric point found.";
    if (pointcount() > 1)
        check_str = "" + pointcount() + " asymmetric points found.";
    c3 = ctltext("","Symmetry Check");
    ctlposition(c3,10,10,200,13);
    s1 = ctlsep();
    ctlposition(s1,-1,37);
    c2 = ctltext("",check_str);
    ctlposition(c2,10,53,200,13);
    return if !reqpost();
    reqend();
}

/*
** Function when Quick Fix is detected (Correct one point, 2 points selected)
**
** @returns     Nothing 
*/
QuickFix
{
    //
    // Setup the requester
    // --------------------------------------------------------------------------------
    side2Correct = 1;

    reqbegin(reqTitle);
    reqsize(240,130);               // X,Y
    c2 = ctltext("","Quick Fix (2 points selected)");
    ctlposition(c2,10,10,200,13);
    s1 = ctlsep();
    ctlposition(s1,-1,37);
    c1 = ctlchoice("Side to correct",side2Correct,@"      - X       ","      + X       "@);
    ctlposition(c1,10,53);
    return if !reqpost();

    side2Correct = getvalue(c1);

    reqend();

    //
    // Perform the Correction
    // --------------------------------------------------------------------------------
    selmode(DIRECT);
    editbegin();
    // Store the Positions
    if (points[1].x > points[2].x) {        // Determine which side was corrected first
        pntPos1 = points[1];
        pntPos2 = points[2];
    } else {
        pntPos1 = points[2];
        pntPos2 = points[1];
    }
    // Move the point to correct into position
    if (side2Correct == 1) {
        pointmove(pntPos2, <-pntPos1.x, pntPos1.y, pntPos1.z>);
    } else {
        pointmove(pntPos1, <-pntPos2.x, pntPos2.y, pntPos2.z>);
    }
    editend();
}

/*
** Function when Tolerance Fix is detected (Correct all selected points)
**
** @returns     Nothing 
*/
ToleranceFix
{
    storeSelPnts();

    //
    // Setup the requester
    // --------------------------------------------------------------------------------
    reqbegin(reqTitle);
    reqsize(240,168);
    c5 = ctltext("","Tolerance Fix (Multiple points selected)");
    s1 = ctlsep();
    c1 = ctlpercent("", toleranceDefault);
    c2 = ctldistance("Symmetry Tolerance", toleranceDefault);
    c3 = ctlchoice("Side to correct",side2Correct,@"    - X     ","    + X     "@);
    c4 = ctlcheckbox("Interactive", interactiveMode);
    xPos = 10;
    ctlposition(c1, xPos+179, 53, 10, 19);
    ctlposition(s1,-1,37);
    ctlposition(c2, xPos, 53, 192);
    ctlposition(c5,10,10,200,13);
    ctlposition(c3,37,80);
    ctlposition(c4,112,108);

    ctlrefresh(c1,"refresh_c2");
    ctlrefresh(c2,"refresh_c1");
    ctlrefresh(c3,"sideSwitch");
    ctlrefresh(c4,"interactiveSwitch");

    // Handle closing of the window (OK, Abort, with undo or non interactive mode)
    if (!reqpost())
    {
        if (changesMade == true) { undo(); }
        return;
    } else {
        if (interactiveMode == false) { correctPoints(); }
        reqend();
    }
}

// Refreshment function for the numeric input field
refresh_c2: value
{
    if( value != getvalue(c2) )
    {
        setvalue(c2, value);
        tolerance = getvalue(c2);
        interactive_adjust();
    }  
}

// Refreshment function for the minislider
refresh_c1: value
{
    if( value != getvalue(c1) )
    {
        setvalue(c1, value);
        tolerance = getvalue(c2);
        interactive_adjust();
    }
}

// Function to update which side to correct
sideSwitch: value
{
    side2Correct = getvalue(c3);
    interactive_adjust();
}

// Function to enable/disable interactive functionality
interactiveSwitch: value
{
    interactiveMode = getvalue(c4);
    if (interactiveMode == false && changesMade == true)
    {
        undo();
        changesMade = false;
    }
    if (interactiveMode == true)
    {
        interactive_adjust();
    }
}

// Function to call the correction function
interactive_adjust
{
    if (interactiveMode == true)
    {
        correctPoints();
    }
}



//
// Function to store all selected Point ID's in an array
// --------------------------------------------------------------------------------
storeSelPnts
{
    selmode(DIRECT);
    editbegin();
    foreach(p, points)
    {
        totPnts++;
        selPnts[totPnts] = p;
    }
    editend();
}


//
// Function to store all selected Point ID's in an array
// --------------------------------------------------------------------------------
correctPoints
{
    if (changesMade == true)
    {
        undo();
        changesMade = false;
    }
    undogroupbegin();
    //
    // Process the correction of the selected points
    // --------------------------------------------------------------------------------
    editbegin();
    moninit(totPnts, "processing...");

    for(ind=1; ind <= totPnts; ind++)       // Loop through all selected points
    {
        refpos = pointinfo(selPnts[ind]);   // Get the position of the point to check
        doCheck = false;
        if (side2Correct == 1) {    // If correcting on -X
            if (refpos.x > 0.0) { doCheck = true; }
        } else {                    // If correctiong on +X
            if (refpos.x < 0.0) { doCheck = true; }
        }
        if (doCheck == true)                 // Only try to correct, if point located on opposite correction axis
        {
            for (j = 1; j <= totPnts; j++)
            {
                pos = pointinfo(selPnts[j]);
                doCheck = false;
                if (side2Correct == 1) {    // If correcting on -X
                    if (refpos.x > 0.0) { doCheck = true; }
                } else {                    // If correcting on +X
                    if (refpos.x < 0.0) { doCheck = true; }
                }
                if (selPnts[j] != selPnts[ind] && doCheck == true)
                {
                    x = pos.x + refpos.x;
                    y = pos.y - refpos.y;
                    z = pos.z - refpos.z;
                    if (sqr(x) + sqr(y) + sqr(z) <= sqr(tolerance))
                    {
                        pointmove(selPnts[j], <-refpos.x, refpos.y, refpos.z>);
                    } // End If
                } // End If
            } // Next
        } // End If
        if (monstep()) {
            editend(ABORT);
            return;
        } // End If
    } // Next
    editend();
    monend();

    undogroupend();
    changesMade = true;
}

sqr: num
{
    return num * num;
}

