# private-view.rb v 0.5
# Copyright (C) 2011 Kitaiti Makoto <KitaitiMakoto@gmail.com>
#
# Requirements:
#   * edit_user plugin must be activated
module ::Hiki
  class Command
    def cmd_index
      # modified by this plugin(delete_if was inserted)
      list = @db.page_info.delete_if {|e| !@plugin.viewable?(e.keys[0])}.sort_by {|e|
        k,v = e.to_a.first
        if v[:title] && !v[:title].empty?
          v[:title].downcase
        else
          k.downcase
        end
      }.collect {|f|
        k = f.keys[0]
        editor = f[k][:editor] ? "by #{f[k][:editor]}" : ''
        display_text = ((f[k][:title] and f[k][:title].size > 0) ? f[k][:title] : k).escapeHTML
        display_text << " [#{@aliaswiki.aliaswiki(k)}]" if k != @aliaswiki.aliaswiki(k)
        %Q!#{@plugin.hiki_anchor(k.escape, display_text)}: #{format_date(f[k][:last_modified] )} #{editor}#{@conf.msg_freeze_mark if f[k][:freeze]}!
      }

      data = get_common_data( @db, @plugin, @conf )

      data[:title]     = title( @conf.msg_index )
      data[:updatelist] = list

      generate_page( data )
    end
    
    def get_recent
      # modified by this plugin(delete_if was inserted)
      list = @db.page_info.delete_if {|e| !@plugin.viewable?(e.keys[0]) }.sort_by {|e|
        k,v = e.to_a.first
        v[:last_modified]
      }.reverse

      last_modified = list[0].values[0][:last_modified]

      list.collect! {|f|
        k = f.keys[0]
        tm = f[k][:last_modified]
        editor = f[k][:editor] ? "by #{f[k][:editor]}" : ''
        display_text = (f[k][:title] and f[k][:title].size > 0) ? f[k][:title] : k
        display_text = display_text.escapeHTML
        display_text << " [#{@aliaswiki.aliaswiki(k)}]" if k != @aliaswiki.aliaswiki(k)
        %Q|#{format_date( tm )}: #{@plugin.hiki_anchor( k.escape, display_text )} #{editor.escapeHTML} (<a href="#{@conf.cgi_name}#{cmdstr('diff',"p=#{k.escape}")}">#{@conf.msg_diff}</a>)|
      }
      [list, last_modified]
    end
    
    def cmd_view
      raise PermissionError, 'Permission denied' unless @plugin.viewable?( @p )
      
      unless @db.exist?( @p )
        @cmd = 'create'
        cmd_create( @conf.msg_page_not_exist )
        return
      end

      tokens = @db.load_cache( @p )
      unless tokens
        text = @db.load( @p )
        parser = @conf.parser.new( @conf )
        tokens = parser.parse( text )
        @db.save_cache( @p, tokens )
      end
      formatter = @conf.formatter.new( tokens, @db, @plugin, @conf )
      contents, toc = formatter.to_s, formatter.toc
      if @conf.hilight_keys
        word = @params['key'][0]
        if word && word.size > 0
          contents = hilighten(contents, word.unescape.split)
        end
      end

      old_ref = @db.get_attribute( @p, :references )
      new_ref = formatter.references 
      @db.set_references( @p, new_ref ) if new_ref != old_ref
      ref = @db.get_references( @p )
      # inserted by this plugin
      ref.reject! { |ref_page| ! @plugin.viewable?(ref_page) }

      data = get_common_data( @db, @plugin, @conf )

      pg_title = @plugin.page_name(@p)

      data[:page_title]   = (@plugin.hiki_anchor( @p.escape, @p.escapeHTML ))
      data[:view_title]   = pg_title
      data[:title]        = title( pg_title.unescapeHTML )
      data[:toc]          = @plugin.toc_f ? toc : nil
      data[:body]         = formatter.apply_tdiary_theme(contents)
      data[:references]   = ref.collect! {|a| "[#{@plugin.hiki_anchor(a.escape, @plugin.page_name(a))}] " }.join
      data[:keyword]      = @db.get_attribute(@p, :keyword).collect {|k| "[#{view_title(k)}]"}.join(' ')

      data[:last_modified]  = @db.get_last_update( @p )
      data[:page_attribute] = @plugin.page_attribute_proc

      generate_page( data )
    end
    
    alias private_view_original_cmd_diff cmd_diff
    def cmd_diff
      raise PermissionError, 'Permission denied' unless @plugin.viewable?( @p )
      private_view_original_cmd_diff
    end
    
    def cmd_search
      word = @params['key'][0]
      if word && word.size > 0
        total, l = @db.search(word)
        
        # inserted by this plugin
        l.delete_if {|res| !@plugin.viewable?(res[0])}
        
        if @conf.hilight_keys
          l.collect! {|p| @plugin.make_anchor("#{@conf.cgi_name}?cmd=view&p=#{p[0].escape}&key=#{word.split.join('+').escape}", @plugin.page_name(p[0])) + " - #{p[1]}"}
        else
          l.collect! {|p| @plugin.hiki_anchor( p[0].escape, @plugin.page_name(p[0])) + " - #{p[1]}"}
        end
        data             = get_common_data( @db, @plugin, @conf )
        data[:title]     = title( @conf.msg_search_result )
        data[:msg2]      = @conf.msg_search + ': '
        data[:button]    = @conf.msg_search
        data[:key]       = %Q|value="#{word.escapeHTML}"|
          word2            = word.split.join("', '")
        if l.size > 0
          data[:msg1]    = sprintf( @conf.msg_search_hits, word2.escapeHTML, total, l.size )
          data[:list]    = l
        else
          data[:msg1]    = sprintf( @conf.msg_search_not_found, word2.escapeHTML )
          data[:list]    = nil
        end
      else
        data             = get_common_data( @db, @plugin, @conf )
        data[:title]     = title( @conf.msg_search )
        data[:msg1]      = @conf.msg_search_comment
        data[:msg2]      = @conf.msg_search + ': '
        data[:button]    = @conf.msg_search
        data[:key]       = 'value=""'
        data[:list]      = nil
        data[:method]  = 'get'
      end
      
      generate_page( data )
    end
  end
