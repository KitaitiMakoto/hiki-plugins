# $Id: quote_page.rb,v 1.5 2005-12-28 22:42:55 fdiary Exp $
# Copyright (C) 2003 OZAWA Sakuro <crouton@users.sourceforge.jp>
unless collect_plugins(sp_hash_from_dirs(@sp_path))[0].include?('private-view.rb')
  load_file File.join(File.dirname(__FILE__), 'quote_page.rb')
else

add_body_enter_proc {
  @quote_page_quoted = []
  ''
}

def quote_page(name, top_wanted=1)
  return unless viewable?(name)
  unless @quote_page_quoted.include?(name)
    @quote_page_quoted << name
    tokens = @conf.parser.new(@conf).parse(@db.exist?(name) ? @db.load(name) : %Q|[[#{name}]]|, top_wanted.to_i + 1)
    @conf.formatter.new(tokens, @db, self, @conf).to_s
  else
    ''
  end
end

export_plugin_methods(:quote_page)

end # of 'unless' on top of this file
