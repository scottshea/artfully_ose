module LinkHelper
  def active?(section)
    "active" if content_for(:_active_section) == section.to_s || content_for(:_active_sub_section) == section.to_s
  end

  def active_section
    content_for(:_active_section)
  end

  def in_section(section)
    content_for(:_active_section, section)
  end

  def in_sub_section(section)
    content_for(:_active_sub_section, section)
  end

  def active_link_to(text, url='#', condition=nil)
    if condition.nil? and String === url
      condition = url == request.path
    end
    content_tag :li, link_to(text, url), :class => (condition && 'active')
  end
end