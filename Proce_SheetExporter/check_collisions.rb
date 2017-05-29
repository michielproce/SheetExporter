module Proce_SheetExporter

  class CollisionChecker
    def self.check_collisions

      Sketchup.active_model.start_operation('Check collisions', true)


      entities = Functions::find_entities(Sketchup.active_model.selection)


      entities.each do |entity|
        entity.visible=false

      end

      collisions = 0

      entities.each do |entity1|
        entities.each do |entity2|
          if entity1 != entity2
              intersect_bounds = entity1.bounds.intersect(entity2.bounds)
              if (!intersect_bounds.empty?)
                entity1.visible=true
                entity2.visible=true
                collisions += 1
              end
          end
        end
      end

      UI.messagebox("#{collisions/2} collisions detected. Rest of component instances hidden")
      Sketchup.active_model.commit_operation
    end
  end
end