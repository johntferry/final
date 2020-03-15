# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"
require "geocoder"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

vacations_table = DB.from(:vacations)
suggestions_table = DB.from(:suggestions)
users_table = DB.from(:users)

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

### vacations summary section ###

# homepage and list of vacations (aka "index")
get "/" do
    puts "params: #{params}"

    @vacations = vacations_table.all.to_a
    pp @vacations

    view "vacations"
end

### Locations detail section ###

# location details (aka "show")
get "/location/:id" do
    puts "params: #{params}"

    @location = vacations_table.where(id: params[:id]).to_a[0]
    pp @location
    @users_table = users_table

    results = Geocoder.search(@location[:location])
    lat_long = results.first.coordinates # => [lat, long]
    @coordinates = lat_long[0], lat_long[1]

    @latitude = lat_long[0]
    @longitude = lat_long[1]

    @suggestions = suggestions_table.where(vacations_id: @location[:id]).to_a
    @suggestions_count = suggestions_table.where(vacations_id: @location[:id]).count

    view "location"

end

# display the suggestions form (aka "new")
get "/location/:id/suggestions/new" do
    puts "params: #{params}"

    @location = vacations_table.where(id: params[:id]).to_a[0]
    view "new_suggestion"
end

# receive the submitted suggestions form (aka "create")
post "/location/:id/suggestions/create" do
    puts "params: #{params}"

    # first find the location that you are leaving a suggestion for
    @location = vacations_table.where(id: params[:id]).to_a[0]

    # next we want to insert a row in the suggestions table with the suggestions form data
    suggestions_table.insert(
        vacations_id: @location[:id],
        user_id: session["user_id"],
        comments: params["comments"],
        name: @current_user[:name],
        email: @current_user[:email]
    )

    redirect "/location/#{@location[:id]}"
end

### Users logic section ###

# display the signup form (aka "new")
get "/users/new" do
    view "new_user"
end

# receive the submitted signup form (aka "create")
post "/users/create" do
    puts "params: #{params}"

    # if there's already a user with this email, skip!
    existing_user = users_table.where(email: params["email"]).to_a[0]
    if existing_user
        view "error"
    else
        users_table.insert(
            name: params["name"],
            email: params["email"],
            password: BCrypt::Password.create(params["password"])
        )

        redirect "/logins/new"
    end
end

# display the login form (aka "new")
get "/logins/new" do
    view "new_login"
end

# receive the submitted login form (aka "create")
post "/logins/create" do
    puts "params: #{params}"

    # step 1: user with the params["email"] ?
    @user = users_table.where(email: params["email"]).to_a[0]

    if @user
        # step 2: if @user, does the encrypted password match?
        if BCrypt::Password.new(@user[:password]) == params["password"]
            # set encrypted cookie for logged in user
            session["user_id"] = @user[:id]
            redirect "/"
        else
            view "create_login_failed"
        end
    else
        view "create_login_failed"
    end
end

# logout user
get "/logout" do
    # remove encrypted cookie for logged out user
    session["user_id"] = nil
    # redirect "/logins/new"
    view "logout"
end