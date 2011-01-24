/* ******************************
 * Modeler LScript: Conform By UV
 * Version: 0.5
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
cbuv_version = "0.5";
cbuv_date = "15 March 2010";

// global values go here

reqTitle = "Fix Symmetry v1.2";
// For Tolerance Fix
c1,c2,c3,c4;
totPnts = 0;
selPnts = nil;
toleranceDefault = 0.003;
side2Correct = 1;
interactiveMode = true;
changesMade = false;        // To keep track of if an undo is necessary



var pol;
var nTri;		// tris in bg

var uvInd;
var uvMapNames = nil;

// Mina
// GUI Settings
var tolerance = 0.05;
var subdivideUV = false;

var selPnts;

var iTotBGPnts;			// Integer with total number of points in BG layer
var aBGPntData;			// Array that keeps track of all point coords and UV coords

var statsNoUV = 0;
var statsUnMatched = nil;
main
{
    //
    // Make all preparations so the plugin finds enough data to be used.
    // --------------------------------------------------------------------------------
    var uvMap = VMap(VMTEXTURE, 0) || error("Please select a UV map.");		// By using 0, the modeler selected UV map is acquired.
	// Get total number of points, not caring about selections
	selmode(GLOBAL);
	var globalPntCnt = pointcount();

    selmode(USER);
	// Get the layers
    var fg = lyrfg();
    var bg = lyrbg();
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

	// Switch to BG again
    lyrsetfg(bg);
		

	if (subdivideUV == true) {
		undogroupbegin();
		unweld();
		subdivide(FLAT);
		mergepoints();
		iTotBGPnts = pointcount();
		undogroupend();
	}

	
	// Initialize the progress bar (iTotBGPnts for looping the BG array + iTotFGPnts when looping though the FG points )
    moninit((iTotBGPnts + 1) + iTotFGPnts);
	// Get all info from bg layer
    var abort = getBGData(uvMap);

	if (subdivideUV == true) {
		undo();
		undo();
	}

	
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
//	return;
    undogroupbegin();
    editbegin();
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
//			for (i=1; i <= aBGPntData.size(); i++) {
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
				p.x = aBGPntData[matchPnt,1];
				p.y = aBGPntData[matchPnt,2];
				p.z = aBGPntData[matchPnt,3];
				// And clear the point to mark it as used
				aBGPntData[matchPnt] = nil;
				
				aBGPntData.pack();
				aBGPntData.trunc();
				iTotBGPnts--;
				
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
	
	// Open the result window
	openResultWin();

    undogroupend();
}


//
// Function to store all selected Point ID's in an array
// --------------------------------------------------------------------------------
storeSelPnts
{
//    selmode(DIRECT);
    editbegin();
    foreach(p, points)
    {
        totPnts++;
        selPnts[totPnts] = p;
    }
    editend();
}

getSelPnts
{
//    selmode(DIRECT);
	selmode(USER);
	    selpolygon(CLEAR);                  // Switch to polygon mode, to speed up drawing of point selections

//    editbegin();
//    foreach(p, selPnts)
 //   {
//	info (p);
//        totPnts++;
//        selPnts[totPnts] = p;
	selpoint(SET, POINTID, selPnts);
 //   }
//    editend();
    selpoint(SET,NPEQ,1000);        // Switch back to point selection mode (Dummy selection value to keep current selection)
}



/*
 * Function to loop through the BG points and build an array of all x,y,z,uv coordinates
 *
 * @returns     Nothing 
 */
getBGData: uvMap
{
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
		i++;
    }
    editend();
    return false;
}

openMainWin
{
    reqbegin("Conform By UV v" + cbuv_version);
    reqsize(240,130);               // X,Y
    c1 = ctlnumber("Tolerance", tolerance);
    ctlposition(c1,28,20, 126);

    c2 = ctlcheckbox("Subdivide BG UV Data (experimental)", subdivideUV);
    ctlposition(c2,14,50);
	
	
    if (!reqpost())
		return false;
		
    tolerance = getvalue(c1);
    subdivideUV = getvalue(c2);

    reqend();
	return true;
}

openResultWin
{
    reqbegin("ConformByUV");
    reqsize(240,130);               // X,Y
	// Add result info here
    c2 = ctltext("","Points without UV: " + statsNoUV);
    ctlposition(c2,10,10,200,13);
    c3 = ctltext("","Unmatched Points: " + statsUnMatched.size());
    ctlposition(c3,10,30,200,13);
	
	if (statsUnMatched.size() != 0) {

	selmode(USER);

	editbegin();
		selMap = VMap(VMSELECT,"UnMatched",1);
//		selMap.dimensions = 1;
//		selMap.name = "johan";

// clear old map
//	foreach(p,points)
//	{
//	info ("loop");
//     	selMap.setValue(p,nil);
//	if(selMap.isMapped(p)) {
//		info ("is mapped");
//     	selMap.setValue(p,0);
//		}
//	}

	foreach(p,statsUnMatched)
	{
     	selMap.setValue(p,1);
	}
		editend();
	}

    return if !reqpost();
    reqend();
}