end

# patch for plugin/00default.rb
def recent( n = 20 )
  n = n > 0 ? n : 0

  # modified by this plugin(delete_if was inserted)
  l = @db.page_info.delete_if {|e| !viewable?(e.keys[0])}.sort do |a, b|
    b[b.keys[0]][:last_modified] <=> a[a.keys[0]][:last_modified]
  end

  s = ''
  c = 0
  ddd = nil
  
  l.each do |a|
    break if (c += 1) > n
    name = a.keys[0]
    p = a[name]
    
    tm = p[:last_modified ] 
    cur_date = tm.strftime( @conf.msg_date_format )

    if ddd != cur_date
      s << "</ul>\n" if ddd
      s << "<h5>#{cur_date}</h5>\n<ul>\n"
      ddd = cur_date
    end
    t = page_name(name)
    an = hiki_anchor(name.escape, t)
    s << "<li>#{an}</li>\n"
  end
  s << "</ul>\n"
  s
end

def viewable?( page = @page )
  !private_view_private_page?( page ) or editable?( page )
end

def private_view_private_page?( page )
  info = @db.info( page )
  return false unless info
  ! ((@conf['private-view.keywords'] || []) & info[:keyword]).empty?
end

add_conf_proc('private-view', private_view_label) do
  if @mode == 'saveconf'
    @conf['private-view.keywords'] = @cgi.params['private-view.keywords'][0].split("\n").collect {|kw| kw.strip}.delete_if {|kw| kw.size == 0}
    
    used, notused, unknown = collect_plugins(sp_hash_from_dirs(@sp_path))
    related_plugins = @cgi.params.select {|k, v| k =~ /\A#{SP_PREFIX}\./}.collect {|param| param[0][SP_PREFIX.length+1 .. -1]}
    enabled_plugins = related_plugins.select {|plugin| @cgi.params["#{SP_PREFIX}.#{plugin}"][0] == 't'}
    disabled_plugins = related_plugins - enabled_plugins
    
    @conf["#{SP_PREFIX}.selected"] = (used - disabled_plugins + enabled_plugins).uniq * "\n"
    @conf["#{SP_PREFIX}.notselected"] = (notused + unknown - enabled_plugins + disabled_plugins).uniq * "\n"
    enabled_plugins.each {|plugin| load_plugin File.expand_path(File.join(File.dirname(__FILE__), plugin))}
  end
  
  <<EOH
#{private_view_dependency}
<p>#{private_view_description}</p>
<p><textarea cols="20" rows="3" name="private-view.keywords">
#{(@conf['private-view.keywords'] || []) * "\n"}</textarea></p>
EOH
end

add_edit_proc do
<<EOH
<div style="margin: 1em 0">
<script type="text/javascript">
  function insertKeyword(keyword) {
    var box = keywordBox();
    box.value = box.value + "\\n" + keyword;
    box.focus();
  }
  function keywordBox() {
    var textareas = document.getElementsByTagName('textarea');
    var ta;
    var taLength = textareas.length
    for (var i = 0; i < taLength; i++) {
      ta = textareas[i];
      if (ta.name == 'keyword') return ta;
    }
  }
</script>
<p>#{private_view_used_keywords_label}
<script type="text/javascript">
  document.write('(#{private_view_keyword_insertion_description})');
</script></p>
<p style="text-indent: 1em;">#{@conf['private-view.keywords'].collect {|k| private_view_bracketed_keyword(k)} * ', '}</p>
</div>
EOH
end

def private_view_dependency
  dependent_plugin_files = ['edit_user.rb']
  used_plugins, = collect_plugins(sp_hash_from_dirs(@sp_path))
  return if used_plugins & dependent_plugin_files == dependent_plugin_files
<<EOH
<em>#{private_view_dependency_warning}</em>
<ul>
    #{sp_li_plugins(dependent_plugin_files, true, false)}
</ul>
EOH
end

def private_view_bracketed_keyword(keyword)
<<EOH
[<script type="text/javascript">document.write(
  '<a href="#" onclick="insertKeyword(\\'#{keyword}\\'); return false;">'
)</script>#{keyword}<script type="text/javascript">document.write(
  '</a>'
)</script>]
EOH
end

export_plugin_methods :recent
