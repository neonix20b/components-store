module Spree
  module ConfigDecorator
    def self.prepended(base)
      base.has_many :configs, as: :configurable
    end
  end
end

::Spree::Store.prepend(Spree::ConfigDecorator)
