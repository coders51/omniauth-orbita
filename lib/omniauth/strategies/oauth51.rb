require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Oauth51 < OmniAuth::Strategies::OAuth2
      option :name, :oauth51

      option :client_options, {
        site: 'https://www.oauth51.com',
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
