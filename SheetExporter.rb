require 'sketchup.rb'
require 'extensions.rb'
require 'SheetExporter/functions.rb'
require 'SheetExporter/sheet_properties_dialog.rb'

module SheetExporter

  sheet_properties_dialog = SheetPropertiesDialog.new

  # show_ruby_panel()
  # sheet_properties_dialog.show

  show_sheet_properties_command = UI::Command.new("Sheet properties") {
    sheet_properties_dialog.show
  }

  show_sheet_properties_command.small_icon = "SheetExporter/icons/sheet_properties_small.png"
  show_sheet_properties_command.large_icon = "SheetExporter/icons/sheet_properties_large.png"
  show_sheet_properties_command.tooltip = "Sheet properties"
  show_sheet_properties_command.status_bar_text = "Sheet properties"
  show_sheet_properties_command.menu_text = "Sheet properties"

  toolbar = UI::Toolbar.new "Sheet exporter"
  toolbar = toolbar.add_item show_sheet_properties_command
  toolbar.show


end