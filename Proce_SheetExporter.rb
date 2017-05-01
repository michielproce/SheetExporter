# width = red = x
# depth = green = y
# height = blue = z

# TODO
# - Proper mult-editing
# - Visible/editable Part #
# - Connect Materials/banding
# - Visual feedback (texture)
# - Visual feedback (banding)
# - Cleanup choice between ComponentInstance / Group (only use ComponentInstance from now on)

require 'sketchup.rb'
require 'extensions.rb'
require 'Proce_SheetExporter/functions.rb'
require 'Proce_SheetExporter/sheet_properties_dialog.rb'

module Proce_SheetExporter

  sheet_properties_dialog = SheetPropertiesDialog.new

  show_sheet_properties_command = UI::Command.new("Sheet properties") {
    # show_ruby_panel()

    sheet_properties_dialog.show
  }


  show_sheet_properties_command.small_icon = "Proce_SheetExporter/icons/sheet_properties_small.png"
  show_sheet_properties_command.large_icon = "Proce_SheetExporter/icons/sheet_properties_large.png"
  show_sheet_properties_command.tooltip = "Sheet properties"
  show_sheet_properties_command.status_bar_text = "Sheet properties"
  show_sheet_properties_command.menu_text = "Sheet properties"

  toolbar = UI::Toolbar.new "Sheet exporter"
  toolbar = toolbar.add_item show_sheet_properties_command
  toolbar.show


end