require 'csv'

module SheetExporter
  
  class SheetPropertiesDialog


    def initialize()
      @web_dialog = UI::WebDialog.new({
          :dialog_title => "Sheet properties",
          :preferences_key => 'SheetExporter',
          :height => 800,
          :width => 350,
          :resizable => true,
          :scrollable => false
      })

      @web_dialog.set_file(Sketchup.find_support_file "sheet_properties_dialog.html", "Plugins/SheetExporter/html")

      @web_dialog.add_action_callback("document_ready") { |web_dialog|
        update
      }

      @web_dialog.add_action_callback("on_error") { |web_dialog|
        puts web_dialog.get_element_value("error")
      }

      @web_dialog.add_action_callback("save_attribute") { |web_dialog, params|
        save_attribute(params)
      }


      @web_dialog.add_action_callback("export_to_clipboard") { |web_dialog|
        export_to_clipboard
        UI.messagebox("Exported to clipboard")
      }

      # TODO: remove observer when properties dialog is hidden
      Sketchup.add_observer(MyAppObserver.new self)


      @materials = Functions::import_materials
    end


    def show()
      @web_dialog.show
    end


    def update()
      unless @web_dialog.visible?
        return
      end

      entities = Functions::find_entities(Sketchup.active_model.selection)

      selected_count = entities.length

      if selected_count == 0
        @web_dialog.execute_script("
            $('#selection').hide();
            $('#no-selection').show();
        ")
        return
      end

      @web_dialog.execute_script("
          $('#material-other').find('option,optgroup').remove();
          $('#material-other').append('<option></option>');
      ")

      materials = []
      materials.push(*Sketchup.active_model.get_attribute("SheetExporter", "used_materials", []))
      materials.push("---")
      materials.push(*@materials)

      materials.each do |material|
        @web_dialog.execute_script("
           $('#material-other').append('<option>#{Functions::strip_quotes(material)}</option>');
        ")
      end

      if selected_count == 1
        entity = entities[0]
        sizes = Functions::entity_sizes(entity)

        @web_dialog.execute_script("
            $('#item-count').text('1');

            $('#sub-assembly').text('#{Functions::entity_sub_assembly(entity)}');
            $('#description').text('#{Functions::entity_description(entity)}');

            $('#weight').text('#{Functions::calc_weight(entity).round(0)}');
            $('#surface').text('#{Functions::calc_surface(entity).round(1)}');

            $('#size-text .length-text').text('#{sizes[0]}');
            $('#size-text .width-text').text('#{sizes[1]}');
            $('#size-text .thick-text').text('#{sizes[2]}');

            $('#length').val('#{sizes[0].to_mm}');
            $('#width').val('#{sizes[1].to_mm}');
            $('#thick').val('#{sizes[2].to_mm}');

            $('#info').val('#{Functions::strip_quotes(Functions::entity_get_attribute(entity, "info", ""))}');
            $('#material').val('#{Functions::strip_quotes(Functions::entity_get_attribute(entity, "material", ""))}');
            $('#skip').val('#{Functions::strip_quotes(Functions::entity_get_attribute(entity, "skip", "false"))}');
            $('#rotate').val('#{Functions::strip_quotes(Functions::entity_get_attribute(entity, "rotate", "false"))}');
            $('#double').val('#{Functions::strip_quotes(Functions::entity_get_attribute(entity, "double", "false"))}');
            $('#split').val('#{Functions::strip_quotes(Functions::entity_get_attribute(entity, "split", "1"))}');
            $('#band-back').val('#{Functions::strip_quotes(Functions::entity_get_attribute(entity, "band-back", "false"))}');
            $('#band-right').val('#{Functions::strip_quotes(Functions::entity_get_attribute(entity, "band-right", "false"))}');
            $('#band-front').val('#{Functions::strip_quotes(Functions::entity_get_attribute(entity, "band-front", "false"))}');
            $('#band-left').val('#{Functions::strip_quotes(Functions::entity_get_attribute(entity, "band-left", "false"))}');

            read_hidden_fields();

            $('.single-item').show();
        ")
      elsif selected_count > 1
        weight = 0
        surface = 0

        entities.each do |entity|
          weight += Functions::calc_weight(entity)
          surface += Functions::calc_surface(entity)
        end

        @web_dialog.execute_script("
            $('#item-count').text('#{selected_count}');
            $('#weight').text('#{weight.round(0)}');
            $('#surface').text('#{surface.round(1)}');

            $('#info').val('');
            $('#material').val('');
            $('#skip').val('false');
            $('#rotate').val('false');
            $('#double').val('false');
            $('#split').val('1');
            $('#band-back').val('false)}');
            $('#band-right').val('false');
            $('#band-front').val('false');
            $('#band-left').val('false');

            read_hidden_fields();

            $('.single-item').hide();
      ")
      end

      @web_dialog.execute_script("
            $('#no-selection').hide();
            $('#selection').show();
        ")
    end




    def save_attribute(attribute)
      value = @web_dialog.get_element_value(attribute)
      # p "Saving attribute '#{attribute}' as '#{value}'"

      if (attribute == "material" && value != '' && value != 'Primary' && value != 'Secondary')
        used_materials = Sketchup.active_model.get_attribute("SheetExporter", "used_materials", [])
        used_materials.push(value)
        Sketchup.active_model.set_attribute("SheetExporter", "used_materials", used_materials.uniq.sort)
      end

      entities = Functions::find_entities(Sketchup.active_model.selection)
      entities.each do |e|
        Functions::entity_set_attribute(e, attribute, value)
      end
    end


    def export_to_clipboard()
      entities = Functions::find_entities(Sketchup.active_model.selection)

      csv_string = CSV.generate(:col_sep => "\t") do |csv|
        csv << [
            "Sub-Assembly",
            "Description",
            "Copies",
            "Thick",
            "Width",
            "Length",
            "Material Type",
            "Material Name",
            "Banding",
            "<Info>"
        ]

        entities.each do |entity|
          next if Functions::entity_get_attribute(entity, 'skip', 'false') == 'true'

          copies = 1
          sizes = Functions::entity_sizes(entity)
          thick = sizes[2]
          width = sizes[1]
          length = sizes[0]
          info  = Functions::entity_get_attribute(entity, "info", "")


          material = Functions::entity_get_attribute(entity, "material", "")
          material_type = ''
          material_name = ''
          if(material == 'Primary')
            material_type = 'Primary'
          elsif(material == 'Secondary')
            material_type = 'Secondary'
          elsif(material != '')
            material_type = 'Sheet Good'
            material_name = material
          end

          # split first before rotate!
          split = Integer(Functions::entity_get_attribute(entity, 'split', '1'))
          if split != 1
            copies *= split
            sizes[0] = (sizes[0] / split).to_l
            length = sizes[0]
            info = "#{info} (split/#{split})"
          end

          if Functions::entity_get_attribute(entity, 'rotate', 'false') == 'true'
            width = sizes[0]
            length = sizes[1]
          end

          if Functions::entity_get_attribute(entity, 'double', 'false') == 'true'
            copies *= 2
            thick = (thick / 2).to_l
            info = "#{info} (double)"
          end

          banding_material = '1'
          if (material == 'Primary')
            banding_material = 'P'
          elsif (material == 'Secondary')
            banding_material = 'S'
          end

          banding = ''
          banding += Functions::entity_get_attribute(entity, 'band-front', 'false') == 'true' ? banding_material : '0'
          banding += '-'
          banding += Functions::entity_get_attribute(entity, 'band-back', 'false') == 'true' ? banding_material : '0'
          banding += '-'
          banding += Functions::entity_get_attribute(entity, 'band-left', 'false') == 'true' ? banding_material : '0'
          banding += '-'
          banding += Functions::entity_get_attribute(entity, 'band-right', 'false') == 'true' ? banding_material : '0'

          csv << [
              Functions::entity_sub_assembly(entity),
              Functions::entity_description(entity),
              copies, # Only used for double, Cutlist Plus merges items
              thick.to_mm.round(1),
              width.to_mm.round(1),
              length.to_mm.round(1),
              material_type,
              material_name,
              banding,
              info
          ]

        end
      end

      IO.popen('clip', 'w') { |f| f << csv_string }
    end
  end

  
  class MyAppObserver < Sketchup::AppObserver

    def initialize(dialog)
      @dialog = dialog
    end

    def onNewModel(model)
      model.selection.add_observer(MySelectionObserver.new @dialog)
    end

    def onOpenModel(model)
      model.selection.add_observer(MySelectionObserver.new @dialog)
    end

    def expectsStartupModelNotifications()
      return true
    end
  end

  class MySelectionObserver < Sketchup::SelectionObserver
    def initialize(dialog)
      @dialog = dialog
    end

    def onSelectionBulkChange(selection)
      @dialog.update
    end

    def onSelectionCleared(selection)
      @dialog.update
    end

    # Implement the following methods because the outliner incorrectly triggers these
    def onSelectionAdded(selection, element)
      @dialog.update
    end

    def onSelectionRemoved(selection, element)
      @dialog.update
    end

    def onSelectedRemoved(selection, element)
      @dialog.update
    end
  end
end