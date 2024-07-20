class Spree::Admin::EmailsController < Spree::Admin::ResourceController
  def index; end

  private
  def model_class
    Email
  end

  def scope
    Email.all
    #current_store.emails
  end

  def find_resource
    scope.find(params[:id])
  end

  def collection
    return @collection if @collection.present?

    params[:q] ||= {}
    @collection = scope

    @search = @collection.ransack(params[:q])
    @collection = @search.result.page(params[:page]).
                  per(params[:per_page] || 100)
  end

  def location_after_save
    spree.edit_admin_email_path(@email)
  end

end
