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

get('/register') do



  slim(:register)
end

post('/login') do
  user = params["user"]
  pwd = params["pwd"]
  db = SQLite3::Database.new("db/user.db")
  result = db.execute("SELECT id,pwddigest FROM users WHERE user=?",user)

  if result.empty?
    redirect('/error')
  end
  user_id = result.first["id"]
  pwd_digest = result.first["pwddigest"]

  if BCrypt::Password.new(pwddigest) == pwd
    session[:user_id] = user_id
    redirect('/chat')
  else
    redirect('/login')
  end
end

post('/register') do
  user = params["user"]
  pwd = params["pwd"]
  pwd_confirm = params["pwd_confirm"]

  db = SQLite3::Database.new("db/users.db")
  result=db.execute("SELECT id FROM users WHERE user=?", user)

  if result.empty?
    if pwd==pwd_confirm
      pwd_digest=BCrypt::Password.create(pwd)
      db.execute("INSERT INTO users(user, pwd_digest) VALUES(?,?)", [user, pwd_digest])
      redirect('/')
    else
      redirect('/')  #till standardsidan med error
end