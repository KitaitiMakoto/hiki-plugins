def private_view_label; 'Private View'; end
def private_view_description
  'Write keyword(s) used for access control(one keyword per line). Pages using keyword(s) included in below list are not viewable by users without login.'
end
def private_view_used_keywords_label; 'Keywords set for use of private view'; end
def private_view_keyword_insertion_description
  'Click to insert the keyword into keywords box above'
end
def private_view_dependency_warning
  'Enable plugin and permit only registrated users in order to make private view enabled.'
end
load_file File.join(File.dirname(__FILE__), 'edit_user.rb')
