# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :vacations do
  primary_key :id
  String :title
  String :description, text: true
  String :date
  String :location
end
DB.create_table! :suggestions do
  primary_key :id
  foreign_key :vacation_id
  String :name
  String :email
  String :suggestion, text: true
end

DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
vacations_table = DB.from(:vacations)

vacations_table.insert(title: "Tahiti Teahupo'o Surfing", 
                    description: "I will be going to Tahiti to surf one of the biggest waves of the world, Teahupo'o. Wish me luck.",
                    date: "October 7, 2020",
                    location: "Tahiti")

vacations_table.insert(title: "Beijing Jiaozi Tour", 
                    description: "I'm so excited to go to the old hutongs in Beijing for a jiaozi tour. What else should I do?",
                    date: "February 10, 2021",
                    location: "Beijing, China")
