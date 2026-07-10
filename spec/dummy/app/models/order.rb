# frozen_string_literal: true

class Order < ApplicationRecord
  validates :email, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at email id updated_at]
  end
end
