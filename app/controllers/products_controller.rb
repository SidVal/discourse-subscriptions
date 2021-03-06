# frozen_string_literal: true

module DiscourseSubscriptions
  class ProductsController < ::ApplicationController
    include DiscourseSubscriptions::Stripe

    before_action :set_api_key

    def index
      begin
        response = ::Stripe::Product.list(active: true)

        products = response[:data].map do |p|
          serialize(p)
        end

        render_json_dump products

      rescue ::Stripe::InvalidRequestError => e
        render_json_error e.message
      end
    end

    def show
      begin
        product = ::Stripe::Product.retrieve(params[:id])

        render_json_dump serialize(product)

      rescue ::Stripe::InvalidRequestError => e
        render_json_error e.message
      end
    end

    private

    def serialize(product)
      {
        id: product[:id],
        name: product[:name],
        description: product[:metadata][:description],
        subscribed: current_user_products.include?(product[:id])
      }
    end

    def current_user_products
      return [] if current_user.nil?

      ::DiscourseSubscriptions::Customer
        .select(:product_id)
        .where(user_id: current_user.id)
        .map { |c| c.product_id }.compact
    end
  end
end
