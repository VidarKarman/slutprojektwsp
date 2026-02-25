require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :session
#db = SQLlite3::Database.new("db/users.db")
get('/') do
  slim(:home)
end

