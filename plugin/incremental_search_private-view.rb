# -*- coding: utf-8 -*-
# ajaxsearch.rb $Revision: 1.3 $
# Copyright (C) 2005 Michitaka Ohno <elpeo@mars.dti.ne.jp>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

unless collect_plugins(sp_hash_from_dirs(@sp_path))[0].include?('private-view.rb')
  plugin_path = @conf.plugin_path || "#{Hiki::PATH}/plugin"
  Dir::glob("#{plugin_path}/*.rb").sort.each do |file|
    load_plugin(file) if File::basename(file) == "incremental_search.rb"
  end
end

def search
  as = Hiki::AjaxSearch.new(@request, @db, @conf)
  @request.params['key'] ? as.search : as.form
end

module Hiki
  class AjaxSearch < Command
    def form
      data = get_common_data( @db, @plugin, @conf )
      @plugin.hiki_menu( data, @cmd )
      body =<<-HTML
            <script language="JScript">
            <!--
             try {
                    xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
            } catch (e) {
                    xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
            }
            // -->
            </script>
            <script language="JavaScript">
            <!--
            if(typeof XMLHttpRequest != 'undefined'){
                    xmlhttp = new XMLHttpRequest();
            }
            function invoke(key) {
                    if (!document.getElementById) return;
                    if (!xmlhttp) return;
                    xmlhttp.open("GET", "#{@conf.cgi_name}#{cmdstr('search', 'key=')}"+encodeURI(key), true);
                    xmlhttp.onreadystatechange=function() {
                            if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
                                    document.getElementById("result").innerHTML = xmlhttp.responseText;
                            }
                    }
                    xmlhttp.send(null)
            }
            // -->
            </script>
            <div class="day">
              <div class="body">
                <div class="section">
                  <div>#{@conf.msg_search_comment}</div>
                  <form method="GET">
                    #{@conf.msg_search}: <input type="hidden" value="search_orig" name="c">
                    <input size="50" maxlength="50" name="key" onkeyup="invoke(this.value)" onfocus="invoke(this.value)">
                    <input type="submit" value="検索">
                  </form>
                  <div id="result">
                  </div>
                </div>
              </div>
            </div>
            HTML
      data[:title] = data[:view_title] = title( @conf.msg_search )
      data[:body] = body
      @cmd = 'plugin'
      generate_page(data)
    end

    def search
      word = @request.params['key']
      r = ""
      unless word.empty? then
        total, l = @db.search( word )
        if @conf.hilight_keys
          l.collect! {|p| @plugin.make_anchor("#{@conf.cgi_name}?cmd=view&p=#{escape(p[0])}&key=#{escape(word.split.join('+'))}", @plugin.page_name(p[0])) + " - #{p[1]}"}
        else
          l.collect! {|p| @plugin.hiki_anchor(escape(p[0]), @plugin.page_name(p[0])) + " - #{p[1]}"}
        end
        if l.size > 0 then
          r = "<ul>\n" + l.map{|i| "<li>#{i}</li>\n"}.join + "</ul>\n"
        end
      end
      header = {}
      header['type'] = 'text/html'
      header['charset'] = 'UTF-8'
      header['Content-Language'] = @conf.lang
      header['Pragma'] = 'no-cache'
      header['Cache-Control'] = 'no-cache'
      ::Hiki::Response.new(r, 200, header)
    end
  end
end

eval(<<TOPLEVEL_CLASS, TOPLEVEL_BINDING)
module Hiki
  class Command
    def cmd_search_orig
      @conf.template['search_orig'] = @conf.template['search']
      cmd_search
    end
  end
end
TOPLEVEL_CLASS

add_body_enter_proc do
  add_plugin_command( 'search', nil )
end
