#
# App Globals
#

kc         = KD.getSingleton "kiteController"
fc         = KD.getSingleton "finderController"
tc         = fc.treeController
#gets current user's nickname
{nickname} = KD.whoami().profile
#a special place to
appStorage = new AppStorage "zf2-installer", "1.0"

#
# App Functions
#

###
Get response and display, if has error colorize

@var res
@var err=
###
parseOutput = (res, err = no)->
    res = "<br><cite style='color:red'>[ERROR] #{res}</cite><br><br><br>" if err
    {output} = split
    output.setPartial res
    output.utils.wait 100, ->
        output.scrollTo
            top      : output.getScrollHeight()
            duration : 100

###
Creates mysqldb instance at backend

@var callback function
###
prepareDb = (callback)->

    parseOutput "<br>creating a database....<br>"
    kc.run
        kiteName  : "databases"
        method    : "createMysqlDatabase"
    , (err, response)=>
        if err
            parseOutput err.message, yes
            callback? err
        else
            parseOutput """
                <br>Database created:<br>
                  Database User: #{response.dbUser}<br>
                  Database Name: #{response.dbName}<br>
                  Database Host: #{response.dbHost}<br>
                  Database Pass: #{response.dbPass}<br>
                <br>
                """
            callback null, response

###
Checks system whether given path exists or not, if exists outputs a message
if not, an exception will be thrown and there wont be any regular response

@var formData Object
@var callback function
###
checkPath = (formData, callback)->

    {path, domain} = formData

    if path is "" then callback yes
    else
        #Checks system whether given path exists or not
        kc.run "stat /Users/#{nickname}/Sites/#{domain}/website/#{path}"
        , (err, response)->
        #if there is any response, we have allready gotten this path in usage
            if response
                parseOutput "Specified path isn't available, please delete it or select another path!", yes
            callback? err, response


###
Installs a new zend framwork application

@var formData Object
@var callback function
###
installWordpress = (formData, dbinfo, callback)->

    #thx to cs
    #path       = formData.path
    #domain     = formData.domain
    #timestamp  = formData.timestamp
    #db         = formData.db
    {path, domain, timestamp, db} = formData

    userDir   = "/Users/#{nickname}/Sites/#{domain}/website/"
    tmpAppDir = "#{userDir}app.#{timestamp}"

    commands = [  "git clone https://github.com/zendframework/ZendSkeletonApplication.git '#{tmpAppDir}'"
                "cd '#{tmpAppDir}'"
                "pwd"
                #"php #{tmpAppDir}/composer.phar self-update"
                #"php #{tmpAppDir}/composer.phar --working-dir='#{tmpAppDir}' install"
            ]

    #if path is not given install into root of website
    if path is ""
        commands.push "cp -R #{tmpAppDir}/* #{userDir}"
    #if any path is given move
    else
        commands.push "mv '#{tmpAppDir}/' '#{userDir}#{path}'"


    # Run commands in correct order if one fails do not continue
    runInQueue = (cmds, index)=>
        command  = cmds[index]
        #if we comsumed all commands in queue
        if cmds.length == index or not command
            parseOutput "<br>ZendFramwork2 successfully installed to: #{userDir}#{path}<br>"
            # add our brand new application into dashboard
            appStorage.fetchValue 'zf2apps', (zf2apps)->
                zf2apps or= []
                zf2apps.push formData
                appStorage.setValue "zf2apps", zf2apps
            callback? formData
          
            # It's gonna be le{wait for it....}gendary.
            KD.utils.wait 1000, ->
                appManager.openFileWithApplication "http://#{nickname}.koding.com/#{path}", "Viewer"
        #if we have commands to run
        else
            parseOutput "$ #{command}<br/>"
            #kc is a kiteController, which makes requests to BE with "run" command
            kc.run command, (err, res)=>
                if err
                    parseOutput err, yes
                    #@todo remove temp directory, after an exception
                else
                    parseOutput res + '<br/>'
                    #run commands recursively
                    runInQueue cmds, index + 1
                  
    #start running pushed commands
    runInQueue commands, 0
  
  
