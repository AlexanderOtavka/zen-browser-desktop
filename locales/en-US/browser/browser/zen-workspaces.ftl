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

# "Recently Deleted Workspaces" trash UI

zen-workspaces-restore-workspace-label =
    .label = Restore Deleted Space

zen-workspaces-restore-workspace-empty =
    .label = (nothing to restore)

# Single entry inside the "Restore Deleted Space" submenu.
# $name is the workspace's display name, $count is the number of tabs that
# were open in it when it was deleted (pinned + unpinned, excluding essentials).
zen-workspaces-restore-workspace-entry =
    .label = { $name } — { $count ->
        [one] { $count } tab
       *[other] { $count } tabs
    }

zen-workspaces-clear-deleted-label =
    .label = Clear Recently Deleted Spaces

zen-workspaces-clear-deleted-title = Clear recently deleted Spaces?
zen-workspaces-clear-deleted-body = This will permanently remove all Spaces currently in the Recently Deleted list. This action cannot be undone.

# Toast shown after a Space is soft-deleted. $name is the Space's name.
zen-workspaces-workspace-deleted-toast-message = "{ $name }" moved to Recently Deleted.
zen-workspaces-workspace-deleted-undo-button =
    .label = Undo
