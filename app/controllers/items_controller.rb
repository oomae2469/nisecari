class ItemsController < ApplicationController
  require "payjp"
  before_action :set_item, only: [:buy, :pay]
  def index
    @items = Item.includes(:item_images).order('created_at DESC')
  end

  def new
    @item = Item.new
    @item.item_images.new
  end

  def edit
    
  end

  def destroy
    
  end

  def create
    @item = Item.new(item_params)
    if @item.save!
      redirect_to root_path
    else
      render "/items/new"
    end
  end

  def update
    @item = Item.find(params[:id])
    if @item.update(item_params)
      redirect_to root_path
    else
      render "/items/new"
    end
  end

  def show
    @item = Item.find(params[:id])
  end


  def destroy
    item = Item.find(params[:id])
      if item.user_id == current_user.id
        item.destroy
      end
  end


  def buy
    @images = @item.item_images.all
    if user_signed_in?
      @user = current_user
      if @user.credit_card.present?
        Payjp.api_key = Rails.application.credentials.payjp[:PAYJP_SECRET_KEY]
        @card = CreditCard.find_by(user_id: current_user.id)
        customer = Payjp::Customer.retrieve(@card.customer_id)
        @customer_card = customer.cards.retrieve(@card.card_id)
        @card_brand = @customer_card.brand
        case @card_brand
        when "Visa"
         @card_src = "visa.png"
        when "JCB"
         @card_src = "jcb.png"
        when "MasterCard"
         @card_src = "master.png"
        when "American Express"
         @card_src = "amex.png"
        when "Diners Club"
         @card_src = "diners.png"
        when "Discover"
         @card_src = "discover.png"
        end
        @exp_month = @customer_card.exp_month.to_s
        @exp_year = @customer_card.exp_year.to_s.slice(2,3)
      end
    else
      redirect_to user_session_path, alert: "ログインしてください"
    end
  end
  
  
  def pay
    if @item.buyer_id.present?
      redirect_to item_path(@item.id), aleart: "売り切れています"
    else
      @item.with_lock do
        if current_user.credit_card.present?
          @card = CreditCard.find_by(user_id: current_user.id)
          Payjp.api_key = Rails.application.credentials.payjp[:PAYJP_SECRET_KEY]
          charge = Payjp::Charge.create(
            amount: @item.price,
            customer: Payjp::Customer.retrieve(@card.customer_id),
            currency: 'jpy'
          )
        else
          Payjp.api_key = Rails.application.credentials.payjp[:PAYJP_SECRET_KEY]
          Payjp::Charge.create(
            amount: @item.price,
            card: params['payjp-token'],
            currency: 'jpy'
          )
        end
       @item.update(buyer_id: current_user.id)
      end
    end
  end
    
  private
  def item_params
    params.require(:item).permit(:name, :price, :item_introduction, :item_condition_id, :postage_payer_id, :preparation_day_id, :prefecture_id).merge(seller_id: current_user.id)
  end
  
  def set_item
    @item = Item.find(params[:id])
  end
end

