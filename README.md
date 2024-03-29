# YDBAdminOpsGUI

The YottaDB Administration GUI is a browser based application that is intended to manage and explore YottaDB. Currently, it consists of different web modules that fall into different categories.

 - **System  Management**
    1. Running Processes
    2. Global Directory Editor
 - **System Explorer**
    1. Routines Explorer
    2. Globals Explorer
    3. Octo SQL Tables explorer

## Manual Setup for Development
The GUI is compromised of two parts. 
 1. **The backend**: written in M
 2. **The fontend**: written in VueJs

### Development dependencies (Nodejs and npm are only used in development)
**Node.js** and **npm** (to compile javascript files)
```bash
sudo apt update
sudo apt install nodejs npm
```


#### Running the app in development mode
- Git clone the project in any working directory. 
```bash
git clone https://gitlab.com/YottaDB/UI/YDBAdminOpsGUI.git
```

- Change dirctory
```bash
cd YDBAdminOpsGUI
```

##### Server
- Point your ydb_routines environment  to the routines folder. You can replace $PWD/routines with any other path that points to the routines folder. 
```bash
export ydb_routines=`$ydb_dist/yottadb -run %XCMD 'W $P($P($ZRO,"(",1,2),")")_" "_"$PWD/routines"_")"_$P($ZRO,")",2,$L($ZRO,")"))'` 
```
- Start the integrated web server. 
By default the web server listens on port 8089. This can be changed by passing the ```Start``` label a port number, and modifying the proxy section of ```quasar.conf.js``` file 
```bash
$ydb_dist/yottadb -run Start^%YDBWEB
```

##### Client
- Download the nodejs dev dependencies.
```bash 
npm install
```
- Run the front-end development server
```bash
npm run dev
```
- Navigate to http://localhost:8080. If port 8080 is unavailable, the closest available port will be selected.


#### Running the app in production mode.
- Make sure you build the application
 ```bash
 npm run build
 ```
- Start the web server using default port (8089)
```bash
$ydb_dist/yottadb -run Start^%YDBWEB
```
- Or provide a specific port (7777 for example)
```bash
$ydb_dist/yottadb -run Start^%YDBWEB(7777)
```
- Point your browser to the running application
```bash
http://localhost:8089
```
##### Notes
- ydb_routines variable needs to be set correctly to point to the routines of the application. You can either move the routines manually to a location specified in ydb_routines, 
or you can modify ydb_routines before YottaDB process start up

```bash
export ydb_routines=`$ydb_dist/yottadb -run %XCMD 'W $P($P($ZRO,"(",1,2),")")_" "_"$PWD/routines"_")"_$P($ZRO,")",2,$L($ZRO,")"))'` 
```
- The instance of the web server has to be started from the project root folder, where the folder ./dist/spa/ contains the project's built files. 

#### Testing
 - Testing the app requires the project files to be built first
 - The testing framework assumes the server is running on port 8089. The port is specified in tests/bootstap.js
 - The tests run by default in headless mode (no browser running in the foreground). The setting is also in tests/bootstap.js
 - to run the tests:
 ```bash
 $ydb_dist/yottadb -run Start^%YDBWEB
 npm test
 ```

 #### Application Commands
 - dev: Run the application in development mode on port 8080 where the client files will be served from.
 ```bash
 npm run dev
 ```
 - build: Builds the applicatio in dist folder
 ```bash
 npm run build
 ``` 
 - test: Run end-to-end tests
 ```bash
 npm test
 ```
- clean: Clean all build artifacts
```bash
npm run clean
```
- lint: Lint application code according to eslint-prettier preset
```bash
npm run lint
```
