module ApplicationHelper
  def external_link_to(name = nil, options = nil, html_options = nil, &block)
    options = options.dup
    link_to name, options, { target: :_blank, rel: 'noopener noreferrer' }.reverse_merge(html_options || {}), &block
  end

  def inline_role_tag(value)
    tag.span class: 'inline -role' do
      EventFollow.role.find_value(value).text
    end
  end

  def inline_visibility_tag(value, hide_public: false)
    return if hide_public && value.to_sym == :public

    tag.span class: 'inline -visibility' do
      Event.visibility_emoji_text(value)
    end
  end

  def inline_resolution_tag(value)
    tag.span class: 'inline -resolution' do
      EventHistory.resolution_emoji_text(value)
    end
  end

  def inline_officiality_tag(value, emoji_only: false)
    tag.span class: "inline -officiality #{value}" do
      emoji = value ? '🐏' : '🌱'
      enum_name = value ? 'official' : 'unofficial'
      emoji_only ? emoji : "#{emoji}#{t(enum_name, scope: 'enumerize.defaults.officiality')}"
    end
  end

  def icon_size_num(size)
    case size
    when :small then '32px'
    when :medium then '48px'
    when :large then '64px'
    else '48px'
    end
  end

  def time_span_text(start_at, end_at)
    repeat_time_span_text(:oneshot, start_at, end_at)[1..2]
  end

  def repeat_time_span_text(repeat, start_at, end_at)
    case repeat.to_sym
    when :some_day, :every_day
      repeat_text = EventSchedule.repeat.find_value(repeat).text
      start_at_text = l(start_at, format: :hm)
    when :every_other_week
      repeat_text = EventSchedule.repeat.find_value(repeat).text
      start_at_text = l(start_at)
    when :every_week, :first_week, :second_week, :third_week, :fourth_week, :fifth_week, :even_week, :odd_week, :last_week
      repeat_text = "#{EventSchedule.repeat.find_value(repeat).text} #{l(start_at, format: '%A')}"
      start_at_text = l(start_at, format: :hm)
    else
      repeat_text = ''
      start_at_text = l(start_at)
    end
    case (end_at.beginning_of_day - start_at.beginning_of_day) / 1.day
    when 0
      [repeat_text, start_at_text, l(end_at, format: :hm)]
    when 1
      [repeat_text, start_at_text, l(end_at.change(hour: 0), format: :hm).sub('0', (end_at.hour + 24).to_s)]
    else
      [repeat_text, start_at_text, l(end_at)]
    end
  end

  # from Kaminari::Helpers::Tag
  PARAM_KEY_EXCEPT_LIST = [:authenticity_token, :commit, :utf8, :_method, :script_name, :original_script_name].freeze
  def filtered_params
    params.to_unsafe_h.with_indifferent_access.except(*PARAM_KEY_EXCEPT_LIST)
  end

  def render_errors_header(form)
    render 'errors_header', form: form
  end

  def render_field(form, field_name, label: nil, required: false, &block)
    render 'field', form: form, label: label, field_name: field_name, required: required, &block
  end

  def render_text_field(form, field_name, required: false, label: nil, &block)
    render 'field', form: form, label: label, field_name: field_name, required: required do
      s = form.text_field(field_name)
      s << capture(&block) if block
      s
    end
  end
end
