module Fabulator
  WLC_NS = "http://dh.tamu.edu/ns/fabulator/wlc/1.0#"
  ASSETS_NS = "http://dh.tamu.edu/ns/fabulator/assets/1.0#"

  require 'fabulator/wlc/actions/make-asset-available'

  Fabulator::Core::Actions::Lib.structural 'module', Fabulator::Core::StateMachine

  module WLC
    module Actions
      class Lib < Fabulator::TagLib
        namespace WLC_NS

        action 'make-asset-available', MakeAssetAvailable
      end
    end
  end
end
