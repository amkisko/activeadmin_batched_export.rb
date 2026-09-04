# frozen_string_literal: true

class OwnedNote < ApplicationRecord
  def self.ransackable_attributes(_auth_object = nil)
    %w[body created_at id owner_key updated_at]
  end
end
