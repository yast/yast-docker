# Copyright (c) 2014 SUSE LLC.
#  All Rights Reserved.

#  This program is free software; you can redistribute it and/or
#  modify it under the terms of version 2 or 3 of the GNU General
# Public License as published by the Free Software Foundation.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, contact SUSE LLC.

#  To contact Novell about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com

require "yast"

module YDocker
  class ChangesDialog
    include Yast::UIShortcuts
    include Yast::I18n
    extend Yast::I18n

    def initialize(container)
      textdomain "docker"
      @container = container
    end

    def run
      return unless create_dialog

      begin
        return controller_loop
      ensure
        close_dialog
      end
    end

    def create_dialog
      Yast::UI.OpenDialog dialog_content
    end

    def close_dialog
      Yast::UI.CloseDialog
    end

    def controller_loop
      while true do
        input = Yast::UI.UserInput
        case input
        when :ok, :cancel
          return :ok
        else
          raise "Unknown action #{input}"
        end
      end
    end

    def dialog_content
      VBox(
        headings,
        changes_table,
        ending_buttons
      )
    end

    def headings
      Heading(_("Changes in Container"))
    end

    def changes_table
      Table(
        Id(:changes_table),
        Header(
          _("Path"),
          _("Status")
        ),
        changes_items
      )
    end

    STATUS_MAPPING = { # TODO: translation
      0 => ("Modified"),
      1 => ("Created"),
      2 => ("Deleted")
    }

    def changes_items
      changes = @container.changes
      changes.reject! do |change|
        path = change["Path"]
        changes.any? do |change2|
          change["Path"] != change2["Path"] && change2["Path"].start_with?(change["Path"])
        end
      end
      changes.sort_by! { |c| c["Path"] }
      changes.map do |change|
        Item(
          change["Path"],
          ((STATUS_MAPPING[change["Kind"]] || change["Kind"]).to_s)
        )
      end
    end

    def ending_buttons
      PushButton(Id(:ok), _("&Exit"))
    end
  end
end
