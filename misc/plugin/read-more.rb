# read-more.rb
#
# Copyright (c) 2011 KITAITI Makoto <KitaitiMaoto@gmail.com>
#
# ! Requirements
# * quote_page plugin(quote_page.rb)
# * jQuery plugin(jquery.rb)
#
# ! Usage
# # Create a page which has a content to be hidden, let name of the page 'MoreText'.
# # In another page, call read more plugin like this:
# <<<
# {{read_more(MoreText)}}
# >>>
@read_more_count = 0

def read_more(page)
  @read_more_count += 1
  <<EOQ
  <div>
    <div class="read-more" style="display: none;">
#{quote_page(page)}
    </div>
    <a href="?#{page}" class="read-more">#{read_more_show_label}</a>
  </div>
EOQ
end

add_footer_proc do
  <<EOS
<script type="text/javascript" charset="#{@conf.charset}">
  jQuery.fn.readMoreToggleText = function (first, second) {
    return this.text(this.text() == first ? second : first);
  };
  (function ($) {
    $('a.read-more').click(function (event) {
      event.preventDefault();
      var anchor = $(event.target);
      anchor.prev('.read-more').slideToggle('normal', function () {
        anchor.readMoreToggleText('#{read_more_show_label}', '#{read_more_hide_label}')
      });
    });
  })(jQuery);
</script>
EOS
end
