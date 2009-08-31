# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_wlc_session',
  :secret      => 'bc5a09342cf6fff5bf217e4a2fe78aa0ffea1db796b7bf9d8c5af931161654e120c188da971eadacb5f53c82948597dddae29d211355c16649be583aaf8052d8'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
