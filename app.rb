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
get('/chat') do
  db = SQLite3::Database.new("db/messages.db")
  db.results_as_hash = true
  @chats = db.execute("SELECT user2id FROM messages WHERE user1id=?", session[:user_id])
  slim(:chat)
end
post('/chat') do
  chaten = params["chat"]
  db = SQLite3::Database.new("db/messages.db")
  db.results_as_hash = true
  @activechat = db.execute("SELECT user1id, user2id, contents, time FROM messages WHERE user1id=? AND user2id=?",[session[:user_id], chaten])  
  redirect('/chat')
end

post('/login') do
  user = params["username"]
  pwd = params["pwd"]
  db = SQLite3::Database.new("db/users.db")
  db.results_as_hash = true
  result = db.execute("SELECT id,pwddigest FROM users WHERE username=?",user)

  if result.empty?
    redirect('/')
  end
  user_id = result.first["id"]
  pwd_digest = result.first["pwddigest"]

  if BCrypt::Password.new(pwd_digest) == pwd
    session[:user_id] = user_id
    redirect('/chat')
  else
    redirect('/')
  end
end

post('/register') do
  user = params["username"]
  pwd = params["pwd"]
  pwd_confirm = params["pwd_confirm"]

  db = SQLite3::Database.new("db/users.db")
  db.results_as_hash = true
  result=db.execute("SELECT id FROM users WHERE username=?", user)
  

  if result.empty?
    if pwd==pwd_confirm
      pwd_digest=BCrypt::Password.create(pwd)
      db.execute("INSERT INTO users(username, pwddigest) VALUES(?,?)", [user, pwd_digest])
      db.execute("INSERT INTO messages(user1id, user2id, contents, ) VALUES(?,?)", [user, pwd_digest])
      redirect('/chat')
    else
      redirect('/')  #till standardsidan med error
    end
  else
    redirect('/')
  end
end