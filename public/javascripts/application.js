// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
Ext.namespace('WLC');

(function() {
  var panels = [ ];
  WLC.getPanel = function(n) {
    return panels[n];
  };

  WLC.setPanel = function(n,p) {
    panels[n] = p;
  };
})();
