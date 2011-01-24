/* ******************************
 * Modeler LScript: Conform By UV
 * Version: 0.8
 * Author: Johan Steen
 * Date: 15 Mar 2010
 * Modified: 15 Mar 2010
 * Description: Conforms the foreground mesh to the background by using the UV coordinates as reference.
 *
 * http://www.artstorm.net
 * ****************************** */

@version 2.4
@warnings
@script modeler
@name "JS_ConformByUV"

// Main Variables
cbuv_version = "0.8";
cbuv_date = "15 March 2010";

// GUI Settings
var tolerance = 0.02;
var subdivideUV = false;
var operationMode = 1;	// 1 = normal, 2 = Cleanup UV, 3 = Morph Batch
var unweldBG = false;
var unweldFG = false;
var morphPrefix = "Morph_";

// Misc
var fg;
var bg;

// Point Variables
var uvMap;				// Holds the selected UV map
var iTotBGPnts;			// Integer with total number of points in BG layer
var iTotFGPnts;			// Integer with total number of selected points in FG layer
var globalPntCnt;		// Integer with total number of poins in FG layer
var aBGPntData;			// Array that keeps track of all point coords and UV coords
var selPnts;			// Array that keeps track of current user point selection
var morphMap;
var morphCtr = 1;

// Stats Variables
var statsNoUV = 0;
var statsUnMatched = nil;
var statsOverlapped = nil;

main
{
    //
    // Make all preparations so the plugin finds enough data to be used.
    // --------------------------------------------------------------------------------
	// Get selected UV Map
    uvMap = VMap(VMTEXTURE, 0) || error("Please select a UV map.");		// By using 0, the modeler selected UV map is acquired.
	// Get total number of points, not caring about selections
	selmode(GLOBAL);
	globalPntCnt = pointcount();
	//
    selmode(USER);
	// Get the layers
	fg = lyrfg();
    bg = lyrbg();
	// If no BG selected, exit plugin
    if(bg == nil) error("Please select a BG layer.");
	// if FG is empty, exit plugin
    var iTotFGPnts = pointcount();
    if(iTotFGPnts <= 0) error("Please use a FG layer with geometry.");
	
	// If selected points differs from total points, store the selection
	if (globalPntCnt != iTotFGPnts) {
		storeSelPnts();
	}

	// Switch to BG
    lyrsetfg(bg);
	// Get number of points in BG layer
	iTotBGPnts = pointcount();
	// If BG is empty, exit plugin
    if(iTotBGPnts == 0){
        lyrsetfg(fg);
        lyrsetbg(bg);
        error("Please use a BG layer with geometry.");
    }	
	
    //
    // Open the main window and collect / process user input.
    // --------------------------------------------------------------------------------
	// Restore layer selections
    lyrsetfg(fg);
    lyrsetbg(bg);
	var mainWin = openMainWin();
	if (mainWin == false)
		return;

    undogroupbegin();

	// Unweld the FG
	if (unweldFG == true && operationMode == 2) 
		unweld();
		
	// Switch to BG again
    lyrsetfg(bg);

	// If in morph mode, loop through all selected bg layers and perform the operation
	if (operationMode == 3) {
		var aBG = bg;
		for (i = 1; i <= aBG.size(); i++) {
			bg = aBG[i];
			lyrsetfg(bg);
			findMatches();
		}
	} else {
		// Unweld the background
		if (unweldBG == true) {
			unweld();
			iTotBGPnts = pointcount();
		}
		// Unweld and subdivide the background
		if (subdivideUV == true) {
			unweld();
			subdivide(FLAT);
			iTotBGPnts = pointcount();
		}
		findMatches();
	}
	
	// Merge the FG
	if (unweldFG == true && operationMode == 2) 
		mergepoints(0);
	// Open the result window
	if (operationMode != 3) {
		openResultWin();
	}
    undogroupend();
}

