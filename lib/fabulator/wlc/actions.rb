module Fabulator
  WLC_NS = "http://dh.tamu.edu/ns/fabulator/wlc/1.0#"

  require 'fabulator/wlc/actions/make-asset-available'

  module WLC
    module Actions
      class Lib
        include Fabulator::ActionLib

        register_namespace WLC_NS

        action 'make-asset-available', MakeAssetAvailable
      end
    end
  end
end
