# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

zen-panel-ui-workspaces-text = Spaces

zen-panel-ui-spaces-label =
    .label = Spaces

zen-panel-ui-workspaces-create =
    .label = Create Space

zen-panel-ui-folder-create =
    .label = Create Folder

zen-panel-ui-live-folder-create =
    .label = Live Folder

zen-panel-ui-new-empty-split =
    .label = New Split

zen-workspaces-panel-context-delete =
    .label = Delete Space
    .accesskey = D

zen-workspaces-panel-change-name =
    .label = Change Name

zen-workspaces-panel-change-icon =
    .label = Change Icon

zen-workspaces-panel-context-default-profile =
    .label = Set Profile

zen-workspaces-panel-unload =
    .label = Unload Space

zen-workspaces-panel-unload-others =
    .label = Unload All Other Spaces

zen-workspaces-how-to-reorder-title = How to reorder spaces
zen-workspaces-how-to-reorder-desc = Drag the space icons at the bottom of the sidebar to reorder them

zen-workspaces-change-theme =
    .label = Edit Theme

zen-workspaces-panel-context-open =
    .label = Open Workspace
    .accesskey = O

zen-workspaces-panel-context-edit =
    .label = Edit Space
    .accesskey = E

zen-bookmark-edit-panel-workspace-selector =
    .value = Spaces
    .accesskey = W

zen-panel-ui-gradient-generator-algo-complementary =
    .label = Complementary
zen-panel-ui-gradient-generator-algo-splitComplementary =
    .label = Split
zen-panel-ui-gradient-generator-algo-analogous =
    .label = Analogous
zen-panel-ui-gradient-generator-algo-triadic =
    .label = Triadic
zen-panel-ui-gradient-generator-algo-floating =
    .label = Floating
zen-panel-ui-gradient-click-to-add = Click to add a color

zen-workspace-creation-name =
    .placeholder = Space Name

zen-move-tab-to-workspace-button =
    .label = Move To...
    .tooltiptext = Move all tabs in this window to a Space

zen-workspaces-panel-context-reorder =
    .label = Reorder Spaces

zen-workspace-creation-profile = Profile
    .tooltiptext = Profiles are used to separate cookies and site data between spaces.
zen-workspace-creation-header = Create a Space
zen-workspace-creation-label = Spaces are used to organize your tabs and sessions.

zen-workspaces-delete-workspace-title = Delete Space?
zen-workspaces-delete-workspace-body = Are you sure you want to delete { $name }? This action cannot be undone.

# Note that the html tag MUST not be changed or removed, as it is used to better
# display the shortcut in the toast notification.
zen-workspaces-close-all-unpinned-tabs-toast = Tabs Closed! Use <span>{ $shortcut }</span> to undo.
zen-workspaces-close-all-unpinned-tabs-title =
    .label = Clear
    .tooltiptext = Close all unpinned tabs

zen-panel-ui-workspaces-change-forward =
    .label = Next Space

zen-panel-ui-workspaces-change-back =
    .label = Previous Space

# Soft-delete / Recently Deleted Workspaces
# Shown as a submenu in the Space actions context menu. Expanding it
# lists recently soft-deleted spaces that can be restored.
zen-workspaces-restore-workspace-label =
    .label = Restore Deleted Space

# Label for a single entry in the Restore submenu. $name is the space's
# user-visible name; $tabCount is the number of non-essential tabs that
# will come back when the space is restored.
zen-workspaces-restore-workspace-item =
    .label = { $name } — { $tabCount ->
        [one] { $tabCount } tab
       *[other] { $tabCount } tabs
    }

# Shown when the Restore submenu is hidden because the trash is empty
# (kept around for any future surface that might need to render an
# empty state -- current UI just hides the submenu entirely).
zen-workspaces-restore-workspace-empty =
    .label = (nothing to restore)

zen-workspaces-clear-deleted-menuitem =
    .label = Clear Recently Deleted Spaces

zen-workspaces-clear-deleted-title = Clear Recently Deleted Spaces?
zen-workspaces-clear-deleted-body = This will permanently delete { $count } space(s) and close their tabs. This action cannot be undone.

# Toast shown after soft-deleting a workspace. $name is the space's
# user-visible name.
zen-workspaces-workspace-deleted-toast = Space "{ $name }" moved to Recently Deleted.

zen-workspaces-workspace-deleted-toast-undo =
    .label = Undo
