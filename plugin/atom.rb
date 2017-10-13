# = $Id: atom.rb, v1.0 2011-01-31
# Copyright (C) 2011 KITAITI Makoto <KitaitiMakoto@gmail.com>
#
# A Hiki plugin to syndicate Atom feed 
#
# rss.rb plugin is very helpful for this plugin, thanks!
# 
# == Requirements
#  * rss library which can make Atom feeds
#    (If your rss lib cannot, download from 
#     http://www.cozmixng.org/~rwiki/?cmd=view;name=RSS+Parser)
# 
# == Environment
#  Operation checked under:
#  * Ruby 1.8.7
#  * Hiki 0.8.8.1
# 
# == To Do
#  * Refactoring(Extract Method)
require 'time'

def atom
  if @conf['atom.entry.enable'] && @page
    atom_entry(@page)
  else
    atom_feed
  end
end

def atom_feed
  page_count = @conf['atom.count'] || atom_default_page_count
  pages = atom_recent_updates(page_count)
  last_modified = pages.first.values[0][:last_modified]
  header = {}
  
  if_modified_since = ENV['HTTP_IF_MODIFIED_SINCE']
  if_modified_since = Time.parse(if_modified_since) if if_modified_since
  
  if if_modified_since and last_modified <= if_modified_since
    header['status'] = 'NOT_MODIFIED'
    return ::Hiki::Response.new('', 304, header)
  else
    body = atom_body(pages)
    header['Last-Modified'] = last_modified.httpdate
    header['type']  = 'application/atom+xml'
    header['charset']       =  body.encoding
    header['Content-Language'] = @conf.lang
    header['Pragma']           = 'no-cache'
    header['Cache-Control']    = 'no-cache'
    return ::Hiki::Response.new(body.to_s, 200, header)
  end
end

def atom_entry(page_name)
  page = @db.info(page_name)
  return print @cgi.header({'status' => 'NOT_FOUND'}) unless page
  return print @cgi.header({'status' => 'FORBIDDEN'}) if respond_to?(:viewable?) && !viewable?(page.keys[0].to_s) # for private-view.rb plugin
  
  last_modified = page[:last_modified]
  header = {}
  
  if_modified_since = ENV['HTTP_IF_MODIFIED_SINCE']
  if_modified_since = Time.parse(if_modified_since) if if_modified_since
  
  if if_modified_since and last_modified <= if_modified_since
    header['status'] = 'NOT_MODIFIED'
    return ::Hiki::Response.new('', 304, header)
  else
    require 'rss/maker'
    
    body = RSS::Maker.make('atom:entry') do |maker|
      atom_make_entry(maker, {page_name => page }, :default_author => 'anonymous', :mode => :html_full)
    end
    
    header['Last-Modified'] = last_modified.httpdate
    header['type']  = 'application/atom+xml'
    header['charset']       = body.encoding
    header['Content-Language'] = @conf.lang
    header['Pragma']           = 'no-cache'
    header['Cache-Control']    = 'no-cache'
    return ::Hiki::Response.new(body.to_s, 200, header)
  end
end

def atom_recent_updates(page_count = atom_default_page_count)
  pages = @db.page_info
  pages.reject! {|page| private_view_private_page?(page.keys[0])} if respond_to? :private_view_private_page? # for private-view.rb plugin
  pages.sort_by do |p|
    p[p.keys[0]][:last_modified]
  end.last(page_count).reverse
end

def atom_body(pages)
  require 'rss/maker'
  
  RSS::Maker.make('atom') do |maker|
    maker.encoding = 'UTF-8'
    
    maker.channel.author = @conf.author_name
    maker.channel.about = @conf.index_url + '?c=atom'
    maker.channel.title = @conf.site_name + ' : ' + label_atom_recent
    maker.channel.description = @conf.site_name + ' ' + label_atom_recent
    maker.channel.language = @conf.lang
    maker.channel.date = pages.first.values[0][:last_modified]
    maker.channel.rights = 'Copyright (C) ' + @conf.author_name
    maker.channel.generator do |generator|
      generator.uri = 'http://hikiwiki.org/'
      generator.version = ::Hiki::VERSION
      generator.content = 'Hiki'
    end
    maker.channel.links.new_link do |link|
      link.rel = 'self'
      link.type = 'application/atom+xml'
      link.href = maker.channel.about
    end
    maker.channel.links.new_link do |link|
      link.rel = 'alternate'
      link.type = 'text/html'
      link.href = @conf.index_url + '?c=recent'
    end
    
    pages.each do |page|
      atom_make_entry(maker, page)
    end
  end
end

def atom_make_entry(maker, page, options = {})
  maker.items.new_item do |item|
    name = page.keys[0]    
    uri = @conf.index_url + '?' + escape(name)
    
    item.title = page_name(name)
    item.link = uri
    item.author = options[:default_author] if options[:default_author]
    item.author = page[name][:editor] if page[name][:editor]
    item.date = page[name][:last_modified].utc.strftime('%Y-%m-%dT%H:%M:%S+00:00')
    item.content.type = 'html'
    item.content.content = atom_make_content(page, options[:mode])
  end
end

