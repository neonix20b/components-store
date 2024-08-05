# frozen_string_literal: true

class Config < ApplicationRecord
  belongs_to :configurable, polymorphic: true
end
