class Spree::Admin::EmailsController < Spree::Admin::ResourceController
  def model_class
    @model_class ||= Email
  end
end
