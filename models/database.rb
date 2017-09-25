require 'sequel'

class Database
	@DB = nil
	def setup
		@DB = wait_for_database
		create_database			
		@DB = Sequel.connect('postgres://postgres:postgres@db/clerk')
		@DB.extension :pg_json
		return @DB
	end

	def create_database
		print "Creating tables.....\n"
		print "**************************\n\n"

		db = Sequel.connect('postgres://postgres:postgres@db/clerk')

		unless db.table_exists?(:sites)
			db.create_table :sites do
				primary_key :id
			  String 		  :url
			  String			:base_url
			  Timestamp			:first_visted, default: Sequel::CURRENT_TIMESTAMP
			  Timestamp		  :last_visited, default: '1970-01-01 00:00:00'
			  index [:url]
			  unique [:url, :base_url]
			end
		end

		unless db.table_exists?(:claims)
			db.create_table :claims do
				primary_key :id
				String 		  :hash
			  JSONB      :claim_data
				foreign_key :site_id, 			:sites
			  Timestamp			:first_visted, default: Sequel::CURRENT_TIMESTAMP
			  Timestamp		  :last_visited, default: '1970-01-01 00:00:00'
			  index [:hash]
			end
		end
	end

	# Waits for the database to start up, will wail 1.5 minutes
	def wait_for_database
		print "Checking for postgres...\n"
		x = 0
		while x < 6
			begin
				db = Sequel.connect('postgres://postgres:postgres@db/clerk')
				x = 6
			rescue Sequel::DatabaseConnectionError
				print "Waiting for postgres to come up...\n"
				print "**************************\n\n"
				sleep 30
			end
			x += 1
		end
		print "postgres came up\n"
		print "**************************\n\n"
		return db
	end

end