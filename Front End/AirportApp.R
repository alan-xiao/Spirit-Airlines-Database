# Turn warnings off
options(warn=-1)

# Turn warnings on 
#options(warn=0)


# Initializing packages ---------------------------------------------------

list.of.packages = c("shiny", "shinydashboard", "shinycssloaders","DT","RMySQL","DBI",
                     "shinyTime", "shinyjs", "sodium", "stringi","data.table","BBmisc", 'ggplot2',
                     'dplyr', 'reshape2', 'svDialogs','testit')

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

# Downloading the packages if not already installed
for (pkg in list.of.packages) {
  if (pkg %in% rownames(.packages()) == FALSE)
  {library(pkg, character.only = TRUE)}
}

# User database details ---------------------------------------------------

exit <- function() {
  .Internal(.invokeRestart(list(NULL, NULL), NULL))
}


user.name <- dlgInput("Enter MySQL username:", "username")$res

if (!length(user.name)) {# The user clicked the 'cancel' button
  dlg_message('Please restart the application')$res
  exit()
  break
}

user.password <- dlgInput("Enter MySQL password: ", "password")$res

if (!length(user.password)) {# The user clicked the 'cancel' button
  dlg_message('Please restart the application')$res
  exit()
  break
}

host.val <- dlgInput("Enter Host Name: ", "127.0.0.1")$res

if (!length(host.val)) {# The user clicked the 'cancel' button
  dlg_message('Please restart the application')$res
  exit()
  break
}

# Database Connection  ----------------------------------------------------
# Connecting to the database

# Connecting to my local host server and the lotrfinal database.
# TO MARKER: If you have a different host, you need to change this
while (has_error(dbConnect(MySQL(), user=user.name, password=user.password, 
                           dbname='AirportDB', host=host.val)) == TRUE)
{
  user.name <- dlgInput("Error in username or password. Enter MySQL username:", "username")$res
  
  if (!length(user.name)) {# The user clicked the 'cancel' button
    dlg_message('Please restart the application')$res
    exit()
    break
  }
  
  user.password <- dlgInput("Error in username or password. Enter MySQL password: ", "password")$res
  
  if (!length(user.password)) {# The user clicked the 'cancel' button
    dlg_message('Please restart the application')$res
    exit()
    break
  }
  
  host.val <- dlgInput("Enter Host Name: ", "127.0.0.1")$res
  
  if (!length(host.val)) {# The user clicked the 'cancel' button
    dlg_message('Please restart the application')$res
    exit()
    break
  }
  
  
}

if (has_error(dbConnect(MySQL(), user=user.name, password=user.password, 
                        dbname='AirportDB', host=host.val)) == FALSE){
  dlg_message('Database has successfully connected')$res
}

assign("usernameInput",user.name, envir = .GlobalEnv)
assign("passwordInput",user.password, envir = .GlobalEnv)
assign("hostInput",host.val, envir = .GlobalEnv)


args <- list(
  drv = RMySQL::MySQL(),
  dbname = "AirportDB",
  host = hostInput,
  username = usernameInput,
  password = passwordInput
)