// Finds the matching UV coordinates and performed the desired operation
findMatches {
	// Initialize the progress bar (iTotBGPnts for looping the BG array + iTotFGPnts when looping though the FG points )
    moninit((iTotBGPnts + 1) + iTotFGPnts);
	// Get all info from bg layer
    var abort = getBGData(uvMap);

	// Update number of BG Points (if some lacked UV coords)
	// using iTotBGPnts on each loop later, is faster than using .size() on each iteration
	iTotBGPnts = aBGPntData.size();
	// Restore layer selections
    lyrsetfg(fg);
    lyrsetbg(bg);
	// If aborted during getBGInfo, exit
    if(abort) return;

    //
    // Start moving the points in the foreground
    // --------------------------------------------------------------------------------
	// If selected points differs from total points, get the selection
	if (globalPntCnt != iTotFGPnts) {
		getSelPnts();
	}
    editbegin();
	
	// Setup vertex maps for the morph mode
	if (operationMode == 3) {
		if (morphCtr > 1)
			oldie = morphMap.name;
		morphMap = VMap(VMMORPH,morphPrefix + morphCtr.asStr(), 3);
		current = morphMap.name;
		morphCtr++;
	}

	// loop through all points in foreground
    var p;
    foreach(p,points){
		// Get the UV for current point
        var uv = uvMap.getValue(p);
		if(uv == nil) {
			// If the point lacks UV coords
			statsNoUV++;
		} else {
			// Convert the UV coords to a vector
			var uvVec = <uv[1],uv[2],0>;
			var bestMatch = nil;					// Keep track of current best match
			var matchPnt = nil;					
			// Loop through all BG UV coords
			for (i=1; i <= iTotBGPnts; i++) {
				// Skip if BG pnt already has been used
				if (aBGPntData[i] != nil) {
					// Get the distance between the FG and BG UV coord vectors
					var getDist = vmag(uvVec - aBGPntData[i,4]);
					// If perfect match is found
					if (getDist == 0) {
						// match immediately and break the for loop
						matchPnt = i;
						break;
					}
					// Check if distance is smaller than current best match, and that distance is within the tolerance
					if (getDist < bestMatch && getDist < tolerance) {
						bestMatch = getDist;
						matchPnt = i;
					}
				}
			}
			
			// If a match was found, move the point into position
			if (matchPnt != nil) {
				if (operationMode == 1) 
					positionPnt(p, matchPnt);
				if (operationMode == 2) 
					positionUV(p, matchPnt);
				if (operationMode == 3) 
					positionMorph(p, matchPnt);
			} else {
				// if no match was found, add the unmatched point to the stats array
				statsUnMatched += p;
			}
		}
		// Increase the progressbar
		if(monstep()){
			monend();
			editend(ABORT);
			return;
		}
    }
    monend();
    editend();
}


// Moves points, for normal mode
positionPnt: p, matchPnt {
	if (aBGPntData[matchPnt,5] == true) {
				statsOverlapped += p;
	}
	p.x = aBGPntData[matchPnt,1];
	p.y = aBGPntData[matchPnt,2];
	p.z = aBGPntData[matchPnt,3];
	aBGPntData[matchPnt,5] = true;
}

// Moves UV coordinates for Cleanup mode
positionUV: p, matchPnt {
	var thisUV = aBGPntData[matchPnt,4];
	uv[1] = thisUV.x; uv[2] = thisUV.y;
	uvMap.setValue(p,uv);
}

positionMorph: p, matchPnt {
	if (morphCtr > 2) {
		var oldMap = VMap(VMMORPH, morphPrefix + (morphCtr - 2).asStr());
		if(oldMap.isMapped(p)) {
			valold = oldMap.getValue(p);
			morphMap = VMap(VMMORPH,morphPrefix + (morphCtr - 1).asStr(), 3);
			val[1] = aBGPntData[matchPnt,1] + valold[1] - p.x;
			val[2] = aBGPntData[matchPnt,2] + valold[2] - p.y;
			val[3] = aBGPntData[matchPnt,3] + valold[3] - p.z;
		} else {
			if (morphCtr == 3) {
				val[1] = aBGPntData[matchPnt,1] - p.x;
				val[2] = aBGPntData[matchPnt,2] - p.y;
				val[3] = aBGPntData[matchPnt,3] - p.z;
			}
		}
	} else {
		val[1] = aBGPntData[matchPnt,1] - p.x;
		val[2] = aBGPntData[matchPnt,2] - p.y;
		val[3] = aBGPntData[matchPnt,3] - p.z;
	}
	morphMap.setValue(p,val);
}

/*
 * Function to loop through the BG points and build an array of all x,y,z,uv coordinates
 *
 * @returns     Nothing 
 */
getBGData: uvMap
{
	aBGPntData = nil;
    editbegin();
    var i = 1;
    foreach(p, points)
    {
		// Increase the progress bar
        if(monstep()){
            editend(ABORT);
            return true;
        }
		// Get the UV values
        var uv = uvMap.getValue(p);
		// Check so the point contains UV data
		if(uv == nil){ 
			// skip rest of the loop and continue with the next point
			continue;
		}
		// If UV data was present
		aBGPntData[i,1] = p.x;
		aBGPntData[i,2] = p.y;
		aBGPntData[i,3] = p.z;
		aBGPntData[i,4] = <uv[1],uv[2],0>;
		aBGPntData[i,5] = false;
		i++;
    }
    editend();
    return false;
}


/*
 * Functions to handle point selections
 *
 * @returns     Nothing 
 */

// Stores all selected Point ID's in an array
storeSelPnts
{
    editbegin();
    foreach(p, points) {
        selPnts += p;
    }
    editend();
}

