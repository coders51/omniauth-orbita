# Orbita

This gem implementation the OmniAuth strategy for the Orbita

Alongside with this gem, you should use also [oauth51-client](https://github.com/coders51/oauth51-client/) gem which provides an interface with Orbita API.

For the login process, add this gem to your `Gemfile`:

```ruby
gem 'omniauth-orbita', github: 'coders51/omniauth-orbita.git'
gem 'oauth51-client', github: 'coders51/oauth51-client.git'
```

Then you should simply follow the [Oauth instruction for devise](https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview) with some additions. Let's see the whole process:

## Fields in the User model

Orbita login mechanism relies on some fields that should be present in the user model. You can generate a migration with this content:

```ruby
# rails g migration add_fields_to_users
# and the edit the resulting file:

class AddFieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :o51_authentication_token, :string         # Will store the auth token
    add_column :users, :o51_authentication_token_secret, :string  # Will store the token secret used for refresh
    add_column :users, :o51_expires_at, :datetime                 # Will hold token expiration
    add_column :users, :o51_profile, :text                        # or :json if you're on postgres
    add_column :users, :o51_picture_url, :string                  # link to the picture
    add_column :users, :o51_uid, :string                          # Uid of the user
    add_column :users, :o51_points, :integer                      # Points of the user
  end
end
```

## Devise configuration

First of all, configure your `secrets.yml` with relevant data, for example:

```yaml
development:
  secret_key_base: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  oauth:
    client_id: OAUTH_CLIENT_ID
    client_secret: OAUTH_CLIENT_SECRET
    app_url: BASE_URL_OF_ORBITA_SERVER # like http://connect.getorbita.io
```

Then you can go and edit `config/initializers/devise.rb`, adding at the bottom:

```ruby
Devise.setup do |config|
  # cut
  config.omniauth :orbita, Rails.application.secrets.oauth['client_id'], Rails.application.secrets.oauth['client_secret'], scope: 'public accounts points', client_options: {site: Rails.application.secrets.oauth['app_url']}
end
```

## Routes and Devise part 2

Ad described in the Devise Wiki for omniauth, we need a controller with an action called as the provider where we will handle the login phase.

Time to create our `app/controllers/omniauth_callbacks_controller.rb`:

```ruby
class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # This action will be called when returing from authentication process.
  # request.env['omniauth.auth'] will hold all informations.
  # Let's handle login process as a class method in User model
  def orbita
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted? # The user has been succesfully saved
      sign_in_and_redirect @user
    else
      # This should never happend, you should investigate otherwise
      redirect_to session[:last_path] || root_path
    end
  end
end
```

And then we can check our `routes.rb` and be sure devise uses that controller:

```ruby
Rails.application.routes.draw do
  # cut
  devise_for :users, controllers: {omniauth_callbacks: 'omniauth_callbacks'}
end
```

We also need the `from_omniauth` method in the user model and some other tweeks.
**Remember** to add :omniauthable to devise definition.

Also add `include Oauth51Client::User` to add a couple of useful methods to User model.

```ruby
class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable,
    :confirmable, :omniauthable

  include Oauth51Client::User

  def self.from_omniauth(auth)
    random_psw = Devise.friendly_token[0,20]

    this_user = where(o51_uid: auth.uid).first_or_initialize do |user|
      user.email = auth.info.email
      user.password = random_psw
      user.password_confirmation = random_psw
    end

    # Let's apply fresh data
    this_user.o51_authentication_token = auth.credentials.token
    this_user.o51_authentication_token_secret = auth.credentials.refresh_token
    this_user.o51_expires_at = (Time.at(auth.credentials.expires_at) rescue nil)

    # o51_client is defined in oauth51-client gem
    profile = this_user.o51_client.me
    this_user.o51_points = profile['points']
    this_user.o51_picture_url = profile['avatar_url']
    this_user.o51_authentication_token = auth.credentials.token
    this_user.o51_authentication_token_secret= auth.credentials.refresh_token
    this_user.o51_profile = profile.to_json
    this_user.save
    this_user
  end
end
```

And that's it.

## Tip & Triks

### Logout from oauth server when logging out from your application

Edit your `application_controller.rb` and add

```ruby
  def after_sign_out_path_for(resource)
    # Here we redirect the user to the logout path of orbita, which will logout the user
    # And redirect back here
    target_path = request.referrer || root_path
    "#{Rails.application.secrets.oauth['app_url']}/users/sign_out?return_to=#{target_path}"
  end
```

### Handle expired tokens and similar problemn

Always in your `application_controller.rb`, add this:

```ruby
  rescue_from RestClient::Unauthorized, with: :handle_unauthorized

  def handle_unauthorized
    if user_signed_in?
      Rails.logger.info "User #{current_user.email} is logged in but we're having 401 with oauth"
      redirect_to destroy_user_session_path
    end
  end
```


## Oauth51Client::User methods

Including Oauth51Client::User will add the following methods:

**o51_client** Will return a Oauth51Client::Client initialized with user token. Will point to the server identified by `Rails.application.secrets.oauth['app_url']`, so be sure to have it.

**o51_token_expired?** whatever the token is expired or not.

**o51_authentication_token!** Will return the auth token, refreshes it if needed

**o51_refesh_token** Refresh the token if needed
