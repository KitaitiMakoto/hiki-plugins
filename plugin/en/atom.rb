# en/atom.rb

def label_atom_recent
  'Recent Changes'
end

def label_atom_config; 'Atom syndication'; end
def label_atom_mode_title; 'Select the format of the feed.' end
def label_atom_mode_candidate
  {
    :unidiff => 'unified diff',
    :worddiff_digest => 'word diff(digest)',
    :worddiff_full => 'word diff(full text)',
    :html_full => 'HTML(full text)',
  }
end
def label_atom_menu_title; 'Add Atom Feed menu'; end
def label_atom_menu_enable; 'Yes'; end
def label_atom_menu_disable; 'No'; end
def label_atom_count_title; 'The count of syndicated feeds'; end
def label_atom_count_unit; 'pages'; end
def label_atom_max_page_count; "#{atom_max_page_count} at a max"; end

def label_atom_entry_enable_title; 'Syndicate Atom Entry per page'; end
def label_atom_entry_enable; 'Yes'; end
def label_atom_entry_disable; 'No'; end
def label_atom_entry_menu_display_title; 'Add Atom Entry menu'; end
def label_atom_entry_menu_display; 'Yes'; end
def label_atom_entry_menu_hide; 'No'; end
