require "net/http"
require "date"

class EventSearchController < ApplicationController
  def index
    if params[:event_search]
      keywords = parseKeyword(params[:event_search][:keyword])
      @this_month = params[:event_search][:this_month]
      ### パラメータから受け取ったbooleanはString型になっているので，
      ### それを正規表現を用いてboolean型にする.
      condition = params[:event_search][:condition] =~ /^true$/i ? true : false
    else
      keywords = ""
      condition = true
    end

    unless params[:started]
      ### パラメータの年月が渡されていない時は今月のDateオブジェクトを生成する．
      date = Date.today
      @this_month ||= date.strftime("%Y%m")
      @next_month = date.next_month.strftime("%Y%m")
      @prev_month = date.prev_month.strftime("%Y%m")
    else
      ### パラメータの年月が渡された時には，一度Dateオブジェクトにキャストしてから，次月先月をインスタンスに格納する．
      date = Date.strptime(params[:started], "%Y%m")
      @this_month ||= date.strftime("%Y%m")
      @next_month = date.next_month.strftime("%Y%m")
      @prev_month = date.prev_month.strftime("%Y%m")
    end
    ### ATND APIからイベントを取得する.
    @events = getEvents(condition, keywords, @this_month)
  end

  private

  ### 先月，今月，次月をハッシュで返すメソッド
  ### 第1引数: 今月の月のDateオブジェクト
  ### 返り値: prev,this,next_monthのハッシュ
  def generateMonth(this_month=Date.today)
    returnHash = {}
    ### 引数がDateオブジェクトなのかをチェックする
    if this_month.class == Date
      returnHash.store('this_month', this_month.strftime("%Y%m"))
      returnHash.store('next_month', this_month.next_month.strftime("%Y%m"))
      returnHash.store('prev_month', this_month.prev_month.strftime("%Y%m"))
    else
      date = Date.strptime(this_month, "%Y%m")
      returnHash.store('this_month', date.strftime("%Y%m"))
      returnHash.store('next_month', date.next_month.strftime("%Y%m"))
      returnHash.store('prev_month', date.prev_month.strftime("%Y%m"))
    end
    retutn returnHash
  end

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
  ### 第3引数: イベント開催年月
  ### 返り値: イベント名，日付，場所，イベントURLを格納したハッシュを返す．
  def getEvents(condition, keyword, date)
    events = []
    if keyword.size > 0
      ### 検索キーワードが入力されている時
      uri = generateQuery_keyword(condition, keyword, date)
    else
      ### 検索キーワードが入力されていない時
      uri = generateQuery(date)
    end
    json = Net::HTTP.get(uri)
    result = JSON.parse(json)
    result['events'].each do |event|
      events.push({'title'=>event['event']['title'], 'date'=>event['event']['started_at'], 'place'=>event['event']['place'], 'url'=>event['event']['event_url']})
    end
    return events
  end

  ### クエリを生成するプライベートメソッド
  ### 第1引数: AND,OR検索を判定する．
  ###         AND => true, OR => false
  ### 第2引数: keywordを格納した配列
  ### 第3引数: イベントの開催年月
  ### 返り値: ATND APIに対応したクエリを返す.
  def generateQuery_keyword(condition, keywordArray, date)
    ### 開催年月のパラメータを生成
    queryDate = 'ym=' + date.to_s
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
  ### 第3引数: イベントの開催年月
  ### 返り値: ATND APIに対応したクエリを返す.
  def generateQuery(date)
    ### 開催年月のパラメータを生成
    queryDate = 'ym=' + date.to_s
    ### end
    url = "http://api.atnd.org/events/?format=json"
    url += "&#{queryDate}"
    url = Addressable::URI.parse(url)
    return url
  end

end
