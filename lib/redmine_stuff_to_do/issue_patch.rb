module RedmineStuffToDo
  module IssuePatch
    extend ActiveSupport::Concern

    included do
      after_save :update_stuff_to_do_queue
      after_destroy :remove_stuff_to_do_queue
    end

    private

    def update_stuff_to_do_queue
      if closed?
        StuffToDo.remove_associations_to(self)
      else
        StuffToDo.remove_stale_assignments(self)
      end
    end

    def remove_stuff_to_do_queue
      StuffToDo.remove_associations_to(self)
    end
  end
end
