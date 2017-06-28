class WordCloudController < ApplicationController
  include CdsUtilHelper

  def get_wordcloud
    authorize :word_cloud, :index?
    cid = current_user.company_id
    gid = params['gid']
    sid = Snapshot.where(company_id: cid, snapshot_type: nil, status: Snapshot::STATUS_ACTIVE).order(id: :asc).last.id
    cache_key = "get-wordcloud-#{gid}"
    wordcloud = cache_read(cache_key)
    if wordcloud.nil?
      wordcloud = WordCloudHelper.get_word_cloud_for_group(cid, gid, sid)
      cache_write(cache_key, wordcloud)
    end
    render json: Oj.dump(wordcloud)
  end
end
