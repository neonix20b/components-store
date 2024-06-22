module OxStore
  class ProductSearch < Spree::Core::Search::Base

    protected
    def get_base_scope
        base_scope = Spree::Product.active
        base_scope = base_scope.in_taxon(taxon) unless taxon.blank?
        base_scope = get_products_conditions_for(base_scope, keywords)
        #base_scope = base_scope.on_hand unless Spree::Config[:show_zero_stock_products]
        base_scope = add_search_scopes(base_scope)
        base_scope
    end

    def get_products_conditions_for(base_scope, query)
        unless query.blank?
            base_scope = base_scope.like_any([:name], query.split)
        end
        base_scope
    end
  end
end