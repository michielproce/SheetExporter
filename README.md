# Sheet Exporter from Sketchup to Cutlist Plus fx
Easily export sheets from Sketchup to Cutlist Plus fx.
Windows only. Tested with Sketchup 2016/2017

## Getting Started
Download .zip archive and extract to `%APPDATA%\SketchUp\SketchUp 2017\SketchUp\Plugins` (replace 2017 with your version).
Click the following toolbar button to open the sheet exporter dialog:
![Materials export dialog](SheetExporter/icons/sheet_properties_small.png?raw=true)

## Instructions
Created your furniture in Sketchup, with each part as a separate component. Select the parts you want to export to Cutlist and click 'copy to clipboard'.
In Cutlist, open Edit -> Import Parts from Clipboard. Make sure "First row has headers" is ticked, and press "Auto-map columns". Click "Finish" and your parts should appear in the parts tab

| Property   | Description                                                                                             |
|------------|---------------------------------------------------------------------------------------------------------|
| Info       | Add information to the "Info" column of Cutlist                                                         |
| Material   | Primary/Secondary materials can be defined in Cutlist                                                   |
| Skip       | This item will never be exported to Cutlist                                                             |
| Rotate 90° | Rotate this parts 90°, changing the grain direction                                                     |
| Double     | When a part is 36mm thick in Sketchup, this option will add 2x 18mm thick in Cutlist                    |
| Split      | When a part is 1000mm long in Sketchup, this option will add 2x 500mm to Cutlist when Split is set to 2 |

## Importing materials
In Cutlist Plus fx, use Materials -> Export database with the following settings:
![Materials export dialog](SheetExporter/materials/materials.jpg?raw=true)
Export the file as `materials.csv` and place it in `%APPDATA%\SketchUp\SketchUp 2017\SketchUp\Plugins\SheetExporter\materials` (replace 2017 with your version)

(If the exported file consists of only one line, enable "Use Unicode file format when exporting" in Settings -> General preferences -> File Locations (tab))


## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details