require 'rexml/document'
require 'yaml'

class AssignmentsWithFabulator < ActiveRecord::Migration
  def self.up
    add_column :assignments, :xml_definition, :text

    Assignment.find(:all).each do |a|
      xml = REXML::Document.new('<wlc:assignment xmlns:wlc="http://dh.tamu.edu/ns/fabulator/wlc/1.0#" />')
      if !a.trust_fn.nil? && a.trust_fn != ''
        tmp = REXML::Element.new('wlc:trust')
        tmp.add_attribute('wlc:select', a.trust_fn)
        xml.root << tmp
      end

      if !a.calculate_score_fn.nil? && a.calculate_score_fn != ''
        tmp = REXML::Element.new('wlc:score')
        tmp.add_attribute('wlc:select', a.calculate_score_fn)
        xml.root << tmp
      end

      a.assignment_modules.sort_by { |r| r.position }.each do |m|
        module_xml = REXML::Element.new('wlc:module')

        module_xml.add_attribute('wlc:name', m.tag)

        module_xml.add_attribute('wlc:duration', m.duration.to_s)

        if m.module_def.nil?
          if m.has_messaging?
            module_xml.add_attribute('wlc:messaging', 'yes')
          end
        else
          module_xml.add_attribute('wlc:module', m.module_def.name)
        end

        module_xml.add_attribute('wlc:participants', m.number_participants.to_s)

        if !m.author_name.nil? && m.author_name != ''
          module_xml.add_attribute('wlc:author-name', m.author_name)
        end

        if !m.participant_name.nil? && m.participant_name != ''
          module_xml.add_attribute('wlc:participant-name', m.participant_name)
        end

        if !m.download_filename_prefix.nil? && m.download_filename_prefix != ''
          module_xml.add_attribute('wlc:file-prefix', m.download_filename_prefix)
        end

        if !m.params.nil?
          tmp = REXML::Element.new('wlc:params')
          param_doc = REXML::Document.new(m.params.to_xml)
          #tmp.add_text(m.params.to_xml)
          tmp << param_doc.root
          module_xml << tmp
        end

        if !m.name.nil? && m.name != ''
          tmp = REXML::Element.new('wlc:caption')
          tmp.add_text(m.name)
          module_xml << tmp
        end

        if !m.instructions.nil? && m.instructions != ''
          tmp = REXML::Element.new('wlc:instructions')
          tmp.add_text(m.instructions)
          module_xml << tmp
        end

        xml.root << module_xml
      end

      s = ''
      xml.write(s, 2)
      a.update_attribute(:xml_definition, s)
      puts "Updating assignment #{a.id}"
      a.save!
    end
  end

  def self.down
    remove_column :assignments, :xml_definition
  end
end

