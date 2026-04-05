require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions
#db = SQLlite3::Database.new("db/users.db")
get('/') do

  slim(:home)
end
get('/chat') do
  redirect('/') unless session[:user_id]
  @chaten = session[:chat_with]
  db = SQLite3::Database.new("db/messages.db")
  db.results_as_hash = true
  db.execute("ATTACH DATABASE 'db/users.db' AS users_db")
  @activechat = db.execute(
    "SELECT m.id, m.user1id, m.user2id, m.contents, m.time, u.username AS sender_name \
     FROM messages m \
     JOIN users_db.users u ON m.user1id = u.id \
     WHERE (m.user1id = ? AND m.user2id = ?) OR (m.user1id = ? AND m.user2id = ?) \
     ORDER BY m.id ASC",
    [session[:user_id], @chaten, @chaten, session[:user_id]]
  )
  db.execute("DETACH DATABASE users_db")
  partners = db.execute("SELECT DISTINCT CASE WHEN user1id = ? THEN user2id ELSE user1id END AS partner_id FROM messages WHERE user1id = ? OR user2id = ?", [session[:user_id], session[:user_id], session[:user_id]])
  @chats = []
  partners.each do |p|
    db_users = SQLite3::Database.new("db/users.db")
    db_users.results_as_hash = true
    user = db_users.execute("SELECT username FROM users WHERE id = ?", p["partner_id"]).first
    @chats << {"id" => p["partner_id"], "username" => user["username"]} if user
  end
  slim(:chat)
end
post('/chat') do
  redirect('/') unless session[:user_id]
  chat_param = params["chat"]
  if chat_param =~ /^\d+$/
    session[:chat_with] = chat_param.to_i
  else
    db = SQLite3::Database.new("db/users.db")
    db.results_as_hash = true
    partner = db.execute("SELECT id FROM users WHERE username = ?", chat_param).first
    if partner
      session[:chat_with] = partner["id"]
    else
      # handle error, maybe redirect back
      redirect('/chat')
    end
  end
  redirect('/chat')
end
post('/typedmessage') do
  halt(401, 'Not logged in') unless session[:user_id]
  halt(400, 'No active chat selected') unless session[:chat_with]

  message = params["message"]
  timestamp = Time.now.to_i
  db = SQLite3::Database.new("db/messages.db")
  db.results_as_hash = true
  db.execute("INSERT INTO messages(user1id, user2id, contents, time) VALUES(?,?,?,?)", [session[:user_id], session[:chat_with], message, timestamp])
  redirect('/chat')
end
post('/delete_message') do
  halt(401, 'Not logged in') unless session[:user_id]
  message_id = params["message_id"].to_i
  db = SQLite3::Database.new("db/messages.db")
  db.results_as_hash = true
  result = db.execute("SELECT user1id FROM messages WHERE id = ?", message_id).first
  if result && result["user1id"].to_i == session[:user_id].to_i
    db.execute("DELETE FROM messages WHERE id = ?", message_id)
  end
  redirect('/chat')
end
post('/edit_message') do
  halt(401, 'Not logged in') unless session[:user_id]
  message_id = params["message_id"].to_i
  new_content = params["new_content"]
  db = SQLite3::Database.new("db/messages.db")
  db.results_as_hash = true
  result = db.execute("SELECT user1id FROM messages WHERE id = ?", message_id).first
  if result && result["user1id"].to_i == session[:user_id].to_i
    db.execute("UPDATE messages SET contents = ? WHERE id = ?", [new_content, message_id])
  end
  redirect('/chat')
end
post('/login') do
  user = params["username"].to_s.strip
  pwd = params["pwd"].to_s

  if user.empty? || pwd.empty?
    @error = "Användarnamn och lösenord krävs"
    return slim(:home)
  end

  db = SQLite3::Database.new("db/users.db")
  db.results_as_hash = true
  result = db.execute("SELECT id,pwddigest FROM users WHERE username=?", user)

  if result.empty?
    @error = "Fel användarnamn eller lösenord"
    return slim(:home)
  end

  user_id = result.first["id"]
  pwd_digest = result.first["pwddigest"]

  if BCrypt::Password.new(pwd_digest) == pwd
    session[:user_id] = user_id
    redirect('/chat')
  else
    @error = "Fel användarnamn eller lösenord"
    slim(:home)
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