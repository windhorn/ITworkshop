require "net/http"
require "date"

class EventSearchController < ApplicationController
  def index
    keyword = params[:event_search][:keyword]
    p keyword

    keywords = ["勉強会","AWS"]

    ### ATND APIからイベントを取得する.
    @events = getEvents(true, keywords)

  end

  private

  ### 各種APIからkeywordを基にイベントを検索するプライベートメソッド
  ### 第1引数: AND,OR検索を判定する．
  ###         AND => true, OR => false
  ### 第2引数: keywordを格納した配列
  ### 返り値: イベント名，日付，場所，イベントURLを格納したハッシュを返す．
  def getEvents(condition, keyword)
    events = []
    uri = generateQuery(condition, keyword)
    json = Net::HTTP.get(uri)
    result = JSON.parse(json)
    result['events'].each do |event|
      events.push({'title'=>event['title'], 'date'=>event['started_at'], 'place'=>event['place'], 'url'=>event['event_url']})
    end
    return events
  end

  ### クエリを生成するプライベートメソッド
  ### 第1引数: AND,OR検索を判定する．
  ###         AND => true, OR => false
  ### 第2引数: keywordを格納した配列
  ### 返り値: ATND APIに対応したクエリを返す.
  def generateQuery(condition, keywordArray)
    ### 開催年月のパラメータを生成
    today =  Date.today.strftime("%Y%m")
    queryDate = 'ym=' + today
    ### end
    ### キーワードパラメータを生成
    if condition
      ### AND検索
      queryKeyword = String.new('keyword=')
      queryKeyword += keywordArray.join(",")
    else
      ### OR検索
      queryKeyword = String.new('keyword_or=')
      queryKeyword += keywordArray.join(",")
    end
    ### end
    url = "http://api.atnd.org/events/?format=json"
    url += "&#{queryDate}&#{queryKeyword}"
    url = Addressable::URI.parse(url)
    return url
  end
end
