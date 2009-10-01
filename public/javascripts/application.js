// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
Ext.QuickTips.init();

Ext.BLANK_IMAGE_URL = '/images/s.gif';

Ext.onReady(function(){
Ext.namespace('WLC');

WLC.debug = function(x) {
    if(!(window.console === undefined || window.console.log === undefined)) {
      console.log(x);
    }
};

Ext.namespace('Ext.ux.dd');

Ext.ux.dd.GridDragDropRowOrder = Ext.extend(Ext.util.Observable,
{
    copy: false,

    scrollable: false,

    lockedField: 'locked',

    constructor : function(config)
    {
        if (config) {
            Ext.apply(this, config);
        }

        this.addEvents(
        {
            beforerowmove: true,
            afterrowmove: true,
            beforerowcopy: true,
            afterrowcopy: true
        });

       Ext.ux.dd.GridDragDropRowOrder.superclass.constructor.call(this);
    },

    init : function (grid)
    {
        this.grid = grid;
        grid.enableDragDrop = true;

        grid.on({
            render: { fn: this.onGridRender, scope: this, single: true }
        });
    },

    onGridRender : function (grid)
    {
        var self = this;

        this.target = new Ext.dd.DropTarget(grid.getEl(),
        {
            ddGroup: grid.ddGroup || 'GridDD',
            grid: grid,
            gridDropTarget: this,

            notifyDrop: function(dd, e, data)
            {
                // Remove drag lines. The 'if' condition prevents null error when drop occurs without dragging out of the selection area
                if (this.currentRowEl)
                {
                    this.currentRowEl.removeClass('grid-row-insert-below');
                    this.currentRowEl.removeClass('grid-row-insert-above');
                }

                // determine the row
                var t = Ext.lib.Event.getTarget(e);
                var rindex = this.grid.getView().findRowIndex(t);
                if (rindex === false || rindex == data.rowIndex)
                {
                    return false;
                }

                // fire the before move/copy event
                if (this.gridDropTarget.fireEvent(self.copy ? 'beforerowcopy' : 'beforerowmove', this.gridDropTarget, data.rowIndex, rindex, data.selections, 123) === false)
                {
                    return false;
                }

                // update the store
                var ds = this.grid.getStore();

                // Changes for multiselction by Spirit
                var selections = new Array();
                var keys = ds.data.keys;
                for (var key in keys)
                {
                    for (var i = 0; i < data.selections.length; i++)
                    {
                        if (keys[key] == data.selections[i].id)
                        {
                            // Exit to prevent drop of selected records on itself.
                            if (rindex == key)
                            {
                                return false;
                            }
                            selections.push(data.selections[i]);
                        }
                    }
                }

                // fix rowindex based on before/after move
                if (rindex > data.rowIndex && this.rowPosition < 0)
                {
                    rindex--;
                }
                if (rindex < data.rowIndex && this.rowPosition > 0)
                {
                    rindex++;
                }

                // fix rowindex for multiselection
                if (rindex > data.rowIndex && data.selections.length > 1)
                {
                    rindex = rindex - (data.selections.length - 1);
                }

                // we tried to move this node before the next sibling, we stay in place
                if (rindex == data.rowIndex)
                {
                    return false;
                }

                // fire the before move/copy event
                /* dupe - does it belong here or above???
                if (this.gridDropTarget.fireEvent(self.copy ? 'beforerowcopy' : 'beforerowmove', this.gridDropTarget, data.rowIndex, rindex, data.selections, 123) === false)
                {
                    return false;
                }
                */

                if (!self.copy)
                {
                    for (var i = 0; i < data.selections.length; i++)
                    {
                        ds.remove(ds.getById(data.selections[i].id));
                    }
                }

                for (var i = selections.length - 1; i >= 0; i--)
                {
                    var insertIndex = rindex;
                    ds.insert(insertIndex, selections[i]);
                }

                // re-select the row(s)
                var sm = this.grid.getSelectionModel();
                if (sm)
                {
                    sm.selectRecords(data.selections);
                }

                // fire the after move/copy event
                this.gridDropTarget.fireEvent(self.copy ? 'afterrowcopy' : 'afterrowmove', this.gridDropTarget, data.rowIndex, rindex, data.selections);
                return true;
            },

            notifyOver: function(dd, e, data)
            {
                var t = Ext.lib.Event.getTarget(e);
                var rindex = this.grid.getView().findRowIndex(t);

                // Similar to the code in notifyDrop. Filters for selected rows and quits function if any one row matches the current selected row.
                var ds = this.grid.getStore();
                var keys = ds.data.keys;

                var rec = ds.getAt(rindex);

                if(rec && rec.get('locked')) {
                    if (this.currentRowEl)
                    {
                        this.currentRowEl.removeClass('grid-row-insert-below');
                        this.currentRowEl.removeClass('grid-row-insert-above');
                    }
                    return this.dropNotAllowed;
                }

                for (var key in keys)
                {
                    for (var i = 0; i < data.selections.length; i++)
                    {
                        if (keys[key] == data.selections[i].id)
                        {
                            if (rindex == key)
                            {
                                if (this.currentRowEl)
                                {
                                    this.currentRowEl.removeClass('grid-row-insert-below');
                                    this.currentRowEl.removeClass('grid-row-insert-above');
                                }
                                return this.dropNotAllowed;
                            }
                        }
                    }
                }

                // If on first row, remove upper line. Prevents negative index error as a result of rindex going negative.
                if (rindex < 0 || rindex === false)
                {
                    this.currentRowEl.removeClass('grid-row-insert-above');
                    return this.dropNotAllowed;
                }

                try
                {
                    var currentRow = this.grid.getView().getRow(rindex);
                    // Find position of row relative to page (adjusting for grid's scroll position)
                    var resolvedRow = new Ext.Element(currentRow).getY() - this.grid.getView().scroller.dom.scrollTop;
                    var rowHeight = currentRow.offsetHeight;

                    // Cursor relative to a row. -ve value implies cursor is above the row's middle and +ve value implues cursor is below the row's middle.
                    this.rowPosition = e.getPageY() - resolvedRow - (rowHeight/2);

                    // Clear drag line.
                    if (this.currentRowEl)
                    {
                        this.currentRowEl.removeClass('grid-row-insert-below');
                        this.currentRowEl.removeClass('grid-row-insert-above');
                    }

                    if (this.rowPosition > 0)
                    {
                        // If the pointer is on the bottom half of the row.
                        this.currentRowEl = new Ext.Element(currentRow);
                        this.currentRowEl.addClass('grid-row-insert-below');
                    }
                    else
                    {
                        // If the pointer is on the top half of the row.
                        if (rindex - 1 >= 0)
                        {
                            var previousRow = this.grid.getView().getRow(rindex - 1);
                            this.currentRowEl = new Ext.Element(previousRow);
                            this.currentRowEl.addClass('grid-row-insert-below');
                        }
                        else
                        {
                            // If the pointer is on the top half of the first row.
                            this.currentRowEl.addClass('grid-row-insert-above');
                        }
                    }
                }
                catch (err)
                {
                    WLC.debug(err);
                    rindex = false;
                }
                return (rindex === false)? this.dropNotAllowed : this.dropAllowed;
            },

            notifyOut: function(dd, e, data)
            {
                // Remove drag lines when pointer leaves the gridView.
                if (this.currentRowEl)
                {
                    this.currentRowEl.removeClass('grid-row-insert-above');
                    this.currentRowEl.removeClass('grid-row-insert-below');
                }
            }
        });

        if (this.targetCfg)
        {
            Ext.apply(this.target, this.targetCfg);
        }

        if (this.scrollable)
        {
            Ext.dd.ScrollManager.register(grid.getView().getEditorParent());
            grid.on({
                beforedestroy: this.onBeforeDestroy,
                scope: this,
                single: true
            });
        }
    },

    getTarget: function()
    {
        return this.target;
    },

    getGrid: function()
    {
        return this.grid;
    },

    getCopy: function()
    {
        return this.copy ? true : false;
    },

    setCopy: function(b)
    {
        this.copy = b ? true : false;
    },

    onBeforeDestroy : function (grid)
    {
        // if we previously registered with the scroll manager, unregister
        // it (if we don't it will lead to problems in IE)
        Ext.dd.ScrollManager.unregister(grid.getView().getEditorParent());
    }
});

Ext.namespace('WLC.grid');

WLC.grid.ResponseGrid = Ext.extend(Ext.grid.EditorGridPanel, {
    xtype: 'editorgrid',
    title: 'Responses',
    width: 430,
    height: 200,
    clicksToEdit: 1,
    constructor: function(config) {
        config.plugins = config.plugins || [ ];
        config.plugins.push(new Ext.ux.dd.GridDragDropRowOrder({
            scrollable: true
        }));
        config.viewConfig = config.viewConfig || { };
        config.viewConfig.forceFit = true;
        config.store = config.store || new Ext.data.ArrayStore({
            fields: [
                'response',
                'score'
            ],
            data: config.rubricRecord.get('responses')
        });
    
        config.columns = [
        {
            id: 'response', header: 'Response', width: 300, dataIndex: 'response', sortable: false, editor:new Ext.form.TextField({ allowBlank: false })
        },
        {
            id: 'score', header: 'Score', width: 50, dataIndex: 'score', sortable: false, editor: new Ext.form.NumberField({ allowBlank: true }) 
        }
        ];
        config.sm = new Ext.grid.RowSelectionModel({singleSelect: true});
    
        config.tools = [{
            id: 'plus',
            handler: function(event, toolEl, panel, tc) {
                var Response = panel.getStore().recordType;
                var r = new Response({
                    response: '',
                    score: ''
                });
                var n = panel.getStore().getTotalCount();
                panel.stopEditing(true);
                panel.store.insert(n, r);
                panel.startEditing(n,0);
            }
        }, {
            id: 'minus',
            handler: function(event, toolEl, panel, tc) {
                var row = panel.selModel.getSelected();
                row.store.remove(row);
            }
        }];
    
        WLC.grid.ResponseGrid.superclass.constructor.call(this, config);
    }
});

WLC.grid.RubricGrid = Ext.extend(Ext.grid.GridPanel, {
  type: 'grid',
  title: 'Rubric',
  clicksToEdit: 1,
  width: 500,
  height: 200,
  constructor: function(config) {
    config.plugins = config.plugins || [ ];
    config.plugins.push( new Ext.ux.dd.GridDragDropRowOrder({
        scrollable: true
    }));
    config.colModel = config.colModel || new Ext.grid.ColumnModel({
              defaults: {
                width: 500,
                sortable: false
              },
              columns: [
                { id : 'tag',
                  header: 'Tag',
                  width: 100,
                  dataIndex: 'tag',
                  sortable: false
                },
                { id: 'prompt', 
                  header: 'Prompt',
                  width: 400, 
                  dataIndex: 'prompt', 
                  sortable: false 
                }
              ]
            });
    config.viewConfig = {
        forceFit: true
    };
    config.sm = new Ext.grid.RowSelectionModel({singleSelect: true});
    config.tools = [{
        id: 'plus',
        qtip: 'New Prompt',
        handler: function(event, toolEl, panel, tc) {
            /* we want to pop up a window to add a new prompt */
            /* only add the new item if the window saves */
            var Response = panel.getStore().recordType;
            var rec = new Response({
                prompt: '',
                responses: [ ]
            });

            var new_form = new Ext.Window({
                title: 'Prompt and Responses',
                renderTo: document.body,
                xtype: 'form',
                floating: true,
                tools: [{
                    id: 'close',
                    handler: function(e,toolEl,panel,tc) {
                        panel.destroy();
                    }
                }],
                buttonAlign: 'center',
                margins: {
                    left: 5,
                    top: 5
                },
                width: 500,
                buttons: [{
                    text: 'Save',
                    type: 'submit',
                    handler: function(f) {
                        var fp = this.ownerCt.ownerCt;
                        
                        rec.set('prompt', fp.getComponent('prompt').getValue());
                        rec.set('tag', fp.getComponent('tag').getValue());
                        var rs = new Array;
                        fp.getComponent('responses').getStore().each(function(r) {
                            rs.push([ r.get('response'), r.get('score') ]);
                        });
                        rec.set('responses', rs);
                        var n = panel.getStore().getTotalCount();
                        panel.store.insert(n, rec);
                        fp.destroy();
                    }
                }, {
                    text: 'Cancel',
                    type: 'submit',
                    handler: function(f) {
                        var fp = this.ownerCt.ownerCt;
                        fp.destroy();
                    }
                }],
                items: [{
                    xtype: 'textfield',
                    name: 'prompt',  
                    fieldLabel: 'Prompt',
                    width: 330,
                    itemId: 'prompt',
                    emptyText: 'What is the question?',
                    value: rec.get('prompt')
                }, {
                    xtype: 'textfield',
                    name: 'tag',
                    fieldLabel: 'Tag',
                    width: 165,
                    itemId: 'tag',
                    emptyText: 'Mnemonic tag',
                    value: rec.get('tag')
                }, {
                    xtype: 'responsegrid',   
                    itemId: 'responses',
                    rubricRecord: rec
                 }]});
                 new_form.show();
    
        }
    }, {
        id: 'minus',
        handler: function(event, toolEl, panel, tc) {
            /* we want to pop up a window to confirm deletion of the selected prompt */
            var row = panel.selModel.getSelected();
            Ext.Msg.confirm(
              'Remove Prompt?',
              'You are removing a prompt and its responses.  This will not remove the prompt from the assignment on the server until you save your changes.  Are you sure you want to remove the prompt and its reponses from this configuration?',
               function(btn) {
                 if(btn == "yes") {
                   row.store.remove(row);
                 }
               }
            );
        }
    }];

    config.listeners = {
        rowdblclick: function(grid, index, e) {
            var rec = grid.getStore().getAt(index);
            var edit_form = new Ext.Window({
                title: 'Prompt and Responses',
                renderTo: document.body,
                xtype: 'form',
                floating: true,
                tools: [{
                    id: 'close',
                    handler: function(e,toolEl,panel,tc) {
                        panel.destroy();
                    }
                }],
                buttonAlign: 'center',
                margins: {
                    left: 5,
                    top: 5
                },
                width: 500,
                buttons: [{
                    text: 'Save',
                    type: 'submit',
                    handler: function(f) {
                        var fp = this.ownerCt.ownerCt;
                        rec.set('prompt', fp.getComponent('prompt').getValue());
                        rec.set('tag', fp.getComponent('tag').getValue());
                        var rs = new Array;
                        fp.getComponent('responses').getStore().each(function(r) {
                            rs.push([ r.get('response'), r.get('score') ]);
                        });
                        rec.set('responses', rs);
                        fp.destroy();
                    }
                }, {
                    text: 'Cancel',
                    type: 'submit',
                    handler: function(f) {
                        var fp = this.ownerCt.ownerCt;
                        fp.destroy();
                    }
                }],
                items: [{
                    xtype: 'textfield',
                    name: 'prompt',
                    fieldLabel: 'Prompt',
                    width: 330,
                    itemId: 'prompt',
                    emptyText: 'What is the question?',
                    value: rec.get('prompt')
                }, {
                    xtype: 'textfield',
                    name: 'tag',
                    fieldLabel: 'Tag',
                    width: 165,
                    itemId: 'tag',
                    emptyText: 'Mnemonic tag',
                    value: rec.get('tag')
                }, {
                    xtype: 'responsegrid',
                    itemId: 'responses',
                    rubricRecord: rec
                 }]});
                 edit_form.show();

               }
            };
          
    WLC.grid.RubricGrid.superclass.constructor.call(this, config);
  }
});

Ext.namespace('WLC.ux');

WLC.ux.ComposeMessageWindow = Ext.extend(Ext.Window, {
  floating: true,
  autoWidth: true,
  tools: [{
    id: 'close',
    handler: function(e,toolEl,panel,tc) {
      panel.destroy();
    }
  }],

  constructor: function(config) {
    var compose_form = this;
    config.items = [{
      xtype: 'form',
      buttonAlign: 'center',
      fileUpload: true,
      url: config.url,
      margins: {
        left: 5,
        top: 5
      },
      width: 500,
      buttons: [{
        text: 'Send Message',
        type: 'submit',
        handler: function(f) {
          var fp = this.ownerCt.ownerCt;
          var form = fp.getForm();
          if(form.isValid()) {
            form.submit({
              url: config.url,
              fileUpload: true,
              success: function() {
                config.store.reload();
                compose_form.destroy();
              }
            });
          }
        }
      }, {
        text: 'Reset',
        type: 'reset',
        handler: function(f) {
          var fp = this.ownerCt.ownerCt;
          var form = fp.getForm();
          form.reset();
        }
      }, {
        text: 'Cancel',
        type: 'submit',
        handler: function(f) {
          compose_form.destroy();
        }
      }],
      items: [{
        fieldLabel: 'To',
        xtype: 'combo',
        mode: 'local',
        editable: true,
        triggerAction: 'all',
        forceSelection: true,
        typeAhead: true,
        lazyRender: true,
        emptyText: "Who will get this message?",
        store: config.recipientStore,
        valueField: 'myId',
        displayField: 'displayText',
        value: config.messageRecipient,
        hiddenName: 'assignment_participation_id'
      }, {
        fieldLabel: 'Subject',
        width: 350,
        xtype: 'textfield',
        emptyText: "What is this message about?",
        name: 'message[subject]',
        value: config.messageSubject,
        inputType: 'text'
      }, {
        fieldLabel: 'Content',
        xtype: 'textarea',
        width: 350,
        emptyText: "What do you want to tell them?",
        height: 300,
        name: 'message[content]',
        value: config.messageContent
      }, {
        xtype: 'fieldset',
        title: 'Attachments',
        autoHeight: true,
        items: [{
          xtype: 'button',
          autoHeight: true,
          handler: function(b,e) {
            /* we want to add a form field/button pair */
            var fields = b.ownerCt.items;
            var table = fields.itemAt(fields.indexOfKey(b.id)+1);
            table.add({
              fieldLabel: 'File #' + (table.items.length/2+1),
              name: 'message[attachment][' + (table.items.length/2) + ']',
              size: 30,
              xtype: 'textfield',
              inputType: 'file'
            });
            table.add({
              xtype: 'button',
              handler: function(b,e) {
                var fields = b.ownerCt.items;
                var filefield = fields.itemAt(fields.indexOfKey(b.id)-1);
                filefield.reset();
              },
              text: 'Reset field'
            });
            table.doLayout();
          },
          text: 'Add another file'
        }, {
          layout: 'table',
          border: false,
          layoutConfig: {
            columns: 2
          },
          items: [{
            fieldLabel: 'File #1',
            name: 'message[attachment][0]',
            size: 30,
            xtype: 'textfield',
            inputType: 'file'
          }, {
            xtype: 'button',
            handler: function(b,e) {
              var fields = b.ownerCt.items;
              var filefield = fields.itemAt(fields.indexOfKey(b.id)-1);
              filefield.reset();
            },
            text: 'Reset field'
          }]
        }] 
      }, {
        inputType: 'hidden',
        xtype: 'field',
        name: 'authenticity_token',
        value: config.form_authenticity_token
      }]
    }];
    WLC.ux.ComposeMessageWindow.superclass.constructor.call(this, config);
  }
});

WLC.grid.ParticipantNameColumn = Ext.extend(Ext.grid.Column, {
    constructor: function(cfg){
        WLC.grid.ParticipantNameColumn.superclass.constructor.call(this, cfg);
        this.renderer = function(value, metaData, record) {
            metaData.css = record.get('is_participant') ?
              'silk-tick' : 'silk-cross';
            if(value.length < 1) { 
              return '';
            }
            else {
              return "<div style='padding-left: 12px'>" + value + "</div>";
            }
        };
    }
});

WLC.ux.AuthorTimelinePanel = Ext.extend(Ext.Panel, {
    baseCls: 'x-author-timeline-panel',
    frame: true
});

WLC.ux.ParticipantTimelinePanel = Ext.extend(Ext.Panel, {
    baseCls: 'x-participant-timeline-panel',
    frame: true
});

WLC.ux.InfoTimelinePanel = Ext.extend(Ext.Panel, {
    baseCls: 'x-info-timeline-panel',
    frame: true
});

WLC.ux.EvalTimelinePanel = Ext.extend(Ext.Panel, {
    baseCls: 'x-eval-timeline-panel',
    frame: true
});

Ext.ComponentMgr.registerType('rubricgrid', WLC.grid.RubricGrid);
Ext.ComponentMgr.registerType('responsegrid', WLC.grid.ResponseGrid);

Ext.ComponentMgr.registerType('composemessagewindow', WLC.ux.ComposeMessageWindow);
Ext.ComponentMgr.registerType('author-timeline-panel', WLC.ux.AuthorTimelinePanel);
Ext.ComponentMgr.registerType('participant-timeline-panel', WLC.ux.ParticipantTimelinePanel);
Ext.ComponentMgr.registerType('info-timeline-panel', WLC.ux.InfoTimelinePanel);
Ext.ComponentMgr.registerType('eval-timeline-panel', WLC.ux.EvalTimelinePanel);

Ext.grid.Column.types['participantnamecolumn'] = WLC.grid.ParticipantNameColumn;
});
