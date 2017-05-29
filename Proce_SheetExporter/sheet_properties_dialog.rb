require 'csv'

module Proce_SheetExporter
  
  class SheetPropertiesDialog


    def initialize()
      @web_dialog = UI::WebDialog.new({
          :dialog_title => "Sheet properties",
          :preferences_key => 'Proce_SheetExporter',
          :height => 800,
          :width => 350,
          :resizable => true,
          :scrollable => false
      })

      @web_dialog.set_file(Sketchup.find_support_file "sheet_properties_dialog.html", "Plugins/Proce_SheetExporter/html")

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

      selected_count = 0
      weight = 0
      surface = 0

      entities.each do |entity|
        sizes = Functions::entity_sizes(entity)

        selected_count += 1

        weight += sizes[0].to_mm * sizes[1].to_mm * sizes[2].to_mm / 1000000000 * 750
        surface += sizes[0].to_mm * sizes[1].to_mm / 1000000


        @web_dialog.execute_script("
            $('#material-other').find('option,optgroup').remove();
            $('#material-other').append('<option></option>');
        ")

        materials = []
        materials.push(*Sketchup.active_model.get_attribute("Proce_SheetExporter", "used_materials", []))
        materials.push("---")
        materials.push(*@materials)

        materials.each do |material|
          @web_dialog.execute_script("
             $('#material-other').append('<option>#{Functions::strip_quotes(material)}</option>');
          ")
        end


        @web_dialog.execute_script("
            $('#sub-assembly').text('#{Functions::entity_sub_assembly(entity)}');
            $('#description').text('#{Functions::entity_description(entity)}');

            $('#size-text .length-text').text('#{sizes[0]}');
            $('#size-text .width-text').text('#{sizes[1]}');
            $('#size-text .thick-text').text('#{sizes[2]}');

            $('#length').val('#{sizes[0].to_mm}');
            $('#width').val('#{sizes[1].to_mm}');
            $('#thick').val('#{sizes[2].to_mm}');

            $('#skip').val('#{Functions::strip_quotes(Functions::entity_get_attribute(entity, "skip", "false"))}');
            $('#info').val('#{Functions::strip_quotes(Functions::entity_get_attribute(entity, "info", ""))}');
            $('#rotate').val('#{Functions::strip_quotes(Functions::entity_get_attribute(entity, "rotate", "false"))}');
            $('#material').val('#{Functions::strip_quotes(Functions::entity_get_attribute(entity, "material", ""))}');
            $('#band-back').val('#{Functions::strip_quotes(Functions::entity_get_attribute(entity, "band-back", "false"))}');
            $('#band-right').val('#{Functions::strip_quotes(Functions::entity_get_attribute(entity, "band-right", "false"))}');
            $('#band-front').val('#{Functions::strip_quotes(Functions::entity_get_attribute(entity, "band-front", "false"))}');
            $('#band-left').val('#{Functions::strip_quotes(Functions::entity_get_attribute(entity, "band-left", "false"))}');

            read_hidden_fields();
        ")

      end

      @web_dialog.execute_script("
            $('#item-count').text('#{selected_count}');
            $('#weight').text('#{weight.round(0)}');
            $('#surface').text('#{surface.round(1)}');
      ")

      if selected_count == 0
        @web_dialog.execute_script("
            $('#selection').hide();
            $('#no-selection').show();
        ")
      else
        @web_dialog.execute_script("
            $('#no-selection').hide();
            $('#selection').show();
        ")
      end

      if selected_count <= 1
        @web_dialog.execute_script("$('.single-item').show();")
      else
        @web_dialog.execute_script("$('.single-item').hide();")
      end
    end


    def save_attribute(attribute)
      value = @web_dialog.get_element_value(attribute)
      # p "Saving attribute '#{attribute}' as '#{value}'"

      if (attribute == "material" && value != '' && value != 'Primary' && value != 'Secondary')
        used_materials = Sketchup.active_model.get_attribute("Proce_SheetExporter", "used_materials", [])
        used_materials.push(value)
        Sketchup.active_model.set_attribute("Proce_SheetExporter", "used_materials", used_materials.uniq.sort)
      end

      entities = Functions::find_entities(Sketchup.active_model.selection)
      entities.each do |e|
        Functions::entity_set_attribute(e, attribute, value)

=begin
        if attribute.start_with?("band-")
          faces = e.definition.entities.select { |e| e.is_a? Sketchup::Face }.sort_by { |face| face.area }
          if faces.length == 6

            face_color = nil
            if value == "true"
              face_color = "Red"
            end

            if attribute == "band-back"
              faces[2].material = face_color
            end

            if attribute == "band-right"
              faces[0].material = face_color
            end

            if attribute == "band-front"
              faces[3].material = face_color
            end

            if attribute == "band-left"
              faces[1].material = face_color
            end

          end
        end
=end
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

          sizes = Functions::entity_sizes(entity)
          thick = sizes[2]
          width = sizes[1]
          length = sizes[0]

          if Functions::entity_get_attribute(entity, 'rotate', 'false') == 'true'
            width = sizes[0]
            length = sizes[1]
          end

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
              1, # Cutlist Plus merges items
              thick,
              width,
              length,
              material_type,
              material_name,
              banding,
              Functions::entity_get_attribute(entity, "info", "")
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