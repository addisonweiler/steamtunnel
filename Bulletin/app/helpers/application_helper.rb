module ApplicationHelper
  # Specify which javascript and stylesheet to include
  def javascript(*files)
      content_for(:head) { javascript_include_tag(*files) }
  end
  def stylesheet(*files)
      content_for(:head) { stylesheet_link_tag(*files) }
  end
end
