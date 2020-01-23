# Spirit-Airlines-Database
Created by: Alan Xiao, Dillshini Hettige, Jacqueline Allex

Hello! Welcome to our Airport Database, providing information and functionality about the aviation industry, primarily data from Spirit Airlines. There are 2 users: the customer and the DBA. The customer can view flights and purchase tickets, while the DBA has full control: they can perform CRUD operations as well as visualize the data in insightful ways. Frontend is written in R-Shiny, backend is written in MySQL.


Please follow the steps below to ensure our Airport App works sufficiently on your computer:


Section 1 - Import the database


1. Download and set up MySQL workbench.
        - https://www.mysql.com/products/workbench/
        
        
2. Download the AiportDB_Dump in AirportDB_Dump folder and import this in your MySQL workbench.


3. If for some reason, it throws an error, download the following files and run:
        - AirportDB_Create = All the create statements for the tables
        - Import the CSV files in the following order: country, aircraft, airport, route,
        flight, passenger, ticket, membershiplevel, loyaltylevel
        - Run the scripts that contain the procedures and triggers: Passenger_Procedures,
        DBA_Procedures, DBA_PredefinedJoins, Procedures_Visualization


Section 2 - Running the front end 
1. Download R
        - Windows: https://cran.r-project.org/bin/windows/base/
        - Mac: https://cran.r-project.org/bin/macosx/


2. Download R Studio
        - https://cran.r-project.org/bin/windows/base/


3: Download the frontend files and save it in the same folder
        - AirportApp.R

4: Open R Studio and open the AirportApp.R file 


5. Click Run App (top right hand corner of the editor)
        - Enter your database username, password and hostname that contains the AiportDB database you imported in Section 1


6. Once you enter the details successfully, it will say Database connection is successful and run the app
        - All the packages and libraries will be automatically installed. As a result, the first run of the app may take a while.
