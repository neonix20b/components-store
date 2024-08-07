# frozen_string_literal: true

module OxStore
  class ProductSearch < Spree::Core::Search::Base
    def retrieve_products
      @products_scope = get_base_scope
      curr_page = page || 1

      @products = @products_scope.includes([:master]).page(curr_page).per(per_page)
    end

    private

    def get_base_scope
      base_scope = Spree::Product.active
      base_scope = base_scope.in_taxon(taxon) if taxon.present?
      base_scope = get_products_conditions_for(base_scope, keywords)
      # base_scope = base_scope.on_hand unless Spree::Config[:show_zero_stock_products]
      add_search_scopes(base_scope)
    end

    def get_products_conditions_for(base_scope, query)
      base_scope = base_scope.like_any([:name], query.split) if query.present?
      base_scope
    end
  end
end
