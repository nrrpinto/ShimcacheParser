# ShimcacheParser

DESCRIPTION:

  Windows Application Compatibility Database is used by windows to identify possible application compatibility challenges with executables.
  Any executable that runs on a Windows system can be found in this key.
	ShimcacheParser.ps1 parses the Registry Application Compatibility Cache on a live system, more common called Shimcache, and exports it to a CSV and/or HTML file, as also can present the info on the screen.
  
  Working for versions: Win10, Win8.1 x64, Win7 x64, Win7 x86


EXAMPLES:

 Exports to CSV format:

    ShimcacheParser.ps1 -CSV

 Exports to HTML format:

    ShimcacheParser.ps1 -HTML
    
 Exports top CSV, HTML and shows it on screen:
 
    ShimcacheParser.ps1 -HTML -CSV -SCREEN
    


NOTES:

Thanks to Eric Zimmerman: https://github.com/EricZimmerman/AppCompatCacheParser

Thanks to Joachim Metz: https://github.com/libyal/winreg-kb/blob/master/documentation/Application%20Compatibility%20Cache%20key.asciidoc
