--------------------------------------------------------------------------------
 Conform By UV - README

 Conforms the foreground mesh to the background by using the UV coordinates
 as reference, which makes point order irrelevant as long as the UV map's 
 layout matches.

 Website:      http://www.artstorm.net/plugins/conform-by-uv/
 Project:      http://code.google.com/p/js-lightwave-lscripts/
 Feeds:        http://code.google.com/p/js-lightwave-lscripts/feeds
 
 Contents:
 
 * Installation
 * Usage
 * Source Code
 * Changelog
 * Credits

--------------------------------------------------------------------------------
 Installation
 
 General installation steps:

 * Copy JS_ConformByUV.ls and JS_ConformByUV.tga to LightWave’s plug-in folder.
 * If "Autoscan Plugins"  is enabled, just restart LightWave and it's installed.
 * Else, locate the “Add Plugins” button in LightWave and add them manually.
 * Tip: To keep things tidy, I personally organize my plugins and scripts in
   folders, so in this case, I'd put the files into
   [LW Install]/Plugins/3rdParty/artstorm/.

 I’d recommend to add the plugin to a convenient spot in LightWave’s menu,
 so all you have to do is press the Conform by UV button when you need to
 use it.
 
--------------------------------------------------------------------------------
 Usage

 See http://www.artstorm.net/plugins/conform-by-uv/ for usage instructions.

--------------------------------------------------------------------------------
 Source Code
 
 Download the source code:
 
   http://code.google.com/p/js-lightwave-lscripts/source/checkout

 You can check out the latest trunk or any previous tagged version via svn
 or explore the repository directly in your browser.
 
 Note that the default checkout path includes all my available LScripts, you
 might want to browse the repository first to get the path to the specific
 script's trunk or tag to download if you don't want to get them all.
 
--------------------------------------------------------------------------------
 Changelog

 * v1.2 - 27 Oct 2010
   * Added automatic loading and saving of settings between sessions.
   * Loads the logo from disk instead of having to compile the script to
     embed it.
   * Released the script as open source.

 * v1.1 - 26 Mar 2010:
   * Added a Create Morph option for the normal mode.
   * Implemented some logic to the gadgets in the GUI.
   * Fixed a bug in Morph Batch mode where variation in point count could
     confuse the tool.

 * v1.0 - 16 Mar 2010:
   * Release of version 1.0, first public release.

--------------------------------------------------------------------------------
 Credits

 Johan Steen, http://www.artstorm.net/
 * Original author
 
 Lee Perry-Smith. http://www.ir-ltd.net/
 * Ideas
 * Logo
 * Testing


