WLC_ROOT = File.expand_path(File.join(File.dirname(__FILE__), "..")) unless defined? WLC_ROOT

unless defined? WLC::Version
  module WLC

    class ReloadPage < Exception
    end

    module Version
      Major = '0'
      Minor = '0'
      Tiny = nil
      Patch = '1'

      class << self
        def to_s
          [ Major, Minor, Tiny, Patch].delete_if{|v| v.nil?}.join('.')
        end
        alias :to_str :to_s
      end
    end
  end
end
