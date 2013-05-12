# Load the rails application
require File.expand_path('../application', __FILE__)

VERSION = '7.30'
SALT    = 'otsosee'

RANDOM = 'RANDOM()' if Rails.env.development?
RANDOM = 'RAND()' if Rails.env.production?

BANNED_PASSWORDS = Array.new
DEFENCE_MODE = true

Haml::Template.options[:format]     = :html5
Haml::Template.options[:ugly]       = true


Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
# Initialize the rails application
Omicron::Application.initialize!

