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
  foreign_key :vacations_id
  foreign_key :user_id
  String :comments, text: true
  String :name
  String :email
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
vacations_table = DB.from(:vacations)
suggestions_table = DB.from(:suggestions)

vacations_table.insert(title: "Surfing Teahupo'o in Tahiti", 
                    description: "Surfing this absolutle monster wave -- what do you think I should do in Tahiti if I survive?",
                    date: "October 7, 2020",
                    location: "Tahiti")

vacations_table.insert(title: "Beijing Jiaozi Tour", 
                    description: "Exploring the hutongs in Beijing and eating an insane amount of dumplings.",
                    date: "February 20, 2020",
                    location: "Beijing")

suggestions_table.insert(vacations_id: 1,
                    user_id: 0,
                    comments: "Make sure you visit Bora Bora and Moorea while you're there!",
                    name: "John Ferry",
                    email: "john@johntferry.com")

suggestions_table.insert(vacations_id: 1,
                    user_id: 1,
                    comments: "I highly doubt you survive surfing that wave. Cancel the trip.",
                    name: "Alex Ferry",
                    email: "alex@johntferry.com")

suggestions_table.insert(vacations_id: 2,
                    user_id: 3,
                    comments: "Baijiu is a great drink to include, but beware it tastes a bit like jet fuel and operates similarly.",
                    name: "Tim Ferry",
                    email: "tim@johntferry.com")

puts "Success!"