require "rake/clean"
require 'rake/packagetask'

PLUGIN_DIR = 'plugin'

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
  p.package_files.include ['', 'en/', 'ja/'].map {|dir| "#{PLUGIN_DIR}/#{dir}atom.rb"}
  p.need_tar_gz = true
end

Rake::PackageTask.new 'jquery', :noversion do |p|
  p.package_files.include "#{PLUGIN_DIR}/jquery.rb"
  p.need_tar_gz = true
end

Rake::PackageTask.new 'private-view', :noversion do |p|
  p.package_files.include private_view_required_files
  p.need_tar_gz = true
end

Rake::PackageTask.new 'read-more', :noversion do |p|
  p.package_files.include ['', 'en/', 'ja/'].map {|dir| "#{PLUGIN_DIR}/#{dir}read-more.rb"}
  p.need_tar_gz = true
end

Rake::PackageTask.new 'disqus', :noversion do |p|
  p.package_files.include ['', 'en/', 'ja/'].map {|dir| "#{PLUGIN_DIR}/#{dir}disqus.rb"}
  p.need_tar_gz = true
end

DOC_SRC = FileList["doc/*.hikidoc"]
DOC_HTML = DOC_SRC.pathmap("%X.html")
DOC_HTML.include "README.html"
DOC_DEST = DOC_HTML.pathmap("public/%f")
DOC_DEST.include "public/index.html"

CLEAN.include DOC_HTML

directory "public"
CLOBBER.include "public"

DOC_HTML.each do |html|
  file File.join("public", File.basename(html)) => html do |t|
    copy t.source, t.name
  end
end

file "public/index.html" => ["public", "public/README.html"] do |t|
  copy t.sources[1], t.name
end

desc "Build documents"
task :doc => ["public/index.html"] + DOC_DEST do |t|
end

rule ".html" => ".hikidoc" do |t|
  sh "hikidoc --no-wikiname #{t.source} > #{t.name}"
end
