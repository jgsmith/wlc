module AssignmentsHelper
  def prompts_to_extjs_items(info)
    form_items = [ ]

    if !info[:eval][:instructions].blank?
      if !info[:portfolio].blank?
        form_items << {
          :xtype => 'panel',
          :html =>  "<table border='0' width='100%'><tr><td width='50%' valign='top'>" + 
                    markdown(info[:eval][:instructions]) + 
                    "</td><td width='50%' valign='top'>" +
                    info[:portfolio] +
                    "</td></tr></table>"
        }
      else
        form_items << {
          :xtype => 'panel',
          :html =>  markdown(info[:eval][:instructions])
        }
      end
    elsif !info[:portfolio].blank?
      form_items << {
        :xtype => 'panel',
        :html => info[:portfolio]
      }
    end

    form_items << {
      :inputType => 'hidden',
      :xtype => 'field',
      :name => 'authenticity_token',
      :value => form_authenticity_token
    }

    eval_item = 0
    info[:eval][:prompts].each do |prompt|
      next_score = 0
      item = {
        :xtype => 'fieldset',
        :title => prompt[:prompt],
        :items => [ ]
      }

      prompt[:responses].each do |response|
        this_score = response[:score]
        this_score = next_score if this_score.blank?
        item[:items] << {
          :xtype => 'radio',
          :boxLabel => response[:response],
          :hideLabel => true,
          :name => "eval[#{eval_item.to_s}]",
          :inputValue => this_score,
          :checked => (!info[:values].nil? && this_score.to_s == info[:values][eval_item.to_s].to_s)
        }
        if response[:score].blank?
          next_score = next_score + 1
        else
          next_score = response[:score].to_i + 1
        end
      end

      eval_item = eval_item + 1
      form_items << item
    end

    return form_items
  end
end
