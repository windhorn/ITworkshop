require "net/http"
require "date"

class EventSearchController < ApplicationController
  def index
    if params[:event_search]
      keywords = parseKeyword(params[:event_search][:keyword])
    else
      keywords = ""
    end
    ### ATND APIからイベントを取得する.
    @events = getEvents(true, keywords)

  end

  private

  ### 入力された文字列をスペースで区切って配列で返すメソッド
  ### スペースは全角，半角どちらでもOK
  ### 第1引数: 文字列
  ### 返り値: 検索キーワードの配列
  def parseKeyword(keyword)
    keyword.gsub!(/[\s ]/," ")      # 全角スペースを半角スペースに置き換える
    return keyword.to_s.split(nil)  # 半角スペースで区切って配列として返す
  end

  ### 各種APIからkeywordを基にイベントを検索するプライベートメソッド
  ### 第1引数: AND,OR検索を判定する．
  ###         AND => true, OR => false
  ### 第2引数: keywordを格納した配列
  ### 返り値: イベント名，日付，場所，イベントURLを格納したハッシュを返す．
  def getEvents(condition, keyword)
    events = []
    if keyword.size > 0
      ### 検索キーワードが入力されている時
      uri = generateQuery_keyword(condition, keyword)
    else
      ### 検索キーワードが入力されていない時
      uri = generateQuery()
    end
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
  def generateQuery_keyword(condition, keywordArray)
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

  ### クエリを生成するプライベートメソッド
  ### 第1引数: AND,OR検索を判定する．
  ###         AND => true, OR => false
  ### 第2引数: keywordを格納した配列
  ### 返り値: ATND APIに対応したクエリを返す.
  def generateQuery()
    ### 開催年月のパラメータを生成
    today =  Date.today.strftime("%Y%m")
    queryDate = 'ym=' + today
    ### end
    url = "http://api.atnd.org/events/?format=json"
    url += "&#{queryDate}"
    url = Addressable::URI.parse(url)
    return url
  end

end
