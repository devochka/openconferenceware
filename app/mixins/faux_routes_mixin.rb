# = FauxRoutesMixin
#
# The FauxRoutesMixin generates a bunch of route helpers for the
# TracksController and SessionTypesController nested resources.
#
# == Examples
#
# Long-hand way of expressing "/events/:event_id/tracks/:track_id":
#   event_track_path(@event, @track)
#
# Faux route helper for expressing the same thing and getting Event from @event:
#   track_path(@track)
#
module FauxRoutesMixin
  # FIXME this implementation is 10x more complex than it should be, but I don't know how to make it simpler

  def self.included(mixee)
    mixee.extend(Methods)

    if mixee.ancestors.include?(ActionController::Base)
      mixee.class_eval do
        Methods.instance_methods.each do |name|
          RAILS_DEFAULT_LOGGER.debug("Faux route, helperized: #{name}")
          helper_method(name)
        end
      end
    end
  end

  module Methods
    # Create a single route for the +options+.
    faux_route_for = lambda do |opts|
      verb = opts[:verb]
      noun = opts[:noun]
      item = opts[:item]
      for kind in %w[path url]
        real = "#{verb ? verb+'_' : nil}event_#{noun}_#{kind}"
        faux = "#{verb ? verb+'_' : nil}#{noun}_#{kind}"
        if item
          define_method(faux, proc{|item, *args| send(real, item.event, item, *args)})
        else
          define_method(faux, proc{|*args| send(real, @event, *args)})
        end
        RAILS_DEFAULT_LOGGER.debug("Faux route, created: #{faux} <= #{real}")
      end
    end

    # Create all common routes for this +resource+.
    faux_routes_for = lambda do |resource|
      resource = resource.to_s.singularize
      faux_route_for[:noun => resource]
      faux_route_for[:noun => resource.pluralize]
      faux_route_for[:noun => resource, :verb => "new"]
      faux_route_for[:noun => resource, :item => true]
      faux_route_for[:noun => resource, :verb => "new", :item => true]
    end

    # Create faux routes for the following +resources+:
    faux_routes_for["tracks"]
    faux_routes_for["session_types"]
    faux_routes_for["rooms"]
  end

  include Methods
  extend Methods

end