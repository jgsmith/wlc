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
    end

    form_items << {
      :inputType => 'hidden',
      :xtype => 'field',
      :name => 'authenticity_token',
      :value => form_authenticity_token
    }

    eval_item = 0
    info[:eval][:prompts].each do |prompt|
      item = {
        :xtype => 'fieldset',
        :title => prompt[:prompt],
        :items => [ ]
      }

      prompt[:responses].each do |response|
        item[:items] << {
          :xtype => 'radio',
          :boxLabel => response[:response],
          :name => "eval[#{eval_item.to_s}]",
          :inputValue => response[:score],
          :checked => (!info[:values].nil? && response[:score].to_s == info[:values][eval_item.to_s].to_s)
        }
      end

      eval_item = eval_item + 1
      form_items << item
    end

    return form_items
  end
end
