class UpgradeTo48 < ActiveRecord::Migration[7.1]
   DEFAULT_LOCALE = 'ru'
   PRODUCTS_TABLE = 'spree_products'
   PRODUCT_TRANSLATIONS_TABLE = 'spree_product_translations'
   TAXONS_TABLE = 'spree_taxons'
   TAXON_TRANSLATIONS_TABLE = 'spree_taxon_translations'

  def up
    remove_index :spree_taxon_translations, name: 'unique_permalink_per_locale', if_exists: true
    Spree::TranslationMigrations.new(Spree::Store, 'ru').revert_translation_data_transfer
    Spree::TranslationMigrations.new(Spree::Taxonomy, 'ru').revert_translation_data_transfer

    ActiveRecord::Base.connection.execute("
       UPDATE #{PRODUCTS_TABLE} as products
       SET (name,
            description,
            meta_description,
            meta_keywords,
            meta_title,
            slug) =
           (t_products.name,
            t_products.description,
            t_products.meta_description,
            t_products.meta_keywords,
            t_products.meta_title,
            t_products.slug)
       FROM #{PRODUCT_TRANSLATIONS_TABLE} AS t_products
       WHERE t_products.spree_product_id = products.id
     ")

     ActiveRecord::Base.connection.execute("
       TRUNCATE TABLE #{PRODUCT_TRANSLATIONS_TABLE}
                                           ")

     ActiveRecord::Base.connection.execute("
       UPDATE #{TAXONS_TABLE} as taxons
       SET (name,
            description,
            meta_title,
            meta_description,
            meta_keywords,
            permalink) =
           (t_taxons.name,
            t_taxons.description,
            t_taxons.meta_title,
            t_taxons.meta_description,
            t_taxons.meta_keywords,
            t_taxons.permalink)
       FROM #{TAXON_TRANSLATIONS_TABLE} AS t_taxons
       WHERE t_taxons.spree_taxon_id = taxons.id
     ")

     ActiveRecord::Base.connection.execute("
       TRUNCATE TABLE #{TAXON_TRANSLATIONS_TABLE}
                                           ")

     ActiveRecord::Base.connection.execute("
       UPDATE spree_properties AS properties
       SET (name, presentation, filter_param) = (t_properties.name, t_properties.presentation, t_properties.filter_param)
       FROM spree_property_translations AS t_properties
       WHERE t_properties.spree_property_id = properties.id;
     ")
     ActiveRecord::Base.connection.execute("
       TRUNCATE TABLE spree_property_translations;
     ")

     # Product Properties
     ActiveRecord::Base.connection.execute("
       UPDATE spree_product_properties AS product_properties
       SET (value, filter_param) = (t_product_properties.value, t_product_properties.filter_param)
       FROM spree_product_property_translations AS t_product_properties
       WHERE t_product_properties.spree_product_property_id = product_properties.id;
     ")
     ActiveRecord::Base.connection.execute("
       TRUNCATE TABLE spree_product_property_translations;
     ")

     ActiveRecord::Base.connection.execute("
       UPDATE spree_option_types as option_types
       SET (name, presentation) = (t_option_types.name, t_option_types.presentation)
       FROM spree_option_type_translations AS t_option_types
       WHERE t_option_types.spree_option_type_id = option_types.id;
     ")
     ActiveRecord::Base.connection.execute("
       TRUNCATE TABLE spree_option_type_translations;
     ")

     # Option Values
     ActiveRecord::Base.connection.execute("
       UPDATE spree_option_values as option_values
       SET (name, presentation) = (t_option_values.name, t_option_values.presentation)
       FROM spree_option_value_translations AS t_option_values
       WHERE t_option_values.spree_option_value_id = option_values.id;
     ")
     ActiveRecord::Base.connection.execute("
       TRUNCATE TABLE spree_option_value_translations;
     ")
     ActiveRecord::Base.connection.execute("
       UPDATE #{PRODUCTS_TABLE} as products
       SET (name,
            description,
            meta_description,
            meta_keywords,
            meta_title,
            slug) =
           (t_products.name,
            t_products.description,
            t_products.meta_description,
            t_products.meta_keywords,
            t_products.meta_title,
            t_products.slug)
       FROM #{PRODUCT_TRANSLATIONS_TABLE} AS t_products
       WHERE t_products.spree_product_id = products.id
     ")

     ActiveRecord::Base.connection.execute("
       TRUNCATE TABLE #{PRODUCT_TRANSLATIONS_TABLE}
                                           ")

     ActiveRecord::Base.connection.execute("
       UPDATE #{TAXONS_TABLE} as taxons
       SET (name,
            description) =
           (t_taxons.name,
            t_taxons.description)
       FROM #{TAXON_TRANSLATIONS_TABLE} AS t_taxons
       WHERE t_taxons.spree_taxon_id = taxons.id
     ")

     ActiveRecord::Base.connection.execute("
       TRUNCATE TABLE #{TAXON_TRANSLATIONS_TABLE}
                                           ")
      ActiveRecord::Base.connection.execute("
       UPDATE #{PRODUCTS_TABLE} as products
       SET (name,
            description,
            meta_description,
            meta_keywords,
            meta_title,
            slug) =
           (t_products.name,
            t_products.description,
            t_products.meta_description,
            t_products.meta_keywords,
            t_products.meta_title,
            t_products.slug)
       FROM #{PRODUCT_TRANSLATIONS_TABLE} AS t_products
       WHERE t_products.spree_product_id = products.id
     ")

     ActiveRecord::Base.connection.execute("
       TRUNCATE TABLE #{PRODUCT_TRANSLATIONS_TABLE}
                                           ")

     ActiveRecord::Base.connection.execute("
       UPDATE #{TAXONS_TABLE} as taxons
       SET (name,
            description) =
           (t_taxons.name,
            t_taxons.description)
       FROM #{TAXON_TRANSLATIONS_TABLE} AS t_taxons
       WHERE t_taxons.spree_taxon_id = taxons.id
     ")

     ActiveRecord::Base.connection.execute("
       TRUNCATE TABLE #{TAXON_TRANSLATIONS_TABLE}
                                           ")

    change_column_null :spree_taxonomies, :name, false
    change_column_null :spree_properties, :presentation, false
    change_column_null :spree_taxons, :name, false
    change_column_null :spree_products, :name, false
  end

  def down
    
  end
end
