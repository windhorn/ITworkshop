require "net/http"

class EventSearchController < ApplicationController
  def index
    @events = []
    ### ATND APIからイベントを取得する.
    uri = URI.parse('http://api.atnd.org/events/?ym=201407&count=100&format=json')
    json = Net::HTTP.get(uri)
    result = JSON.parse(json)['events']
    result.each do |event|
      @events.push( {'title'=>event['title'], 'date'=>event['started_at'], 'place'=>event['place'], 'url'=>event['event_url']} )
    end
  end
end
