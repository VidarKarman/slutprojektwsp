require 'sqlite3'

db = SQLite3::Database.new("users.db")


def seed!(db)
  puts "Using db file: db/users.db"
  puts "🧹 Dropping old tables..."
  drop_tables(db)
  puts "🧱 Creating tables..."
  create_tables(db)
  puts "🍎 Populating tables..."
  #populate_tables(db)
  #puts "✅ Done seeding the database!"
end

def drop_tables(db)
  db.execute('DROP TABLE IF EXISTS users')
end

def create_tables(db)
  db.execute('CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL, 
              pwddigest TEXT)')
end

#def populate_tables(db)
  #db.execute('INSERT INTO users (name, pwd-digest) VALUES ("Köp mjölk", "3 liter mellanmjölk, eko")')
#end


seed!(db)

db = SQLite3::Database.new("messages.db")

def seed2!(db)
  puts "Using db file: db/users.db"
  puts "🧹 Dropping old tables..."
  drop_tables2(db)
  puts "🧱 Creating tables..."
  create_tables2(db)
  puts "🍎 Populating tables..."
  #populate_tables(db)
  #puts "✅ Done seeding the database!"
end

def drop_tables2(db)
  db.execute('DROP TABLE IF EXISTS messages')
end

def create_tables2(db)
  db.execute('CREATE TABLE messages (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user1id TEXT NOT NULL, 
              user2id TEXT NOT NULL,
              contents TEXT,
              time INTEGER)')
end

seed2!(db)
