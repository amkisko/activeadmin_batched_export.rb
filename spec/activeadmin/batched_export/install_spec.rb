# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::BatchedExport::Install do
  let(:order_resource) do
    ActiveAdmin.application.namespaces[:admin].resources.find do |resource|
      resource.resource_name.name == "Order"
    end
  end

  it "registers batched_export only once when call runs repeatedly" do
    2.times { described_class.call }

    batched_export_actions =
      order_resource.collection_actions.select { |action| action.name.to_sym == :batched_export }

    expect(batched_export_actions.length).to eq(1)
    expect(order_resource.controller.included_modules).to include(ActiveAdmin::BatchedExport::ControllerMethods)
  end
end
