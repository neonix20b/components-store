class Spree::MessagesController < Spree::StoreController
  #load_and_authorize_resource class: Spree::Address

  def index
    redirect_to account_path
  end

  def create
    redirect_to account_path
  end
end
