require "redcarpet"
require "rubypress"
require "dotenv"

require "pry"

Dotenv.load

wp = Rubypress::Client.new(
  host: "localhost",
  port: 8080,
  username: ENV["WP_USER_NAME"],
  password: ENV["WP_USER_PASS"]
)

binding.pry