require 'rake/packagetask'

PLUGIN_DIR = 'misc/plugin'

def private_view_required_files
  (['private-view.rb'] |
   %w[category google-sitemaps incremental_search keyword orphan pagerank quote_page rank recent2 rss sitemap].map {|f| "#{f}_private-view.rb"} |
   %w[en ja].map {|f| "#{f}/private-view.rb"} |
   %w[rss].map {|f| "de/#{f}_private-view.rb"} |
   %w[rss].map {|f| "en/#{f}_private-view.rb"} |
   %w[rss].map {|f| "fr/#{f}_private-view.rb"} |
   %w[rss].map {|f| "it/#{f}_private-view.rb"} |
   %w[rss].map {|f| "ja/#{f}_private-view.rb"}
   ).map { |f| "#{PLUGIN_DIR}/#{f}" }
end

Rake::PackageTask.new 'atom', :noversion do |p|
  p.package_files.include ['atom.rb', 'en/atom.rb', 'ja/atom.rb'].map {|f| "#{PLUGIN_DIR}/#{f}"}
  p.need_tar_gz = true
end

Rake::PackageTask.new 'private-view', :noversion do |p|
  p.package_files.include private_view_required_files
  p.need_tar_gz = true
end
