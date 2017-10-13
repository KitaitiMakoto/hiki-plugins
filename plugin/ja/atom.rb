# coding: utf-8
# ja/atom.rb

def label_atom_recent
  '更新日時順'
end

def label_atom_config; 'Atom の配信'; end
def label_atom_mode_title; 'Atom Feedのフォーマット'; end
def label_atom_mode_candidate
  {
    :unidiff => 'unified diff 形式',
    :worddiff_digest => 'word diff 形式 (ダイジェスト)',
    :worddiff_full => 'word diff 形式 (全文)',
    :html_full => 'HTML 形式 (全文)',
  }
end
def label_atom_menu_title; 'Atom Feedメニューの表示'; end
def label_atom_menu_enable; 'する'; end
def label_atom_menu_disable; 'しない'; end
def label_atom_count_title; 'Atom Feedで配信するページの数'; end
def label_atom_count_unit; '件'; end
def label_atom_max_page_count; "最大#{atom_max_page_count}件"; end

def label_atom_entry_enable_title; '各ページのAtom Entryの配信'; end
def label_atom_entry_enable; 'する'; end
def label_atom_entry_disable; 'しない'; end
def label_atom_entry_menu_display_title; '各ページのAtom Entryメニューの表示'; end
def label_atom_entry_menu_display; 'する'; end
def label_atom_entry_menu_hide; 'しない'; end
