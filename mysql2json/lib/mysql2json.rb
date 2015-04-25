

class MySQL2JSON 
     require 'json'
     require 'mysql'

     # JSON module as mixin
     include JSON
     
     def initialize(args={})
         @server=   args[:server]||'localhost'
         @port=     args[:port]||3306
         @user=     args[:user]||'root'
         @password= args[:password]
         @db_list=  args[:db_list]||[]
         @json_hash=Hash.new()

         connect
         
         # if an user hasn't declared the list of databases, we take all ones
         if @db_list.empty?
            @connection.query("show databases").each do |db|
               @db_list.push db[0]
            end  
         end

         retrieve_data
         #
         disconnect
         #
         
     end

    def connect
        begin
          @connection=Mysql.connect(@server,@user,@password,'mysql')
          rescue ServerError=>error
             @last_error=error
             raise
          end
          puts "Connected to #{@server}"
     
    end

   def disconnect
       @connection.close
   end

   # here we use the powerful Ruby technology named "mixins"
   def generate(obj,opts = nil)
       state = PRETTY_STATE_PROTOTYPE.dup
       state.generate(obj)
   end

   def retrieve_data
       @db_list.each do |db|

          # here we use a little bit sophisticated data structure
          # which may be named as "hash of arrays of hashes"

          tables=Array.new()
         
          @connection.query("use "+db)
           @connection.query("show tables").each do |table|
             tables.push table[0]
          end
          tables.each do |table|
             puts "Reading table #{table} from database #{db}..."
             @json_hash[table]=Array.new()
             fields=@connection.list_fields table
             fields_array=fields.fetch_fields
             j=0
             @connection.query("select * from "+table).each do |query_result_line|
                @json_hash[table].push Hash.new()
               
                query_result_line.each_index do |i|
                   field=fields_array.at(i)
                   key=field.name
                   @json_hash[table][j][key]=query_result_line.at(i)
                end

                j+=1
             end
          end

          dump db
       
      end
   end
     
   def dump(database)
     fjson=File.open(database+".json",'w')
     puts "Writing  database #{database} to json file..."
     json=generate @json_hash
     fjson.puts json
     puts "Done."
     fjson.close
   end

end



