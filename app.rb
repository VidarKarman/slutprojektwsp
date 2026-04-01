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
  @chaten = session[:chat_with]
  db = SQLite3::Database.new("db/messages.db")
  db.results_as_hash = true
  @activechat = db.execute(
    "SELECT user1id, user2id, contents, time FROM messages WHERE user1id=? AND user2id=?",
    [session[:user_id], @chaten]
  )
  @chats = db.execute("SELECT DISTINCT user2id FROM messages WHERE user1id=?", session[:user_id])
  slim(:chat)
end
post('/chat') do
  @chaten = params["chat"]
  session[:chat_with] = params["chat"]
  db = SQLite3::Database.new("db/messages.db")
  db.results_as_hash = true
  @activechat = {}
  @activechat = db.execute("SELECT user1id, user2id, contents, time FROM messages WHERE user1id=? AND user2id=?",[session[:user_id], @chaten])  
  redirect('/chat')
end
post('/typedmessage') do
  halt(401, 'Not logged in') unless session[:user_id]
  halt(400, 'No active chat selected') unless session[:chat_with]

  message = params["message"]
  db = SQLite3::Database.new("db/messages.db")
  db.results_as_hash = true
  db.execute("INSERT INTO messages(user1id, user2id, contents) VALUES(?,?,?)", [session[:user_id], session[:chat_with], message])
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
      session[:user_id] = db.last_insert_row_id
      session[:chat_with] = nil
      redirect('/chat')
    else
      redirect('/')  #till standardsidan med error
    end
  else
    redirect('/')
  end
end