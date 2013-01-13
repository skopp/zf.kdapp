class DashboardPane extends Pane

    constructor:->

        super

        @listController = new KDListViewController
            lastToFirst     : yes
            viewOptions     :
                type          : "wp-blog"
                itemClass     : InstalledAppListItem

        @listWrapper = @listController.getView()

        @notice = new KDCustomHTMLView
            tagName : "p"
            cssClass: "why-u-no"
            partial : "You can start here creating a ZendFramework2 Skeletion Application"

        @notice.hide()

        @loader = new KDLoaderView
            size          :
                width       : 60
            cssClass      : "loader"
            loaderOptions :
                color       : "#ccc"
                diameter    : 30
                density     : 30
                range       : 0.4
                speed       : 1
                FPS         : 24

        @listController.getListView().on "DeleteLinkClicked", (listItemView)=>

            {path, domain, name} = listItemView.getData()

            userDir = "/Users/#{nickname}/Sites/#{domain}/website/"

            if path.trim() is ""
                path    = ""
                message = "Oh, its installed to root! <strong>you need to delete files manually</strong>."
                command = ""
                warning = ""
            else
                message = "<pre>#{userDir}#{path}</pre>"
                command = "rm -r '#{userDir}#{path}'"
                warning = """<p class='modalformline' style='color:red'>
                                Warning: This will remove everything under #{userDir}#{path} directory!
                             </p>"""

            modal = new KDModalView
                title          : "Are you sure want to delete this ZF2 Application?"
                content        : """
                                  <div class='modalformline'>
                                    <p>#{message}</p>
                                  </div>
                                  #{warning}
                                 """
                height         : "auto"
                overlay        : yes
                width          : 500
                buttons        :
                    Delete       :
                        style      : "modal-clean-red"
                        loader     :
                            color    : "#ffffff"
                            diameter : 16
                        callback   : =>
                            @removeItem listItemView
                            if path is ""
                                modal.buttons.Delete.hideLoader()
                                modal.destroy()
                            else
                                split.resizePanel 250, 0
                                parseOutput "<br>Deleting /Users/#{nickname}/Sites/#{domain}/website/#{path}<br><br>"
                                parseOutput command
                                kc.run withArgs : {command} , (err, res)=>
                                    modal.buttons.Delete.hideLoader()
                                    modal.destroy()
                                    if err
                                        parseOutput err, yes
                                        new KDNotificationView
                                            title    : "There was an error, you may need to remove it manually!"
                                            duration : 3333
                                    else
                                        parseOutput "<br>#############"
                                        parseOutput "<br>#{name} successfully deleted."
                                        parseOutput "<br>#############<br>"
                                        tc.refreshFolder tc.nodes["/Users/#{nickname}/Sites/#{domain}/website"]

                                    @utils.wait 1500, ->
                                        split.resizePanel 0, 1

    removeItem:(listItemView)->

        zf2apps = appStorage.getValue "zf2apps"
        appToDelete = listItemView.getData()
        zf2apps.splice zf2apps.indexOf(appToDelete), 1

        appStorage.setValue "zf2apps", zf2apps, =>
            @listController.removeItem listItemView
            appStorage.fetchValue "zf2apps", (zf2apps)=>
                zf2apps?=[]
                @notice.show() if zf2apps.length is 0

    putNewItem:(formData, resizeSplit = yes)->

        tabs = @getDelegate()
        tabs.showPane @
        @listController.addItem formData
        @notice.hide()
        if resizeSplit
            @utils.wait 1500, -> split.resizePanel 0, 1

    viewAppended:->

        super

        @loader.show()

        appStorage.fetchStorage (storage)=>
            @loader.hide()
            zf2apps = appStorage.getValue("zf2apps") or []
            if zf2apps.length > 0
                zf2apps.sort (a, b) -> if a.timestamp < b.timestamp then -1 else 1
                zf2apps.forEach (item)=> @putNewItem item, no
            else
                @notice.show()

    pistachio:->
        """
        {{> @loader}}
        {{> @notice}}
        {{> @listWrapper}}
        """

class InstalledAppListItem extends KDListItemView

    constructor:(options, data)->

        options.type = "wp-blog"

        super options, data

        @delete = new KDCustomHTMLView
            tagName : "a"
            cssClass: "delete-link"
            click   : => @getDelegate().emit "DeleteLinkClicked", @

    viewAppended:->

        @setTemplate @pistachio()
        @template.update()
        @utils.wait => @setClass "in"

    pistachio:->
        {path, timestamp, domain, name} = @getData()
        url = "http://#{domain}/#{path}"
        """
        {{> @delete}}
        <a target='_blank' class='name-link' href='#{url}'>{{ #(name)}}</a>
        <a target='_blank' class='raw-link' href='#{url}'>#{url}</a>
        <time datetime='#{new Date(timestamp)}'>#{$.timeago new Date(timestamp)}</time>
        """
