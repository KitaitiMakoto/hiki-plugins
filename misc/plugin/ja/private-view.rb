# coding: utf-8
def private_view_label; '閲覧制限'; end
def private_view_description
  '　閲覧制限に使うキーワードを設定してください（一行に一つ）。設定したキーワードを使用したページに閲覧制限が掛かり、ログインしない限り見られなくなります。'
end
def private_view_used_keywords_label; '閲覧制限用に設定されているキーワード'; end
def private_view_keyword_insertion_description
  'クリックすると上のキーワード欄に挿入されます'
end
def private_view_dependency_warning
  '　閲覧制限を行うには次のプラグインを有効化し、登録ユーザーのみ編集可能にしてください。'
end
load_file File.join(File.dirname(__FILE__), 'edit_user.rb')
