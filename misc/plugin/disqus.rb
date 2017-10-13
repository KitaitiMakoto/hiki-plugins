$DEBUG=true

require "uri"

class DISQUSPlugin
  include Hiki::Util

  NAME = "disqus"

  attr_reader :shortname, :base_url, :url, :identifier, :title

  def initialize(conf, url, identifier, title)
    init_conf conf
    @url = url
    @identifier = identifier
    @title = title
  end

  def canonical_url
    return unless base_url
    base_url + url
  end

  def output
    unless @shortname
      warn "[DISQUS plugin]shortname is not configured. Set it at admin panel."
      return
    end
    unless @base_url
      warn "[DISQUS plugin]base_url is not configured. Set it in config file."
      return
    end
    template.result(binding)
  end

  private

  def init_conf(conf)
    @shortname = conf["#{NAME}.shortname"]
    @base_url = URI(conf.base_url) if conf.base_url
  end

  def escape_js_string_single_quote(string)
    string.to_s.gsub("'", "\\'")
  end

  def template
    ERB.new(<<TEMPLATE)
<div id="disqus_thread"></div>
<script>

/**
*  RECOMMENDED CONFIGURATION VARIABLES: EDIT AND UNCOMMENT THE SECTION BELOW TO INSERT DYNAMIC VALUES FROM YOUR PLATFORM OR CMS.
*  LEARN WHY DEFINING THESE VARIABLES IS IMPORTANT: https://disqus.com/admin/universalcode/#configuration-variables*/
var disqus_config = function () {
<% if canonical_url %>this.page.url = '<%= escape_js_string_single_quote canonical_url %>';<% end %>
<% if identifier && !identifier.empty? %>this.page.identifier = '<%= escape_js_string_single_quote(identifier) %>';<% end %>
<% if title && !title.empty? %>this.page.title = '<%= escape_js_string_single_quote(title) %>';<% end %>
};
(function() { // DON'T EDIT BELOW THIS LINE
var d = document, s = d.createElement('script');
s.src = 'https://<%= escape_js_string_single_quote(shortname) %>.disqus.com/embed.js';
s.setAttribute('data-timestamp', +new Date());
(d.head || d.body).appendChild(s);
})();
</script>
<noscript>Please enable JavaScript to view the <a href="https://disqus.com/?ref_noscript">comments powered by Disqus.</a></noscript>
TEMPLATE
  end
end

def disqus
  DISQUSPlugin.new(@conf, hiki_url(@page), escape(@page), page_name(@page)).output
end

def disqus_saveconf
  return unless @mode == "saveconf"

  @conf["disqus.shortname"] = @request.params["disqus.shortname"]
end

add_conf_proc("disqus", disqus_label_settings) do
  if @conf.base_url.nil? || @conf.base_url.empty?
    next "<p>#{disqus_label_no_base_url}</p>"
  end

  disqus_saveconf

  <<HTML
<h3>shortname</h3>
<p>#{disqus_label_shortname_description}</p>
<p><input name="disqus.shortname" value="#{escapeHTML @conf['disqus.shortname']}" type="text" /></p>
HTML
end

export_plugin_methods :disqus
