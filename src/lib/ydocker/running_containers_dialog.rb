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
require "docker"

module YDocker
  class RunningContainersDialog
    include Yast::UIShortcuts
    include Yast::I18n

    def self.run
      Yast.import "UI"
      Yast.import "Popup"

      dialog = self.new
      dialog.run
    end

    def initialize
      textdomain "docker"

      read_containers
    end

    def run
      return unless create_dialog

      begin
        return controller_loop
      ensure
        close_dialog
      end
    end

  private
    DEFAULT_SIZE_OPT = Yast::Term.new(:opt, :defaultsize)

    def create_dialog
      Yast::UI.OpenDialog DEFAULT_SIZE_OPT, dialog_content
    end

    def close_dialog
      Yast::UI.CloseDialog
    end

    def read_containers
      @containers = [] # TODO
    end

    def controller_loop
      while true do
        input = Yast::UI.UserInput
        case input
        when :ok, :cancel
          return :ok
        when :stop
          stop_container
        when :kill
          kill_container
        else
          raise "Unknown action #{input}"
        end
      end
    end

    def select_container
      selected = Yast::UI.QueryWidget(:containers_table, :SelectedItems)
      selected = selected.first if selected.is_a? Array
      Docker::Container.get(selected)
    end

    def stop_container
      select_container.stop!

      redraw_containers
    end

    def kill_container
      select_container.kill!

      redraw_containers
    end

    def dialog_content
      VBox(
        headings,
        HBox(
          containers_table,
          action_buttons
        ),
        ending_buttons
      )
    end

    def headings
      Heading(_("Running Docker Containers"))
    end

    def redraw_containers
      Yast::UI.ChangeWidget(:containers_table, :Items, containers_items)
    end

    def containers_table
      Table(
        Id(:containers_table),
        Header(
          _("Container ID"),
          _("Image"),
          _("Command"),
          _("Created"),
          _("Status"),
          _("Ports")
        ),
        containers_items
      )
    end

    def containers_items
      containers = Docker::Container.all
      containers.map do |container|
        Item(
          Id(container.id),
          container.id,
          container.info["Image"],
          container.info["Command"],
          DateTime.strptime(container.info["Created"].to_s, "%s").to_s,
          container.info["Status"],
          container.info["Ports"].map {|p| "#{p["IP"]}:#{p["PublicPort"]}->#{p["PrivatePort"]}/#{p["Type"]}" }.join(",")
        )
      end
    end

    def action_buttons
      VBox(
        Label(_("Filter channels")),
        InputField(Id(:filter_text), Opt(:notify),""),
        PushButton(Id(:details), _("&Show details")),
        PushButton(Id(:add), _("&Run new container")),
        PushButton(Id(:stop), _("&Stop container")),
        PushButton(Id(:kill), _("&Kill container")),
      )
    end

    def ending_buttons
      PushButton(Id(:ok), _("&Exit"))
    end
  end
end
