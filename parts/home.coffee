if Meteor.isClient
    Router.route '/', (->
        @layout 'layout'
        @render 'home'
        ), name:'home'

    Template.finance_bar.onRendered ->
        Meteor.setTimeout ->
            finance_stat = Docs.findOne model:'finance_stat'
            if finance_stat
                percent = 6000/finance_stat.total_expense_sum
                console.log percent
                $('.progress').progress({
                      percent: percent
                });
        , 2000
    
    Template.home.onCreated ->
        @autorun => Meteor.subscribe 'latest_debits'
        @autorun => Meteor.subscribe 'model_docs', 'finance_stat'

        # @autorun => Meteor.subscribe 'model_docs', 'transaction'
        @autorun => Meteor.subscribe 'model_docs', 'project'
        @autorun => Meteor.subscribe 'model_docs', 'task'
        # @autorun => Meteor.subscribe 'model_docs', 'comment'
        @autorun => Meteor.subscribe 'future_events'
        # @autorun => Meteor.subscribe 'model_docs', 'global_stats'
        # @autorun -> Meteor.subscribe('home_tag_results',
        #     selected_tags.array()
        #     selected_location_tags.array()
        #     selected_authors.array()
        #     Session.get('view_purchased')
        #     # Session.get('view_incomplete')
        #     )
        # @autorun -> Meteor.subscribe('home_results',
        #     selected_tags.array()
        #     selected_location_tags.array()
        #     selected_authors.array()
        #     Session.get('view_purchased')
        #     # Session.get('view_incomplete')
        #     )
        # @autorun => Meteor.subscribe 'model_docs', 'home_doc'

    Template.finance_bar.helpers
        viewing_finance_details: -> Session.get('view_finance_details')
        membership_payments: ->
            Docs.find 
                model:'expense'
                # membership:true
        
        finance_stat: ->
            Docs.findOne
                model:'finance_stat'
                # membership:true
        
        membership_count: ->
            Docs.find(
                model:'expense'
                membership:true
            ).count()
        
    Template.home.helpers
        featured_products: ->
            Docs.find
                model:'product'
        home_doc: ->
            Docs.findOne 
                model:'home_doc'
        stats_doc: ->
            Docs.findOne 
                model:'global_stats'
        can_debit: ->
            Meteor.user().points > 0
        stewards: ->
            Meteor.users.find
                levels:$in:['steward']
        latest_debits: ->
            Docs.find {
                model:'debit'
                submitted:true
            },
                sort:
                    _timestamp: -1
                limit:25
                
        latest_tasks: ->
            Docs.find {
                model:'task'
                # published:true
            },
                sort:
                    _timestamp: -1
                limit:10
        next_events: ->
            Docs.find {
                model:'event'
            },
                sort:
                    sort:date:1
                    sort:start_time:1
                limit:10
        next_shifts: ->
            Docs.find {
                model:'shift'
            },
                sort:
                    _timestamp: -1
                limit:10
        latest_projects: ->
            Docs.find {
                model:'project'
            },
                sort:
                    _timestamp: -1
                limit:10
        debits: ->
            Docs.find
                model:'debit'
        members: ->
            Meteor.users.find({},
                sort:points:1)
    Template.finance_bar.events
        'click .toggle_finance_details': ->
            Session.set('view_finance_details', !Session.get('view_finance_details'))
    
    Template.home.events
        'click .view_debit': ->
            Router.go "/m/debit/#{@_id}/view"
        'click .view_task': ->
            Router.go "/m/task/#{@_id}/view"
        'click .view_project': ->
            Router.go "/m/project/#{@_id}/view"

        'click .refresh_stats': ->
            Meteor.call 'calc_global_stats'
        'click .debit': ->
            new_debit_id =
                Docs.insert
                    model:'debit'
            Router.go "/m/debit/#{new_debit_id}/edit"
        'click .add_task': ->
            new_task_id =
                Docs.insert
                    model:'task'
            Router.go "/m/task/#{new_task_id}/edit"
        'click .add_event': ->
            new_event_id =
                Docs.insert
                    model:'event'
            Router.go "/m/event/#{new_event_id}/edit"
        'click .add_project': ->
            new_project_id =
                Docs.insert
                    model:'project'
            Router.go "/m/project/#{new_project_id}/edit"
        'click .add_task': ->
            new_task_id =
                Docs.insert
                    model:'task'
            Router.go "/m/task/#{new_task_id}/edit"
        
        'click .add_message': ->
            new_message_id =
                Docs.insert
                    model:'message'
            Router.go "/m/message/#{new_message_id}/edit"

        'keydown .find_username': (e,t)->
            # email = $('submit_email').val()
            if e.which is 13
                email = $('.submit_email').val()
                if email.length > 0
                    Docs.insert
                        model:'email_signup'
                        email_address:email
                    $('body')
                      .toast({
                        class: 'success'
                        position: 'top right'
                        message: "#{email} added to list"
                      })
                    $('.submit_email').val('')


    Template.home_event_card.onCreated ->
        # console.log @
        @autorun => Meteor.subscribe 'event_transactions', @data
        @autorun => Meteor.subscribe 'doc_comments', @data._id

    Template.debit_card.onCreated ->
        @autorun => Meteor.subscribe 'doc_comments', @data._id
    Template.home_project_card.onCreated ->
        @autorun => Meteor.subscribe 'doc_comments', @data._id
    Template.home_task_card.onCreated ->
        @autorun => Meteor.subscribe 'doc_comments', @data._id

    # Template.home_card.events
    #     'click .record_home': ->
    #         Meteor.users.update Meteor.userId(),
    #             $inc: points:-@points
    #         $('body').toast({
    #             class: 'info',
    #             message: "#{@points} spent"
    #         })
    #         Docs.insert
    #             model:'home_item'
    #             parent_id: @_id


if Meteor.isServer
    Meteor.publish 'event_transactions', (event)->
        # console.log event
        Docs.find 
            model:'transaction'
            event_id:event._id