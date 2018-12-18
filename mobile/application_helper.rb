module Mobile::ApplicationHelper
  PAGES = {
    home: { route: 'argggg', title: 'Title' }
  }

  def goto_home
    @curr_page = PAGES[:home]
  end
end