// Selects all points stored in the selection array
getSelPnts
{
	selmode(USER);
    selpolygon(CLEAR);                  // Switch to polygon mode, to speed up drawing of point selections
	selpoint(SET, POINTID, selPnts);
    selpoint(SET,NPEQ,1000);        	// Switch back to point selection mode (Dummy selection value to keep current selection)
}

/*
 * Functions to handle the windows
 *
 * @returns     Nothing 
 */
 
// Main Window, Returns false for cancel
openMainWin
{
    reqbegin("Conform By UV v" + cbuv_version);
    reqsize(340,246);               // Width, Height

    ctlTol = ctlnumber("Tolerance", tolerance);
    ctlMode = ctlpopup("Mode", 1, @ "Normal","Cleanup UV","Morph Batch" @);
    ctlUnweldBG = ctlcheckbox("Unweld BG Data", unweldBG);
    ctlSubD = ctlcheckbox("Subdivide BG Data", subdivideUV);
    ctlUnweldFG = ctlcheckbox("Unweld & Merge FG", unweldFG);
	ctlMorphPfx = ctlstring("Morph Prefix: ", morphPrefix, 156);
    ctlAbout = ctlbutton("About the Plugin", 73, "openAboutWin");
	
	ctlSep1 = ctlsep();
	ctlSep2 = ctlsep();
	ctlSep3 = ctlsep();

    ctlposition(ctlMode,93,10);
    ctlposition(ctlTol, 72, 32, 204);
	ctlposition(ctlSep1, 0, 60);
    ctlposition(ctlUnweldBG, 126, 68, 150);
    ctlposition(ctlSubD, 126, 90, 150);
    ctlposition(ctlUnweldFG, 126, 112, 150);
	ctlposition(ctlSep2, 0, 140);
    ctlposition(ctlMorphPfx, 55, 148);
	ctlposition(ctlSep3, 0, 176);
	ctlposition(ctlAbout, 126, 184, 150);
	
    if (!reqpost())
		return false;
		
    tolerance = getvalue(ctlTol);
	operationMode = getvalue(ctlMode);
	unweldBG = getvalue(ctlUnweldBG);
    subdivideUV = getvalue(ctlSubD);
	unweldFG = getvalue(ctlUnweldFG);
	morphPrefix = getvalue(ctlMorphPfx);

    reqend();
	return true;
}

// Result Window
openResultWin
{
    reqbegin("Conform By UV");
    reqsize(240,170);               // X,Y
	// Add result info here
    c2 = ctltext("","Points without UVs: " + statsNoUV);
    ctlposition(c2,10,10,200,13);
    c3 = ctltext("","Unmatched Points: " + statsUnMatched.size());
    ctlposition(c3,10,30,200,13);
    c5 = ctltext("","Overlapping Points: " + statsOverlapped.size());
    ctlposition(c5,10,50,200,13);

    c10 = ctlcheckbox("Create selection set of unmatched points", false);
    ctlposition(c10,10,76);
    c11 = ctlcheckbox("Create selection set of overlapping points", false);
    ctlposition(c11,10,100);
	
    return if !reqpost();

	// Create selection set of unmatched points
	if (getvalue(c10) == true && statsUnMatched.size() != 0) {
		selmode(USER);
		editbegin();
		selMap = VMap(VMSELECT,"UnMatched",1);
		foreach(p,statsUnMatched)
		{
			selMap.setValue(p,1);
		}
		editend();
	}

	// Create selection set of overlapping points
	if (getvalue(c11) == true && statsOverlapped.size() != 0) {
		selmode(USER);
		editbegin();
		selMap = VMap(VMSELECT,"Overlap",1);
		foreach(p,statsOverlapped)
		{
			selMap.setValue(p,1);
		}
		editend();
	}
    reqend();
}

// About Window
openAboutWin
{
	reqbegin("About Conform By UV");
	reqsize(300,190);

	// ctlLogo = ctlimage("E:/Coding/LightWave/Classic/RenderPresets/trunk/AboutLogo.tga");
	// ctlposition(ctlLogo, 0,0);
	
	ctlText1 = ctltext("","Conform By UV");
	ctlText2 = ctltext("","Version: " + cbuv_version);
	ctlText3 = ctltext("","Build Date: " + cbuv_date);
	ctlText4 = ctltext("","Programming by Johan Steen, http://www.artstorm.net/");
	ctlText5 = ctltext("","Ideas and Testing by Lee Perry-Smith, http://www.ir-ltd.net/");
	ctlposition(ctlText1, 10, 60);
	ctlposition(ctlText2, 10, 75);
	ctlposition(ctlText3, 10, 90);
	ctlposition(ctlText4, 10, 115);
	ctlposition(ctlText5, 10, 130);
	
	return if !reqpost();
	reqend();
}