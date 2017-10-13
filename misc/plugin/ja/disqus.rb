# coding: utf-8
def disqus_label_settings
  "DISQUS設定"
end

def disqus_label_no_base_url
  <<HTML
<code>base_url</code>が設定されていません。<code>hikiconf.rb</code>などの設定ファイルで設定してください。
HTML
end
def disqus_label_shortname_description
  %Q|DISQUSのshortnameを設定してください。shortnameの登録と確認はDISQUS公式ドキュメント（<a href="https://help.disqus.com/customer/portal/articles/466208-what-s-a-shortname-">What's a shortname?</a>）をご覧ください。|
end