def atom_make_content(page, mode = nil)
  mode ||= @conf['atom.mode']
  raise ArgumentError, "Unknown mode: #{mode}" unless [:unidiff, :worddiff_digest, :worddiff_full, :html_full].include?(mode)
  
  name = page.keys[0]
  src = @db.load_backup(name) || ''
  dst = @db.load(name) || ''
  
  case mode
  when :unidiff
    content = h(unified_diff(src, dst)).strip.gsub(/\n/, "<br>\n").gsub(/ /, '&nbsp;')
  when :worddiff_digest
    content = word_diff(src, dst, true).strip.gsub(/\n/, "<br>\n")
  when :worddiff_full
    content = word_diff(src, dst).strip.gsub(/\n/, "<br>\n")
  when :html_full
    tokens = @db.load_cache(name)
    unless tokens
      parser = @conf.parser.new(@conf)
      tokens = parser.parse(@db.load(name))
      @db.save_cache(name, tokens)
    end
    tmp = @conf.use_plugin
    begin
      @conf.use_plugin = false
      formatter = @conf.formatter.new(tokens, @db, Plugin.new(@conf.options, @conf), @conf)
      content = formatter.to_s
    ensure
      @conf.use_plugin = tmp
    end
  end
  if content.empty?
    content = shorten(dst).strip.gsub(/\n/, "<br>\n")
  end
  
  content
end

def atom_max_page_count; 50; end
def atom_default_page_count; 10; end

add_body_enter_proc do
  @conf['atom.mode'] ||= :unidiff
  @conf['atom.menu'] ? add_plugin_command('atom', 'Atom') : add_plugin_command('atom', nil)
end

add_header_proc do
  %Q|  <link rel="alternate" type="application/atom+xml" title="Atom" href="#{@conf.index_url}?c=atom">\n|
end

if @conf['atom.entry.enable']
  if @conf['atom.entry.menu-display']
    add_menu_proc {%Q|<a href="#{@conf.index_url}?c=atom;p=#{escape(@page)}">Atom Entry</a>|} if @page
  end
  add_header_proc { %Q|  <link rel="alternate" type="application/atom+xml" title="Atom Entry" href="#{@conf.index_url}?c=atom;p=#{escape(@page)}">| } if @page
end

def atom_saveconf
  if @mode == 'saveconf'
    @conf['atom.mode'] = @cgi.params['atom.mode'][0].intern
    @conf['atom.count'] = [@cgi.params['atom.count'][0].to_i, atom_max_page_count].min
    @conf['atom.count'] = [@conf['atom.count'], 1].max
  end
end

if @cgi.params['conf'] == 'atom' && @mode == 'saveconf'
  @conf['atom.menu'] = (@cgi.params['atom.menu'][0] == 'true')
  @conf['atom.entry.enable'] = (@cgi.params['atom.entry.enable'][0] == 'true')
  @conf['atom.entry.menu-display'] = (@cgi.params['atom.entry.menu-display'][0] == 'true')
end

add_conf_proc('atom', label_atom_config) do
  atom_saveconf
  
  str = <<HTML
  <h3 class="subtitle">#{label_atom_mode_title}</h3>
  <p><select name="atom.mode">
HTML
  label_atom_mode_candidate.each_pair do |value, label|
    str << %Q|<option value="#{value}"#{' selected' if @conf['atom.mode'] == value}>#{label}</option>\n|
  end
  str << "</select></p>\n"
  
  str << <<HTML
  <h3 class="subtitle">#{label_atom_menu_title}</h3>
  <p><label><input type="radio" name="atom.menu" value="true"
                   #{'checked="checked"' if @conf['atom.menu']}>
            #{label_atom_menu_enable}</label>
     <label><input type="radio" name="atom.menu" value="false"
                   #{'checked="checked"' unless @conf['atom.menu']}>
            #{label_atom_menu_disable}</label>\n
HTML
  
  str << <<HTML
  <h3 class="subtitle">#{label_atom_count_title}</h3>
  <p><input name="atom.count" size="4"
      value="#{@conf['atom.count']}">
     #{label_atom_count_unit}(#{label_atom_max_page_count})</p>
HTML
  
  str << <<HTML
  <h3 class="subtitle">#{label_atom_entry_enable_title}</h3>
  <p><label><input type="radio" name="atom.entry.enable" value="true"
             #{'checked="checked"' if @conf['atom.entry.enable']}>
             #{label_atom_entry_enable}</label>
     <label><input type="radio" name="atom.entry.enable" value="false"
             #{'checked="checked"' unless @conf['atom.entry.enable']}>
             #{label_atom_entry_disable}</label></p>
  <h3 class="subtitle">#{label_atom_entry_menu_display_title}</h3>
  <p><label><input type="radio" name="atom.entry.menu-display" value="true"
            #{'checked="checked"' if @conf['atom.entry.menu-display']}>
            #{label_atom_entry_menu_display}</label>
     <label><input type="radio" name="atom.entry.menu-display" value="false"
            #{'checked="checked"' unless @conf['atom.entry.menu-display']}>
            #{label_atom_entry_menu_hide}</label></p>
HTML
end

export_plugin_methods :atom
