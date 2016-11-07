require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Orbita < OmniAuth::Strategies::OAuth2
      option :name, :orbita
      option :authorize_params, { locale: "en"}
      option :client_options, {
        site: 'http://connect.getorbita.io',
        authorize_url: '/oauth/authorize'
      }

      uid { raw_info['id'] }

      def authorize_params
        super.tap do |params|
          if request.params[:scope]
            params[:scope] = request.params[:scope]
          end
        end
      end

      def setup_phase
        request.env['omniauth.strategy'].options[:authorize_params][:locale] = request.params["locale"]
      end

      info do
        {
          email: raw_info['email'],
          image: raw_info['avatar_url']
        }
      end

      def raw_info
        @raw_info ||= access_token.get('/api/v1/users/me.json').parsed
      end
    end
  end
end