# User Login ----------------------------------------------------
loginpage <- div(id = "loginpage", style = "width: 500px; max-width: 100%; margin: 0 auto; padding: 20px;",
                 wellPanel(
                   tags$h2("LOG IN", class = "text-center", style = "padding-top: 0;color:#333; font-weight:600;"),
                   textInput("userName", placeholder="Username", label = tagList(icon("user"), "Username")),
                   passwordInput("passwd", placeholder="Password", label = tagList(icon("unlock-alt"), "Password")),
                   br(),
                   div(
                     style = "text-align: center;",
                     actionButton("login", "SIGN IN", style = "color: white; background-color:#3c8dbc;
                                 padding: 10px 15px; width: 150px; cursor: pointer;
                                 font-size: 18px; font-weight: 600;"),
                     shinyjs::hidden(
                       div(id = "nomatch",
                           tags$p("Oops! Incorrect username or password!",
                                  style = "color: red; font-weight: 600; 
                                            padding-top: 5px;font-size:16px;", 
                                  class = "text-center"))),
                     br(),
                     br(),
                     tags$code("Username: DBAdmin  Password: DBAdmin2019"),
                     br(),
                     tags$code("Username: Passenger  Password: Passenger2019")
                   ))
)

credentials = data.frame(
  username_id = c("DBAdmin", "Passenger"),
  passod   = sapply(c("DBAdmin2019", "Passenger2019"),password_store),
  permission  = c("advanced", "basic"), 
  stringsAsFactors = F
)


# UI ----------------------------------------------------
# Dashboard header
header <- dashboardHeader(
  tags$li(class = "dropdown",
          tags$style(".main-header {height: 0px}"),
          tags$style(".main-header .logo {height: 0px}"),
          tags$style(
            HTML(".shiny-notification {
             position:fixed;
             top: calc(10%);
             left: calc(21%);
             }
             "
            )), 
          tags$head(tags$style(HTML('
                                    .skin-blue .main-header .logo {
                                    background-color: #222D32;
                                    }
                                    .skin-blue .main-header .logo:hover {
                                    background-color: #222D32;
                                    }
                                    ')),
                    tags$style(type="text/css",
                               ".shiny-output-error { visibility: hidden; }",
                               ".shiny-output-error:before { visibility: hidden; }")
          )
  ),
  title = HTML(
    "<div style = 'background-color:#222D32; vertical-align:middle, height = 00px'>
    <img src = 'spirit2.png' align = 'centre', height = '00px'> 
    </div>"),
  titleWidth = "100%")

# Dashboard sidebar
sidebar <- dashboardSidebar(tags$style(".left-side, .main-sidebar {padding-top: 0px}"),uiOutput("sidebarpanel"),uiOutput("Sidebar_Options")) 


#Dashboard Boday 
body <- dashboardBody(shinyjs::useShinyjs(), uiOutput("body"))

# UI
ui <- dashboardPage(header, sidebar, body,
                    skin = "blue")


# Server ----------------------------------------------------
server <- function(input, output, session) {
  # Matching credentials and logging in  
  login = FALSE
  USER <- reactiveValues(login = login)
  
  observe({ 
    if (USER$login == FALSE) {
      if (!is.null(input$login)) {
        if (input$login > 0) {
          Username <- isolate(input$userName)
          Password <- isolate(input$passwd)
          if(length(which(credentials$username_id==Username))==1) { 
            pasmatch  <- credentials["passod"][which(credentials$username_id==Username),]
            pasverify <- password_verify(pasmatch, Password)
            if(pasverify) {
              USER$login <- TRUE
            } else {
              shinyjs::toggle(id = "nomatch", anim = TRUE, time = 1, animType = "fade")
              shinyjs::delay(3000, shinyjs::toggle(id = "nomatch", anim = TRUE, time = 1, animType = "fade"))
            }
          } else {
            shinyjs::toggle(id = "nomatch", anim = TRUE, time = 1, animType = "fade")
            shinyjs::delay(3000, shinyjs::toggle(id = "nomatch", anim = TRUE, time = 1, animType = "fade"))
          }
        } 
      }
    }    
  })
  
  # Logout button
  output$logoutbtn <- renderUI({
    req(USER$login)
    tags$li(a(icon("fa fa-sign-out"), "Logout", 
              href="javascript:window.location.reload(false)"),
            class = "dropdown", 
            style = "background-color: #222D32 !important; border: 0;
                    font-weight: bold; margin:5px; padding: 10px;")
  })
  
  
  ###### Rendering the sidebar ######
  output$sidebarpanel <- renderUI({
    if (USER$login == TRUE ){ 
      if (credentials[,"permission"][which(credentials$username_id==input$userName)]=="advanced") {
        sidebarMenu(id = "tab",
                    uiOutput("logoutbtn"),
                    menuItem("Query", tabName="Query", icon=icon("fas fa-search"),
                             menuSubItem("Single Table Query",
                                         tabName = "singleQuery", icon=icon("fas fa-table")),
                             menuSubItem("Passenger Info",
                                         tabName = "PassInfo", icon=icon("fas fa-user-friends")),
                             menuSubItem("Route Info", 
                                         tabName = "RouteInfo", icon=icon("fas fa-globe-americas")),
                             menuSubItem("Aircraft Info",
                                         tabName = "AircraftInfo", icon=icon("fas fa-plane-departure"))),
                    menuItem("Edit", icon=icon("fas fa-pencil-alt"), tabName="Edit",
                             menuSubItem("Flight",
                                         tabName = "flight_edit", icon=icon("fas fa-fighter-jet")),
                             menuSubItem("Passenger",
                                         tabName = "pass_edit", icon=icon("fas fa-user-friends")),
                             menuSubItem("Ticket",
                                         tabName = "tick_edit",icon=icon("fas fa-ticket-alt")),
                             menuSubItem("Membership Level",
                                         tabName = "memLev_edit", icon=icon("fas fa-layer-group"))
                    ),
                    menuItem("Visualize", icon=icon("fas fa-chart-bar"), tabName="Visualize",
                             badgeLabel="new", badgeColor="light-blue"))
      }
      else{
        sidebarMenu(id = "tab",
                    uiOutput("logoutbtn"),
                    menuItem("Query", tabName="Query", icon=icon("fas fa-search"),
                             menuSubItem("Look up Reservation",
                                         tabName = "passResQuery"),
                             menuSubItem("Look up Flights",
                                         tabName = "passFlightQuery")),
                    menuItem("Purchase", icon=icon("plane"), tabName="Purchase",
                             menuSubItem("New Customer",
                                         tabName = "purchFlightNew"),
                             menuSubItem("Existing Customer",
                                         tabName = "purchFlightExist")))
      }
    }
  })
  
  ###### Redering the body for each tab ######
  output$body <- renderUI({
    if (USER$login == TRUE ) {
      tabItems(
        tabItem(tabName = "singleQuery",
                fluidRow(
                  column(12,box(title="Results" , width = 12, 
                                div(style = 'height:600px; overflow-y: scroll;overflow-x: scroll;', DT::dataTableOutput('DBA_SingleRead')), offset = 0, style='padding:0px;')
                  ))
                
        ),
        tabItem(tabName = "PassInfo",
                fluidRow(
                  column(12,box(title="Results" , width = 12, 
                                div(style = 'height:600px; overflow-y: scroll;overflow-x: scroll;', DT::dataTableOutput('PassInfomation')), offset = 0, style='padding:0px;')
                  ))
                
        ),
        tabItem(tabName = "RouteInfo",
                fluidRow(
                  column(12,box(title="Results" , width = 12, 
                                div(style = 'height:600px; overflow-y: scroll;overflow-x: scroll;', DT::dataTableOutput('RouteInfomation')), offset = 0, style='padding:0px;')
                  ))
                
        ),
        tabItem(tabName = "AircraftInfo",
                fluidRow(
                  column(12,box(title="Results" , width = 12, 
                                div(style = 'height:600px; overflow-y: scroll;overflow-x: scroll;', DT::dataTableOutput('AircraftInfomation')), offset = 0, style='padding:0px;')
                  ))
                
        ),
        
        tabItem(tabName = "passResQuery",
                fluidRow(
                  column(12,box(title="" , width = 12, 
                                div(style = 'height:600px; overflow-y: scroll;overflow-x: scroll;', DT::dataTableOutput('passReservation')), offset = 0, style='padding:0px;')
                  ))),
        tabItem(tabName = "passFlightQuery",
                fluidRow(
                  column(12,box(title="Flights" , width = 12, 
                                div(style = 'height:600px; overflow-y: scroll;overflow-x: scroll;', DT::dataTableOutput('passFlightSearch')), offset = 0, style='padding:0px;')
                  ))
                
        ),
        tabItem(tabName = "purchFlightNew",
                fluidRow(
                  column(12,box(title="" , width = 12, 
                                div(style = 'height:1000px; overflow-y: scroll;overflow-x: scroll;', DT::dataTableOutput('passDetails')), offset = 0, style='padding:0px;')
                  ))
                
        ),
        tabItem(tabName = "purchFlightExist",
                fluidRow(
                  column(12,box(title="" , width = 12, 
                                div(style = 'height:600px; overflow-y: scroll;overflow-x: scroll;', DT::dataTableOutput('passExistDetails')), offset = 0, style='padding:0px;')
                  ))),
        tabItem(tabName = "memLev_edit",
                fluidRow(
                  column(12,box(title="" , width = 12, 
                                div(style = 'height:600px; overflow-y: scroll;overflow-x: scroll;', DT::dataTableOutput('EditMemberTable')), offset = 0, style='padding:0px;')
                  ))),
        tabItem(tabName = "flight_edit",
                fluidRow(
                  column(12,box(title="" , width = 12, 
                                div(style = 'height:600px; overflow-y: scroll;overflow-x: scroll;', DT::dataTableOutput('EditFlightTable')), offset = 0, style='padding:0px;')
                  ))),
        tabItem(tabName = "tick_edit",
                fluidRow(
                  column(12,box(title="" , width = 12, 
                                div(style = 'height:600px; overflow-y: scroll;overflow-x: scroll;', DT::dataTableOutput('EditTickTable')), offset = 0, style='padding:0px;')
                  ))),
        tabItem(tabName = "pass_edit",
                fluidRow(
                  column(12,box(title="" , width = 12, 
                                div(style = 'height:600px; overflow-y: scroll;overflow-x: scroll;', DT::dataTableOutput('EditPassTable')), offset = 0, style='padding:0px;')
                  ))),
        tabItem(tabName = "Visualize",
                fluidRow(
                  valueBoxOutput("NumCust"),
                  valueBoxOutput("TotalRev"),
                  valueBoxOutput("TotalTicket")
                ),
                fluidRow(
                  box(
                    title = "Timeseries of Flights"
                    ,status = "primary"
                    ,solidHeader = TRUE 
                    ,collapsible = TRUE 
                    ,plotOutput("FlightTimeseries", height = "250px")
                  )
                  ,box(
                    title = "Tickets Sold/Customers by Month"
                    ,status = "primary"
                    ,solidHeader = TRUE 
                    ,collapsible = TRUE 
                    ,plotOutput("TicketTimeseries", height = "250px")
                  )
                ),
                fluidRow(
                  box(
                    title = "Timeseries of Revenue"
                    ,status = "primary"
                    ,solidHeader = TRUE 
                    ,collapsible = TRUE,
                    width = 12
                    ,plotOutput("RevenueTimeseries", height = "200px")
                  )
                )))
    }
    else {
      loginpage
    }
  })
  
  ###### Setting up the sidebar options for each tab ######
  output$Sidebar_Options <- renderUI({
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    if (length(input$tab) == 0) {
      dyn_ui <- list()
    } else if (input$tab == "singleQuery") {
      dyn_ui <- list(
        selectInput(inputId="tableName",
                    label="Select table to query:",
                    choices=c(dbListTables(conn)), multiple = FALSE),
        uiOutput('columns'),
        uiOutput('columnsFilter'),
        uiOutput('column1Filter'),
        uiOutput('rows')
      )} else if (input$tab == "passResQuery"){
        dyn_ui <- list(
          textInput("resNum", "Reservation Number"))
      } else if (input$tab == "passFlightQuery"){
        dyn_ui <- list(
          selectInput('depCityVal', 'Select Departure City', c("All",dbGetQuery(conn,"SELECT airportCity from route r INNER JOIN airport a1 ON r.arrivalIata = a1.codeIataAirport
       UNION
SELECT airportCity from route r INNER JOIN airport a2 ON r.departureIata = a2.codeIataAirport;")),multiple=FALSE),
          selectInput('arrCityVal', 'Select Arrival City', c("All",dbGetQuery(conn,"SELECT airportCity from route r INNER JOIN airport a1 ON r.arrivalIata = a1.codeIataAirport
UNION
SELECT airportCity from route r INNER JOIN airport a2 ON r.departureIata = a2.codeIataAirport;")),multiple=FALSE))
      } else if (input$tab == "purchFlightNew" ) {
        dyn_ui <- list(
          actionButton("go_PassFlight", "Purchase", icon("plane"), 
                       style="color: #fff; background-color: #337ab7; border-color: #2e6da4"),
          selectInput("FlightNum", "Flight Number", c(dbGetQuery(conn,"SELECT flightNumber from
                                                                    flight")),multiple=FALSE),
          textInput("FirstName", "First Name"),
          textInput("LastName", "Last Name"),
          dateInput("DOB", "Date of Birth", 
                    value = "1995-01-01"),
          textInput("email", "Email"),
          numericInput("telNo", "Telephone Number",1),
          selectInput("CountryName", "Country", c(dbGetQuery(conn,"SELECT countryName from
                                                                    country")),multiple=FALSE),
          textInput("StreetAddress", "Street Address"),
          textInput("City", "City"),
          textInput("Postcode", "Postcode"),
          textInput("State", "State"))
      }  else if (input$tab == "purchFlightExist" ) {
        dyn_ui <- list(
          actionButton("go_PassFlightExists", "Purchase", icon("plane"), 
                       style="color: #fff; background-color: #337ab7; border-color: #2e6da4"),
          selectInput("FlightNumExist", "Flight Number", c(dbGetQuery(conn,"SELECT flightNumber from
                                                                    flight")),multiple=FALSE),
          textInput("emailExist", "Email"))
      } else if (input$tab == "insert" ) {
        dyn_ui <- list(
          selectInput(inputId="tableName",
                      label="Select table to query:",
                      choices=c(dbListTables(conn)), multiple = FALSE))
      } else if (input$tab == "flight_edit") {
        dyn_ui <- list(actionButton("go_EditFlight", "Go", icon = icon("fas fa-mouse-pointer"), 
                                    style="color: #fff; background-color: #337ab7; border-color: #2e6da4"),
                       radioButtons("f_edit_type", "Edit type:",
                                    c("Insert" = "f_ins",
                                      "Update" = "f_up",
                                      "Delete" = "f_Delete")),
                       uiOutput('edit_Flight'))
      } else if (input$tab == "pass_edit") {
        dyn_ui <- list(actionButton("go_EditPass", "Go", icon = icon("fas fa-mouse-pointer"), 
                                    style="color: #fff; background-color: #337ab7; border-color: #2e6da4"),
                       radioButtons("p_edit_type", "Edit type:",
                                    c("Insert" = "p_ins",
                                      "Update" = "p_up",
                                      "Delete" = "p_Delete")),
                       uiOutput('edit_Pass'))
      } else if (input$tab == "tick_edit") {
        dyn_ui <- list(actionButton("go_EditTick", "Go", icon = icon("fas fa-mouse-pointer"), 
                                    style="color: #fff; background-color: #337ab7; border-color: #2e6da4"),
                       radioButtons("t_edit_type", "Edit type:",
                                    c("Insert" = "t_ins",
                                      "Update" = "t_up",
                                      "Delete" = "t_Delete")),
                       uiOutput('edit_Tick'))
      } else if (input$tab == "memLev_edit") {
        dyn_ui <- list(actionButton("go_EditMember", "Go", icon = icon("fas fa-mouse-pointer"), 
                                    style="color: #fff; background-color: #337ab7; border-color: #2e6da4"),
                       radioButtons("m_edit_type", "Edit type:",
                                    c("Insert" = "m_ins",
                                      "Update" = "m_up")),
                       uiOutput('edit_memLev'))
      } else if (input$tab == "Visualize") {
        dyn_ui <- list(actionButton("go_Refresh", "Refresh Visualization", icon = icon("fas fa-refresh"), 
                                    style="color: #fff; background-color: #337ab7; border-color: #2e6da4"))
      } else if (input$tab == "PredefinedQuery") {
        dyn_ui <- list(actionButton("passInfo", "Passenger Information", icon = icon("fas fa-user-friends")),
                       actionButton("routeInfo", "Route Information", icon = icon("fas fa-globe-americas")),
                       actionButton("aircraftInfo", "Aircraft Information", icon = icon("fas fa-plane-departure"))) 
      }else {
        dyn_ui <- list()
      }
    return(dyn_ui)})
  
  
  # Get list of tables available in the database for the DBA
  output$columns = renderUI({
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    selectInput('columnName', 'Select Columns', c(dbListFields(conn,input$tableName)),multiple=TRUE)
  })
  
  # Get list of fields available for the table the DBA has selected so they can filter 
  
  output$columnsFilter = renderUI({
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    selectInput('columnFilterName', 'Select column to filter on', c("No filter",dbListFields(conn,input$tableName)),multiple=FALSE)
  })
  
  # Based on field DBA chooses, create a input field based on the datatype
  output$column1Filter = renderUI({
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    if (is.null(input$columnFilterName) || input$columnFilterName == "No filter") {
      
    } else { 
      dataType_1 = dbGetQuery(conn, paste0(
        "SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '",
        input$tableName, "' AND COLUMN_NAME = '",input$columnFilterName,"' ;"))
      if (dataType_1[1,1] == "varchar"){
        textInput("filterval1", paste0("Filter ",input$columnFilterName," on:"))
      } else if (dataType_1[1,1] == "date"){
        dateInput("filterval1", paste0("Filter ",input$columnFilterName," on:"),
                  value = "2019-08-29")
      } else if (dataType_1[1,1] == "int") {
        numericInput("filterval1",paste0("Filter ",input$columnFilterName," on:"),1)
      } else if (dataType_1[1,1] == "time") {
        timeInput("filterval1", paste0("Filter ",input$columnFilterName," on:"))
      } else (
        print(dataType_1[1,1])
      )
    }   
  })
  
  # Getting the number of rows in the table so the DBA can filter on it 
  output$rows = renderUI({
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    rowNumber =  dbGetQuery(conn, paste0(
      "SELECT COUNT(*) FROM ",input$tableName,";"))
    rowNumber_int = rowNumber[[1]]
    sliderInput(inputId="nrows",
                label="Enter the number of rows to display:",
                min=1,
                max=rowNumber_int,
                value=3)})
  
  ### Edit Tables ###
  
  shinyjs::runjs("$('#inputdepTerm').attr('maxlength', 1)")
  
  # Flight table edit user inputs
  output$edit_Flight = renderUI({
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    if (input$f_edit_type == "f_ins" ||input$f_edit_type == "f_up"  ){
      list(
        if(input$f_edit_type == "f_up") {
          selectInput('flightNum', "Flight Number to Update", c(dbGetQuery(conn,"SELECT flightNumber from
                                                                    flight")),multiple=FALSE)},
        textInput("depTerm", "Departure Terminal"),
        timeInput("depTime", "Departure Time"),
        timeInput("arrTime", "Arrive Time"),
        dateInput("flight_date", "Flight Date", 
                  value = "1995-01-01"),
        selectInput('aircraft_Reg', "Aircraft Registration Number", c(dbGetQuery(conn,"SELECT aircraftRegNo from
                                                                    aircraft")),multiple=FALSE),
        selectInput('route_id', "Route ID", c(dbGetQuery(conn,"SELECT route_id from
                                                                    route")),multiple=FALSE))
    } else {
      selectInput('flightNum', "Flight Number to Delete", c(dbGetQuery(conn,"SELECT flightNumber from
                                                                    flight")),multiple=FALSE)}
  })    
   
  # Passenger table edit user inputs 
  output$edit_Pass = renderUI({
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    if (input$p_edit_type == "p_ins" ||input$p_edit_type == "p_up"){
      list(
        if(input$p_edit_type == "p_up") {
          selectInput('passID', "Passenger ID to Update", c(dbGetQuery(conn,"SELECT passenger_id from
                                                                    passenger")),multiple=FALSE)},
        textInput("FirstName", "First Name"),
        textInput("LastName", "Last Name"),
        dateInput("DOB", "Date of Birth", 
                  value = "2020-01-01"),
        textInput("email", "Email"),
        numericInput("telNo", "Telephone Number",1),
        selectInput("CountryName", "Country", c(dbGetQuery(conn,"SELECT countryName from
                                                                    country")),multiple=FALSE),
        textInput("StreetAddress", "Street Address"),
        textInput("City", "City"),
        textInput("Postcode", "Postcode"),
        textInput("State", "State"))
    } else {
      selectInput('passID', "Passenger ID to Delete", c(dbGetQuery(conn,"SELECT passenger_id from
                                                                    passenger")),multiple=FALSE)}
  })
  
  # Ticket table edit user inputs
  output$edit_Tick = renderUI({
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    if (input$t_edit_type == "t_ins" ||input$t_edit_type == "t_up"  ){
      list(
        if(input$t_edit_type == "t_up") {
          list(selectInput('resNum', "Reservation ID to Update", c(dbGetQuery(conn,"SELECT reservationID from
                                                                    ticket")),multiple=FALSE),
               numericInput("price", "Ticket Price",40))},
        dateInput("purchDate", "Purchase Date", value = Sys.Date()),
        textInput("seatNo", "Seat Number"),
        selectInput('flight_Num', "Flight Number", c(dbGetQuery(conn,"SELECT flightNumber from
                                                                    flight")),multiple=FALSE),
        selectInput('pass_id', "Passenger ID", c(dbGetQuery(conn,"SELECT passenger_id from
                                                                    passenger")),multiple=FALSE))
    } else {
      selectInput('resNum', "Reservation ID to Delete", c(dbGetQuery(conn,"SELECT reservationID from
                                                                    ticket")),multiple=FALSE)}
  })
  
  
  # Membershiplevel table edit user inputs 
  output$edit_memLev = renderUI({
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    if (input$m_edit_type == "m_ins" ||input$m_edit_type == "m_up"  ){
      list(
        if(input$m_edit_type == "m_up") {
          selectInput('memLevel', "Select Membership Level to Update", c(dbGetQuery(conn,"SELECT memberLevel from
                                                                    membershipLevel")),multiple=FALSE)
        },
        if (input$m_edit_type == "m_ins") {
          textInput("memLevel", "Membership Level Name")
        },
        textInput("levelFeat", "Level Features"),
        numericInput("NumPoints", "Number of Points",10))
    } else {
      }
selectInput('memLevel', "Select Membership Level to  Delete", c(dbGetQuery(conn,"SELECT memberLevel from
                                                                    membershipLevel")),multiple=FALSE)  } )     
  
  
  
  ###### DBA FUNCTIONS ######
  # DBA Read single query
  output$DBA_SingleRead <- DT::renderDataTable({
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    vals <- ifelse(length(input$columnName) == 0, "*",paste(input$columnName, collapse = ","))
    if(input$columnFilterName == "No filter"){
      result = dbGetQuery(conn, paste0(
        "SELECT ", vals," FROM ",input$tableName," LIMIT ", input$nrows, ";"))
      datatable(result, options = list(
        searching = FALSE, paging = FALSE))
    } else {
      result = dbGetQuery(conn, paste0(
        "SELECT ", vals," FROM ",input$tableName, " WHERE ", input$columnFilterName, "= '", 
        input$filterval1, "' LIMIT ", input$nrows, ";"))
      datatable(result, options = list(
        searching = FALSE, paging = FALSE))
    }
  } )
  
  # Insert/Update/Delete Member
  EditMemberQuery <- eventReactive(input$go_EditMember, {
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    if (input$m_edit_type == "m_ins" || input$m_edit_type == "m_up"  ) {
      if (input$memLevel == "" || input$levelFeat == "" ||
          input$NumPoints == "") {
        shiny::showNotification("Please fill in all blanks", type = "error")
        NULL
      }
      if (input$m_edit_type == "m_ins") {
        dbGetQuery(conn,paste0("CALL insert_membership_level('",input$memLevel,"','",input$levelFeat,"','",input$NumPoints,"');"))
      } else if (input$m_edit_type == "m_up" ) {
        dbGetQuery(conn,paste0("CALL update_membership_level('",input$memLevel,"','",input$levelFeat,"','",input$NumPoints,"');"))
      }
    }       
    result = dbGetQuery(conn, "SELECT * from membershipLevel")
    result
  })
  
  output$EditMemberTable <- DT::renderDataTable(rownames = TRUE, colnames = FALSE,{
    if (is.null(EditMemberQuery()) || EditMemberQuery() == ''){
      
    } else {
      datatable(EditMemberQuery(), options = list(
        searching = FALSE, paging = FALSE))
    }
  })
  
  # Insert/Update/Delete Flight
  EditFlightQuery <- eventReactive(input$go_EditFlight, {
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    if (input$f_edit_type == "f_ins" || input$f_edit_type == "f_up"  ) {
      if (input$depTerm == "") {
        shiny::showNotification("Please fill in all blanks", type = "error")
        NULL
      }
      if (input$f_edit_type == "f_ins") {
        dbGetQuery(conn,paste0("CALL insert_flight('",input$depTerm,"','",strftime(input$depTime,format="%H:%M:%S"),"','",strftime(input$arrTime,format="%H:%M:%S"),"','",input$aircraft_Reg,"','",input$route_id,"','",input$flight_date,"');"))
      } else if (input$f_edit_type == "f_up" ) {
        dbGetQuery(conn,paste0("CALL update_flight('",input$flightNum,"','",input$depTerm,"','",strftime(input$depTime,format="%H:%M:%S"),"','",strftime(input$arrTime,format="%H:%M:%S"),"','",input$aircraft_Reg,"','",input$route_id,"','",input$flight_date,"');"))
      }
    } else if (input$f_edit_type == "f_Delete" ) {
      dbGetQuery(conn,paste0("CALL delete_flight('",input$flightNum,"');"))
    } else {
      
    }
    result = dbGetQuery(conn, "SELECT * from flight")
    result
  })
  
  
  output$EditFlightTable <- DT::renderDataTable(rownames = TRUE, colnames = FALSE,{
    if (is.null(EditFlightQuery()) || EditFlightQuery() == ''){
      
    } else {
      datatable(EditFlightQuery(), options = list(
        searching = FALSE, paging = FALSE))
    }
  })
  
  
  # Insert/Update/Delete Ticket
  EditTickQuery <- eventReactive(input$go_EditTick, {
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    if (input$t_edit_type == "t_ins" || input$t_edit_type == "t_up"  ) {
      if (input$seatNo == "") {
        shiny::showNotification("Please fill in all blanks", type = "error")
        NULL
      }
      if (input$t_edit_type == "t_ins") {
        resNumber = stri_rand_strings(1, 7, pattern = "[A-Z0-9]")
        dbGetQuery(conn,paste0("CALL insert_ticket('",resNumber,"','",input$purchDate,"','",input$seatNo,"','",input$flight_Num,"','",input$pass_id,"');"))
      } else if (input$t_edit_type == "t_up" ) {
        dbGetQuery(conn,paste0("CALL update_ticket('",input$resNum,"','",input$purchDate,"','",input$seatNo,"','",input$flight_Num,"','",input$pass_id,"','",input$price,"');"))
      }
    } else if (input$t_edit_type == "t_Delete" ) {
      dbGetQuery(conn,paste0("CALL delete_ticket('",input$resNum,"');"))
    } else {
      
    }
    result = dbGetQuery(conn, "SELECT * from ticket")
    result
  })
  
  
  output$EditTickTable <- DT::renderDataTable(rownames = TRUE, colnames = FALSE,{
    if (is.null(EditTickQuery()) || EditTickQuery() == ''){
      
    } else {
      datatable(EditTickQuery(), options = list(
        searching = FALSE, paging = FALSE))
    }
  })
  
  
  # Insert/Update/Delete Passenger
  EditPassQuery <- eventReactive(input$go_EditPass, {
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    if (input$p_edit_type == "p_ins" || input$p_edit_type == "p_up"  ) {
      if (input$FirstName == "" || input$LastName == "" ||
          input$email == "" ||
          input$StreetAddress == "" ||
          input$City == "" || input$Postcode == "" ||
          input$State == "") {
        shiny::showNotification("Please fill in all blanks", type = "error")
        NULL
      }
      if (input$p_edit_type == "p_ins") {
        dbGetQuery(conn,paste0("CALL insert_passenger('",input$FirstName,"','",input$LastName,"','",input$DOB,"','",input$email,"','",input$telNo,"','",input$StreetAddress,"','",input$City,"','",input$Postcode,"','",input$State,"','",input$CountryName,"');"))
      } else if (input$p_edit_type == "p_up" ) {
        dbGetQuery(conn,paste0("CALL update_passenger('",input$passID,"','",input$FirstName,"','",input$LastName,"','",input$DOB,"','",input$email,"','",input$telNo,"','",input$StreetAddress,"','",input$City,"','",input$Postcode,"','",input$State,"','",input$CountryName,"');"))
      }
    } else if (input$p_edit_type == "p_Delete" ) {
      dbGetQuery(conn,paste0("CALL delete_passenger('",input$passID,"');"))
    } else {
    }
    result = dbGetQuery(conn, "SELECT * from passenger")
    result
  })
  
  
  output$EditPassTable <- DT::renderDataTable(rownames = TRUE, colnames = FALSE,{
    if (is.null(EditPassQuery()) || EditPassQuery() == ''){
      
    } else {
      datatable(EditPassQuery(), options = list(
        searching = FALSE, paging = FALSE))
    }
  })
  
  
  # Predefined query - passenger information
  output$PassInfomation <- DT::renderDataTable(rownames = TRUE, colnames = FALSE,{
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    result = dbGetQuery(conn, "CALL passenger_info()")
    datatable(result, options = list(
      searching = FALSE, paging = FALSE))
  })
  
  
  # Predefined query - route information
  output$RouteInfomation <- DT::renderDataTable(rownames = TRUE, colnames = FALSE,{
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    result = dbGetQuery(conn, "CALL route_info()")
    datatable(result, options = list(
      searching = FALSE, paging = FALSE))
  })
  
  # Predefined query - aircraft information
  output$AircraftInfomation <- DT::renderDataTable(rownames = TRUE, colnames = FALSE,{
    conn <- dbConnect(MySQL(), user=usernameInput, password=passwordInput, 
                      dbname='AirportDB', host='127.0.0.1')
    result = dbGetQuery(conn, "CALL aircraft_info()")
    datatable(result, options = list(
      searching = FALSE, paging = FALSE))
  })
  
  
  
  ###### PASSENGER FUNCTIONS ###### 
  
  # Looking up reservations
  output$passReservation <- DT::renderDataTable(rownames = TRUE, colnames = FALSE,{
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    if (is.null(input$resNum) || input$resNum == ''){
      
    } else {
      result = dbGetQuery(conn, paste0("CALL passenger_user_res('",input$resNum,"');"))
      result_transpose = transpose(result)
      rownames(result_transpose) <- colnames(result)
      colnames(result_transpose) <- "Details"
      datatable(result_transpose, options = list(
        searching = FALSE, paging = FALSE))
    }
  } )
  
  
  # Looking up flights (datatable)
  
  output$passFlightSearch <- DT::renderDataTable(rownames = TRUE, colnames = FALSE,{
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    if (is.null(input$depCityVal) || is.null(input$arrCityVal))
    {
      
    } else if (input$depCityVal == "All" && input$arrCityVal == "All") {
      result = dbGetQuery(conn, paste0("CALL find_destination_all();"))
      datatable(result, options = list(
        searching = FALSE, paging = FALSE))
    } else if (input$depCityVal == "All") {
      result = dbGetQuery(conn, paste0("CALL find_destination_destination('",input$arrCityVal,"');"))
      datatable(result, options = list(
        searching = FALSE, paging = FALSE))
    } else if (input$arrCityVal == "All"){
      result = dbGetQuery(conn, paste0("CALL find_destination_origin('",input$depCityVal,"');"))
      datatable(result, options = list(
        searching = FALSE, paging = FALSE))
    } else if (input$depCityVal != "All" && input$arrCityVal != "All") {
      result = dbGetQuery(conn, paste0("CALL find_destination('",input$depCityVal,"','",input$arrCityVal,"');"))
      datatable(result, options = list(
        searching = FALSE, paging = FALSE))
    } else {
    }
  } )
   
  # Inserting passenger details function
  passDetailsInsert <- eventReactive(input$go_PassFlight, {
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    allEmails = dbGetQuery(conn, "SELECT email from passenger")
    if (input$FirstName == "" || input$LastName == "" ||
        input$email == "" ||
        input$StreetAddress == "" ||
        input$City == "" || input$Postcode == "" ||
        input$State == "") {
      shiny::showNotification("Please fill in all blanks", type = "error")
      NULL
    } else if (isValidEmail(input$email) == FALSE){
      shiny::showNotification("Please Input a valid E-mail address", type = "error")
    } else if (input$email %in% allEmails$email== TRUE){
      shiny::showNotification("Passenger already exists with this email", type = "error")
    } else {
      dbGetQuery(conn,paste0("CALL insert_passenger('",input$FirstName,"','",input$LastName,"','",input$DOB,
                             "','",input$email,"','",input$telNo,"','",input$StreetAddress,"','",input$City
                             ,"','",input$Postcode,"','",input$State,"','",input$CountryName,"');"))
      resNumber = stri_rand_strings(1, 7, pattern = "[A-Z0-9]")
      seatNumber = paste(round(runif(1,1,30)), stri_rand_strings(1, 1, pattern = "[A-F]"), sep = "")
      dbGetQuery(conn,paste0("CALL passenger_purchase_ticket('",input$FlightNum,"','",resNumber,"','",input$email,
                             "','",seatNumber,"');"))
      result = dbGetQuery(conn, paste0("CALL passenger_user_res('",resNumber,"');"))
      result_transpose = transpose(result)
      rownames(result_transpose) <- colnames(result)
      colnames(result_transpose) <- "Details"
      result_transpose
    }
  })    
  
  
  # Rendering data table based on the details inserted by the new passenger
  output$passDetails <- DT::renderDataTable(rownames = TRUE, colnames = FALSE,{
    if (is.null(passDetailsInsert()) || passDetailsInsert() == ''){
      
    } else {
      datatable(passDetailsInsert(), options = list(
        searching = FALSE, paging = FALSE))
    }
  })
  
  
  # Inserting into the ticket table if passenger exists
  passExistTicketInsert <- eventReactive(input$go_PassFlightExists, {
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    resNumber = stri_rand_strings(1, 7, pattern = "[A-Z0-9]")
    seatNumber = paste(round(runif(1,1,30)), stri_rand_strings(1, 1, pattern = "[A-F]"), sep = "")
    
    res <- tryCatch({
      dbSendQuery(conn,paste0("CALL passenger_purchase_ticket('",input$FlightNumExist,"','",resNumber,"','",input$emailExist,"','",seatNumber,"');"))
    },
    error = function(e) NULL
    )
    if (is.null(res)){
      shiny::showNotification("You have not been registered as a existing customer, please choose the New Customer tab", type = "error")
      NULL
    } else {
      result = dbGetQuery(conn, paste0("CALL passenger_user_res('",resNumber,"');"))
      result_transpose = transpose(result)
      rownames(result_transpose) <- colnames(result)
      colnames(result_transpose) <- "Details"
      result_transpose
    }
  })
  
  
  # Rendering datatable based on flight number and passenger details 
  output$passExistDetails <- DT::renderDataTable(rownames = TRUE, colnames = FALSE,{
    if (is.null(passExistTicketInsert()) || passExistTicketInsert() == ''){
      
    } else {
      datatable(passExistTicketInsert(), options = list(
        searching = FALSE, paging = FALSE))
    }
  })
  
  
  # Functions to check validity of email
  isValidEmail <- function(x) {
    grepl("\\<[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\>", as.character(x), 
          ignore.case=TRUE)
  }
  
  
  # Visualization Functions  ----------------------------------------------------
  
  # Getting the number of flights per day
  timeseriesFlight_fn <- function (){
    sql = "call timeseries_flights();"
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    res = dbSendQuery(conn, sql)
    timeseriesFlight = fetch(res,n=-1)
    while(dbMoreResults(conn) == TRUE) {
      dbNextResult(conn)
    }
    dbClearResult(dbListResults(conn)[[1]])
    return(timeseriesFlight)
  }
  
  
  # Getting number of tickets, customer, and revenue by month
  TicketMonthly_Timeseries_fn <- function () {
    sql = "call monthly_timeseries();"
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    res = dbSendQuery(conn, sql)
    TicketMonthly_Timeseries = fetch(res,n=-1)
    while(dbMoreResults(conn) == TRUE) {
      dbNextResult(conn)
    }
    dbClearResult(dbListResults(conn)[[1]])
    return(TicketMonthly_Timeseries)
  }
  
  # Getting the total number of customers
  TotalCust_fn <- function () {
    sql = "call total_customers();"
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    res = dbSendQuery(conn, sql)
    TotalCust = fetch(res,n=-1)
    while(dbMoreResults(conn) == TRUE) {
      dbNextResult(conn)
    }
    dbClearResult(dbListResults(conn)[[1]])
    return(TotalCust)
  }
  
  # Getting the total revenue 
  TotalRev_fn <- function () {
    sql = "call total_revenue();"
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    res = dbSendQuery(conn, sql)
    TotalRev = fetch(res,n=-1)
    while(dbMoreResults(conn) == TRUE) {
      dbNextResult(conn)
    }
    dbClearResult(dbListResults(conn)[[1]])
    return(TotalRev)
  }
  
  # Getting the total tickets sold
  TotalTicket_fn <- function () {
    sql = "call total_tickets();"
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    res = dbSendQuery(conn, sql)
    TotalTicket = fetch(res,n=-1)
    while(dbMoreResults(conn) == TRUE) {
      dbNextResult(conn)
    }
    dbClearResult(dbListResults(conn)[[1]])
    return(TotalTicket)
  }
  
  ###### VISUALIZATION FUNCTIONS ###### 
  
  # Visualization Functions  ----------------------------------------------------
  
  # Getting the number of flights per day
  timeseriesFlight_fn <- function (){
    sql = "call timeseries_flights();"
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    res = dbSendQuery(conn, sql)
    timeseriesFlight = fetch(res,n=-1)
    while(dbMoreResults(conn) == TRUE) {
      dbNextResult(conn)
    }
    dbClearResult(dbListResults(conn)[[1]])
    return(timeseriesFlight)
  }
  
  
  # Getting number of tickets, customer, and revenue by month
  TicketMonthly_Timeseries_fn <- function () {
    sql = "call monthly_timeseries();"
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    res = dbSendQuery(conn, sql)
    TicketMonthly_Timeseries = fetch(res,n=-1)
    while(dbMoreResults(conn) == TRUE) {
      dbNextResult(conn)
    }
    dbClearResult(dbListResults(conn)[[1]])
    return(TicketMonthly_Timeseries)
  }
  
  # Getting the total number of customers
  TotalCust_fn <- function () {
    sql = "call total_customers();"
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    res = dbSendQuery(conn, sql)
    TotalCust = fetch(res,n=-1)
    while(dbMoreResults(conn) == TRUE) {
      dbNextResult(conn)
    }
    dbClearResult(dbListResults(conn)[[1]])
    return(TotalCust)
  }
  
  # Getting the total revenue 
  TotalRev_fn <- function () {
    sql = "call total_revenue();"
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    res = dbSendQuery(conn, sql)
    TotalRev = fetch(res,n=-1)
    while(dbMoreResults(conn) == TRUE) {
      dbNextResult(conn)
    }
    dbClearResult(dbListResults(conn)[[1]])
    return(TotalRev)
  } 
  
  # Getting the total tickets sold
  TotalTicket_fn <- function () {
    sql = "call total_tickets();"
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))
    res = dbSendQuery(conn, sql)
    TotalTicket = fetch(res,n=-1)
    while(dbMoreResults(conn) == TRUE) {
      dbNextResult(conn)
    }
    dbClearResult(dbListResults(conn)[[1]])
    return(TotalTicket)
  }
  
  # Total Customers
  TotalCustRefresh <- eventReactive(input$go_Refresh, {
    TotalCust_fn()[1,1]
  })
  
  output$NumCust <- renderValueBox({
    valueBox(
      formatC(TotalCustRefresh(), format="d", big.mark=','),
      'Total Number of Customers'
      ,icon = icon("stats",lib='glyphicon')
      ,color = "purple")
  })
  
  # Total Revenue
  RevRefresh <- eventReactive(input$go_Refresh, {
    TotalRev_fn()[1,1]
  })
  
  output$TotalRev <- renderValueBox({
    valueBox(
      formatC(RevRefresh(), format="d", big.mark=',')
      ,'Total Revenue'
      ,icon = icon("usd",lib='glyphicon')
      ,color = "green")
  })
  
  # Total Tickets
  TickRefresh <- eventReactive(input$go_Refresh, {
    TotalTicket_fn()[1,1]
  })
  
  
  output$TotalTicket <- renderValueBox({
    valueBox(
      formatC(TickRefresh(), format="d", big.mark=',')
      ,'Total Tickets Sold'
      ,icon = icon('fa fa-ticket-alt') 
      ,color = "yellow")
  })
  
  # Flight timeseries
  FlightRefresh <- eventReactive(input$go_Refresh, {
    timeseriesFlight_fn()
  })
  
  output$FlightTimeseries <- renderPlot({
    timeseriesFlight = FlightRefresh()
    timeseriesFlight$flightDate <- as.Date(timeseriesFlight$flightDate , "%Y-%m-%d")
    ggplot(data = timeseriesFlight, aes(x = flightDate, y = `Number of Flights`)) +
      geom_bar(stat="identity", fill="steelblue")+
      theme_minimal()
  })
  
  # Tickets and customers by Month
  TickTimeSeriesRefresh <- eventReactive(input$go_Refresh, {
    TicketMonthly_Timeseries_fn()
  })
  
  output$TicketTimeseries <- renderPlot({
    timeseriesTicket = TickTimeSeriesRefresh()
    timeseriesTicket$PurchDate <- as.Date(paste(paste(timeseriesTicket$Year, timeseriesTicket$Month, sep = "-"),"-01",sep=""))
    timeseriesTicket = timeseriesTicket[,c("PurchDate","Number of Tickets","Number of Customers")]
    timeseriesTicket.melt<-melt(timeseriesTicket,id.vars="PurchDate")
    ggplot(data = timeseriesTicket.melt, aes(x=PurchDate, y=value, fill=variable)) +
      geom_bar(stat='identity', position='dodge')+
      theme_minimal()
  })
  
  # Revenue by Month
  output$RevenueTimeseries <- renderPlot({
    timeseriesRevenue = TickTimeSeriesRefresh()
    timeseriesRevenue$PurchDate <- as.Date(paste(paste(timeseriesRevenue$Year, timeseriesRevenue$Month, sep = "-"),"-01",sep=""))
    ggplot(data=timeseriesRevenue, aes(x=PurchDate, y=Revenue, group=1)) +
      geom_line(size=1.2)+
      geom_point()+
      theme_minimal()
  }) 
  
  ###### CLOSING CONNECTIONS ON EXIT ###### 
  session$onSessionEnded(function() {
    lapply(dbListConnections(MySQL()), dbDisconnect)
  })
}   

shinyApp(ui, server)




