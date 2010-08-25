require 'rexml/document'
require 'yaml'

class ModuleDefsWithFabulator < ActiveRecord::Migration
  def self.up
    add_column :module_defs, :xml_definition, :text
    add_column :state_defs,  :view,           :text

    ModuleDef.find(:all).each do |m|
      xml = REXML::Document.new('<f:module xmlns:f="http://dh.tamu.edu/ns/fabulator/1.0#" />')
      xml.root << REXML::Comment.new('Begin init_fn')
      xml.root << REXML::Comment.new(m.init_fn)
      xml.root << REXML::Comment.new('End init_fn')
      m.state_defs.each do |s|
        state_xml = REXML::Element.new('f:view')
        state_xml.add_attribute('f:name', s.name)
        if !s.pre_fn.nil? && s.pre_fn != ''
          tmp = REXML::Element.new('f:begin')
          tmp.add_text(s.pre_fn)
          state_xml << tmp
        end
      
        if !s.post_fn.nil? && s.post_fn != ''
          tmp = REXML::Element.new('f:post')
          tmp.add_text(s.post_fn)
          state_xml << tmp
        end

        s.transition_defs.each do |t|
          transition_xml = REXML::Element.new('f:goes-to')
          transition_xml.add_attribute('f:view', t.to_state.name)
          tmp = REXML::Element.new('f:params')
          tmp << REXML::Comment.new(t.validate_fn)
          transition_xml << tmp
          transition_xml << REXML::Comment.new(t.process_fn)
          state_xml << transition_xml
        end
        xml.root << state_xml
      end
      s = ''
      xml.write(s, 2)
      m.update_attribute(:xml_definition, s)
      m.save!
    end

    StateDef.find(:all).each do |s|
      xml = REXML::Document.new('<view />')
      tmp = REXML::Element.new('text')
      tmp.add_text(s.view_text)
      xml.root << tmp
      form_data = s.view_form # YAML::parse(s.view_form)
      form_xml = REXML::Element.new('form')
      if !form_data[:items].nil?
        form_data[:items].each do |item|
          el_name = case item[:inputType]
            when 'file': 'file'
          end

          tmp = REXML::Element.new(el_name)
          tmp.add_attribute('id', item[:name])
          caption = REXML::Element.new('caption')
          caption.add_text(item[:fieldLabel])
          tmp << caption
          form_xml << tmp
        end
      end
      if form_data[:submit]
        tmp = REXML::Element.new('submit')
        tmp.add_attribute('id', 'submit')
        caption = REXML::Element.new('caption')
        caption.add_text(form_data[:submit])
        tmp << caption
        form_xml << tmp
      end
      xml.root << form_xml
      str = ''
      xml.write(str, 2)
      s.update_attribute(:view, str)
      s.save!
    end
  end

  def self.down
    remove_column :module_defs, :xml_definition
    remove_column :state_defs,  :view
  end
end

