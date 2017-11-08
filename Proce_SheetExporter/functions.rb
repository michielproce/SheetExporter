require 'ostruct'

module Proce_SheetExporter
  class Functions

    def self.strip_quotes(input)
      return input.tr(?', '').tr(?", '')
    end


    def self.entity_sizes(entity)
      bounds = entity.definition.bounds

      tr = entity.transformation.to_a
      xscale = Math::sqrt(tr[0]*tr[0]+tr[1]*tr[1]+tr[2]*tr[2])
      yscale = Math::sqrt(tr[8]*tr[8]+tr[9]*tr[9]+tr[10]*tr[10])
      zscale = Math::sqrt(tr[4]*tr[4]+tr[5]*tr[5]+tr[6]*tr[6])

      width = (bounds.width * xscale).to_l
      depth = (bounds.depth * yscale).to_l
      height = (bounds.height * zscale).to_l

      [width, depth, height].sort.reverse
    end

    def self.entity_sub_assembly(entity)
      entity_description(find_parent(entity))
    end

    def self.entity_description(entity)
      description = ""

      if entity.is_a? Sketchup::ComponentInstance
        description = entity.definition.name
      end

      description
    end

    def self.entity_get_attribute(entity, name, default = nil)
      entity.definition.get_attribute("Proce_SheetExporter", name, default)
    end

    def self.entity_set_attribute(entity, name, value)
      entity.definition.set_attribute("Proce_SheetExporter", name, value)
    end

    def self.find_entities(selection)
      entities = []

      to_visit_entities = []
      selection.select { |e| e.is_a? Sketchup::Group or e.is_a? Sketchup::ComponentInstance }.each do |e|
        to_visit_entities.push(e)
      end


      to_visit_entities.each do |e|
        children = find_children(e).select { |e| e.is_a? Sketchup::Group or e.is_a? Sketchup::ComponentInstance }

        if children.length == 0 and e.is_a? Sketchup::ComponentInstance
          entities.push(e)
        end

        to_visit_entities.push(*children)
      end

      entities
    end


    def self.find_parent(child_entity)
      model = Sketchup.active_model
      entities = model.entities.select { |e| e.is_a? Sketchup::Group or e.is_a? Sketchup::ComponentInstance }

      to_visit_entities = []

      entities.each do |e|
        node = OpenStruct.new
        node.entity = e
        node.parent = nil
        to_visit_entities.push(node)
      end

      to_visit_entities.each do |node|

        children = find_children(node.entity)

        children.each do |e|
          new_node = OpenStruct.new
          new_node.entity = e
          new_node.parent = node.entity
          to_visit_entities.push(new_node)
        end

        if node.entity == child_entity
          return node.parent
        end
      end

      nil
    end

    def self.find_children(entity)
      children = []
      if entity.is_a? Sketchup::Group
        children = entity.entities
      end

      if entity.is_a? Sketchup::ComponentInstance
        children = entity.definition.entities
      end

      children
    end

    def self.calc_weight(entity)
      sizes = Functions::entity_sizes(entity)
      sizes[0].to_mm * sizes[1].to_mm * sizes[2].to_mm / 1000000000 * 750
    end

    def self.calc_surface(entity)
      sizes = Functions::entity_sizes(entity)
      sizes[0].to_mm * sizes[1].to_mm / 1000000
    end


    def self.import_materials
      materials = []

      CSV.foreach(Sketchup.find_support_file "materials.csv", "Plugins/Proce_SheetExporter/materials") do |row|
        next unless row[0] == "Sheet Good"
        materials.push row[1]
      end

      materials.uniq.sort
    end
  end
end
