module ResponsesHelper

  def response_title(response)
    "#{response.survey.name} - Cycle ID #{response.cycle_id} - Year of Treatment #{response.year_of_registration}"
  end

  def prep_help(text)
    if text.blank?
      ""
    else
      simple_format(h text).html_safe
    end
  end
end
