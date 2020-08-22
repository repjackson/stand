if Meteor.isClient
    @selected_user_levels = new ReactiveArray []
    
    Router.route '/task/:doc_id/view', (->
        @layout 'layout'
        @render 'task_view'
        ), name:'task_view'

    Template.task_view.onCreated ->
        @autorun => Meteor.subscribe 'doc', Router.current().params.doc_id
        @autorun => Meteor.subscribe 'parent_doc', Router.current().params.doc_id
        @autorun => Meteor.subscribe 'child_docs', Router.current().params.doc_id
   
    Template.registerHelper 'parent', () ->
        Docs.findOne @parent_id
   
    Template.registerHelper 'child_docs', () ->
        Docs.find
            parent_id:@_id
   
   
    Template.task_view.onRendered ->

    Template.task_view.helpers
        can_complete: ->
            count = Docs.find(
                model:'task'
                parent_id:@_id
                complete:false
            )
            console.log count.count()
            count.count() == 0
        
        
    Template.task_view.events
        'click .add_subtask': ->
            new_sub_id = 
                Docs.insert 
                    model:'task'
                    parent_id:@_id
            Router.go "/m/task/#{new_sub_id}/edit"
                    
        'click .mark_complete': ->
            Meteor.call 'mark_complete', @_id, ->
        'click .mark_incomplete': ->
            Meteor.call 'mark_incomplete', @_id, ->
                    
    Template.task_view.events
        'click .mark_complete': ->
            Meteor.call 'mark_complete', @_id, ->
        'click .mark_incomplete': ->
            Meteor.call 'mark_incomplete', @_id, ->
            

if Meteor.isServer
    Meteor.methods
        mark_complete: (doc_id)->
            task = Docs.findOne doc_id
            Docs.update task._id,
                $set:
                    complete:true
                    completed_by_id:Meteor.userId()
                    completed_by_username:Meteor.user().username
                    completed_timestamp:Date.now()
    
        mark_incomplete: (doc_id)->
            task = Docs.findOne doc_id
            Docs.update task._id,
                $set:
                    complete:false
                $unset:    
                    completed_by_id:1
                    completed_by_username:1
                    completed_timestamp:1
        # send_task: (task_id)->
        #     task = Docs.findOne task_id
        #     target = Meteor.users.findOne task.recipient_id
        #     gifter = Meteor.users.findOne task._author_id
        #
        #     console.log 'sending task', task
        #     Meteor.users.update target._id,
        #         $inc:
        #             points: task.amount
        #     Meteor.users.update gifter._id,
        #         $inc:
        #             points: -task.amount
        #     Docs.update task_id,
        #         $set:
        #             publishted:true
        #             submitted_timestamp:Date.now()
        #
        #
        #
        #     Docs.update Router.current().params.doc_id,
        #         $set:
        #             submitted:true


if Meteor.isClient
    Template.task_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc', Router.current().params.doc_id
    Template.task_edit.onRendered ->


    Template.task_edit.events
        'click .delete_item': ->
            if confirm 'delete item?'
                Docs.remove @_id

        'click .publish': ->
            Docs.update Router.current().params.doc_id,
                $set:published:true
            if confirm 'confirm?'
                Meteor.call 'publish_task', @_id, =>
                    Router.go "/task/#{@_id}/view"


    Template.task_edit.helpers
    Template.task_edit.events

if Meteor.isServer
    Meteor.methods
        reward_task: (task_id, target_id)->
            task = Docs.findOne task_id
            target = Meteor.users.findOne target_id

            console.log 'rewarding task', task
            Meteor.users.update target._id,
                $addToSet:
                    rewarded_task_ids: task._id
                    
                    
    Meteor.publish 'parent_doc', (child_id)->
        child = Docs.findOne child_id
        Docs.find
            _id:child.parent_id
            
            
    Meteor.publish 'child_docs', (parent_id)->
        Docs.find
            parent_id:parent_id
            
            
            