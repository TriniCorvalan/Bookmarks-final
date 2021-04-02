class HomeController < ApplicationController
  def index
    @bookmarks = Bookmark.joins(:kinds).group("kinds.title").count
  end
end
