class Config < ApplicationRecord
  belongs_to :configurable, polymorphic: true
end
