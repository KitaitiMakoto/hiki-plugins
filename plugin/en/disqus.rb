def disqus_label_settings
  "DISQUS settings"
end

def disqus_label_no_base_url
  <<HTML
<code>base_url</code> is not set. Set it in config file such as <code>hikiconf.rb</code>
HTML
end

def disqus_label_shortname_description
  %Q|Set DISQUS shortname. See DISQUS official document(<a href="https://help.disqus.com/customer/portal/articles/466208-what-s-a-shortname-">What's a shortname?</a>) for registration and knowing your shortname.|
end









