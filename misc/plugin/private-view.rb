# private-view.rb v 0.6
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
        display_text = escapeHTML((f[k][:title] and f[k][:title].size > 0) ? f[k][:title] : k)
        display_text << " [#{@aliaswiki.aliaswiki(k)}]" if k != @aliaswiki.aliaswiki(k)
        %Q!#{@plugin.hiki_anchor(escape(k), display_text)}: #{format_date(f[k][:last_modified] )} #{editor}#{@conf.msg_freeze_mark if f[k][:freeze]}!
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
        display_text = escapeHTML(display_text)
        display_text << " [#{@aliaswiki.aliaswiki(k)}]" if k != @aliaswiki.aliaswiki(k)
        %Q|#{format_date( tm )}: #{@plugin.hiki_anchor( escape(k), display_text )} #{escapeHTML(editor)} (<a href="#{@conf.cgi_name}#{cmdstr('diff',"p=#{escape(k)}")}">#{@conf.msg_diff}</a>)|
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
        word = @params['key']
        if word && word.size > 0
          contents = hilighten(contents, unescape(word).split)
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

      data[:page_title]   = (@plugin.hiki_anchor( escape(@p), escapeHTML(@p) ))
      data[:view_title]   = pg_title
      data[:title]        = title( escapeHTML(unescapeHTML(pg_title)) )
      data[:toc]          = @plugin.toc_f ? toc : nil
      data[:body]         = formatter.apply_tdiary_theme(contents)
      data[:references]   = ref.collect! {|a| "[#{@plugin.hiki_anchor(escape(a), @plugin.page_name(a))}] " }.join
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
          l.collect! {|p| @plugin.make_anchor("#{@conf.cgi_name}?cmd=view&p=#{escape(p[0])}&key=#{escape(word.split.join('+'))}", @plugin.page_name(p[0])) + " - #{p[1]}"}
        else
          l.collect! {|p| @plugin.hiki_anchor( escape(p[0]), @plugin.page_name(p[0])) + " - #{p[1]}"}
        end
        data             = get_common_data( @db, @plugin, @conf )
        data[:title]     = title( @conf.msg_search_result )
        data[:msg2]      = @conf.msg_search + ': '
        data[:button]    = @conf.msg_search
        data[:key]       = %Q|value="#{escapeHTML(word)}"|
          word2            = word.split.join("', '")
        if l.size > 0
          data[:msg1]    = sprintf( @conf.msg_search_hits, escapeHTML(word2), total, l.size )
          data[:list]    = l
        else
          data[:msg1]    = sprintf( @conf.msg_search_not_found, escapeHTML(word2) )
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
    an = hiki_anchor(escape(name), t)
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
  private_view_saveconf if @mode == 'saveconf'
  
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

def private_view_saveconf
  @conf['private-view.keywords'] = @cgi.params['private-view.keywords'][0].split("\n").collect {|kw| kw.strip}.delete_if {|kw| kw.size == 0}
  
  used, notused, unknown = collect_plugins(sp_hash_from_dirs(@sp_path))
  related = @cgi.params.select {|k, v| k =~ /\A#{SP_PREFIX}\./}.collect {|param| param[0][SP_PREFIX.length+1 .. -1]}
  enabled = related.select {|plugin| @cgi.params["#{SP_PREFIX}.#{plugin}"][0] == 't'}
  disabled = related - enabled
  
  @conf["#{SP_PREFIX}.selected"] = (used - disabled + enabled).uniq * "\n"
  @conf["#{SP_PREFIX}.notselected"] = (notused + unknown - enabled + disabled).uniq * "\n"
  enabled.each {|plugin| load_plugin File.expand_path(File.join(File.dirname(__FILE__), plugin))}
  
  @conf['user.auth'] = @cgi.params['user.auth'][0].to_i
end

def private_view_dependency
  dependent_plugin_files = ['edit_user.rb']
  used_plugins, = collect_plugins(sp_hash_from_dirs(@sp_path))
  dependent_plugins_enabled = (dependent_plugin_files - used_plugins).empty?
  dependency_filled = dependent_plugins_enabled && (@conf['user.auth'] == 0)
  return if dependency_filled
  
  <<EOH
<h3>#{label_edit_user_config}</h3>
#{'<p><em>' + private_view_dependency_warning + '</em></p>'}
#{'<ul>' + sp_li_plugins(dependent_plugin_files, true, dependent_plugins_enabled) + '</ul>' unless dependent_plugins_enabled}
#{'<p>' + private_view_edit_user_auth + '</p>' unless @conf['user.auth'] == 0}
<h3>#{private_view_label}</h3>
EOH
end

def private_view_edit_user_auth
  html = label_edit_user_auth_description
  label_edit_user_auth_candidate.each_with_index do |cand, i|
    html << %Q|<label><input type="radio" name="user.auth" value="#{i}"#{
              ' checked' if @conf['user.auth'] == i}>#{cand}</label>|
  end
  
  html
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
