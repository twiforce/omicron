class SettingsRecord < ActiveRecord::Base
  serialize :allowed_file_types, Array
  serialize :spamtxt, Array
end
