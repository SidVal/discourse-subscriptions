# frozen_string_literal: true

# name: discourse-subscriptions
# about: Integrates Stripe into Discourse to allow visitors to subscribe
# version: 2.8.1
# url: https://github.com/rimian/discourse-subscriptions
# authors: Rimian Perkins

enabled_site_setting :discourse_subscriptions_enabled

gem 'stripe', '5.17.0'

register_asset "stylesheets/common/main.scss"
register_asset "stylesheets/common/layout.scss"
register_asset "stylesheets/common/subscribe.scss"
register_asset "stylesheets/mobile/main.scss"
register_svg_icon "credit-card" if respond_to?(:register_svg_icon)

register_html_builder('server:before-head-close') do
  "<script src='https://js.stripe.com/v3/'></script>"
end

extend_content_security_policy(
  script_src: ['https://js.stripe.com/v3/']
)

add_admin_route 'discourse_subscriptions.admin_navigation', 'discourse-subscriptions.products'

Discourse::Application.routes.append do
  get '/admin/plugins/discourse-subscriptions' => 'admin/plugins#index'
  get '/admin/plugins/discourse-subscriptions/products' => 'admin/plugins#index'
  get '/admin/plugins/discourse-subscriptions/products/:product_id' => 'admin/plugins#index'
  get '/admin/plugins/discourse-subscriptions/products/:product_id/plans' => 'admin/plugins#index'
  get '/admin/plugins/discourse-subscriptions/products/:product_id/plans/:plan_id' => 'admin/plugins#index'
  get '/admin/plugins/discourse-subscriptions/subscriptions' => 'admin/plugins#index'
  get '/admin/plugins/discourse-subscriptions/plans' => 'admin/plugins#index'
  get '/admin/plugins/discourse-subscriptions/plans/:plan_id' => 'admin/plugins#index'
  get 'u/:username/billing' => 'users#show', constraints: { username: USERNAME_ROUTE_FORMAT }
  get 'u/:username/billing/:id' => 'users#show', constraints: { username: USERNAME_ROUTE_FORMAT }
end

after_initialize do
  ::Stripe.api_version = "2019-12-03"

  ::Stripe.set_app_info(
    'Discourse Subscriptions',
    version: '2.8.1',
    url: 'https://github.com/rimian/discourse-subscriptions'
  )

  [
    "../lib/discourse_subscriptions/engine",
    "../config/routes",
    "../app/controllers/concerns/group",
    "../app/controllers/concerns/stripe",
    "../app/controllers/admin_controller",
    "../app/controllers/admin/plans_controller",
    "../app/controllers/admin/products_controller",
    "../app/controllers/admin/subscriptions_controller",
    "../app/controllers/user/payments_controller",
    "../app/controllers/user/subscriptions_controller",
    "../app/controllers/customers_controller",
    "../app/controllers/hooks_controller",
    "../app/controllers/invoices_controller",
    "../app/controllers/plans_controller",
    "../app/controllers/payments_controller",
    "../app/controllers/products_controller",
    "../app/controllers/subscriptions_controller",
    "../app/models/customer",
    "../app/serializers/payment_serializer",
  ].each { |path| require File.expand_path(path, __FILE__) }

  Discourse::Application.routes.append do
    mount ::DiscourseSubscriptions::Engine, at: 's'
  end
end
