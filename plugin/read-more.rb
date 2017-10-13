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
#
# ! Styling
# Anchor element with hidden content has class 'read-more-show',
# and it will be removed when the content will be shown by clicking the anchor.
# So you can style the anchor with toggling color, image and so on.
#
# ! To do
# * User specified text of anchor
# * User specified sliding speed 
@read_more_count = 0

def read_more(page)
  @read_more_count += 1
  <<EOQ
  <div class="read-more">
    <div style="display: none;">
#{quote_page(page)}
    </div>
    <a href="./?#{page}" class="read-more-show">#{read_more_show_label}</a>
  </div>
EOQ
end

add_footer_proc do
  @read_more_count == 0 ? '' : <<EOS
<script type="text/javascript" charset="#{@conf.charset}">
  jQuery.fn.readMoreToggleText = function (first, second) {
    return this.text(this.text() == first ? second : first);
  };
  (function ($) {
    $('div.read-more a').click(function (event) {
      event.preventDefault();
      var anchor = $(event.currentTarget);
      anchor.prev('div').slideToggle('normal', function () {
        anchor.toggleClass('read-more-show').
                 readMoreToggleText('#{read_more_show_label}', '#{read_more_hide_label}');
      });
    });
  })(jQuery);
</script>
EOS
end
