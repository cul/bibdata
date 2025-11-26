# frozen_string_literal: true

class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: Devise.omniauth_configs.keys
end
