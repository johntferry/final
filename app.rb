# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"                                                                      #
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

# homepage and list of vacations (aka "index")
get "/" do
    puts "params: #{params}"

    @vacations = vacations_table.all.to_a
    pp @vacations

    view "vacations"
end

# vacation suggestions (aka "show")
get "/vacations/:id" do
    puts "params: #{params}"

    @users_table = users_table
    @vacation = vacations_table.where(id: params[:id]).to_a[0]
    pp @vacation

    @suggestions = suggestions_table.where(vacation_id: @vacation[:id]).to_a
    @suggestion = suggestions_table.where(vacation_id: @vacation[:id]).to_a[0]
    pp @suggestion

    view "vacation"
end

# display the suggestions form (aka "new")
get "/vacations/:id/suggestions/new" do
    puts "params: #{params}"

    @vacation = vacations_table.where(id: params[:id]).to_a[0]
    view "new_suggestion"
end

# receive the submitted suggestion form (aka "create")
post "/vacations/:id/suggestions/create" do
    puts "params: #{params}"

    # first find the vacation that the suggestion is for
    @vacation = vacations_table.where(id: params[:id]).to_a[0]
    # next we want to insert a row in the suggestions table with the suggestion form data
    suggestions_table.insert(
        vacation_id: @vacation[:id],
        user_id: session["user_id"],
        comments: params["comments"]
    )

    redirect "/vacations/#{@vacation[:id]}"
end

# display the suggestion form (aka "edit")
get "/suggestions/:id/edit" do
    puts "params: #{params}"

    @suggestion = sugugestions_table.where(id: params["id"]).to_a[0]
    @vacation = vacations_table.where(id: @vacation[:vacation_id]).to_a[0]
    view "edit_suggestion"
end

# receive the submitted suggestion form (aka "update")
post "/suggestions/:id/update" do
    puts "params: #{params}"

    # find the suggestion to update
    @suggestioen = suggestions_table.where(id: params["id"]).to_a[0]
    # find the suggestion's vacation
    @vacation = vacations_table.where(id: @suggestion[:vacation_id]).to_a[0]

    if @current_user && @current_user[:id] == @suggestion[:id]
        suggestions.where(id: params["id"]).update(
            going: params["going"],
            comments: params["comments"]
        )

        redirect "/vacations/#{@vacation[:id]}"
    else
        view "error"
    end
end

# delete the suggestion (aka "destroy")
get "/suggestions/:id/destroy" do
    puts "params: #{params}"

    suggestion = suggestions_table.where(id: params["id"]).to_a[0]
    @vacation = vacations_table.where(id: suggestion[:vacation_id]).to_a[0]

    suggestions_table.where(id: params["id"]).delete

    redirect "/vacations/#{@vacation[:id]}"
end

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
    redirect "/logins/new"
end