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

require "docker"
require "shellwords"
require "yast"

module YDocker
  class RunImageDialog
    include Yast::UIShortcuts
    include Yast::I18n
    extend Yast::I18n

    def initialize(image)
      textdomain "docker"
      @image = image

      config_command = @image.json["Config"]["Cmd"]
      @run_cmd =
        case config_command
        when String
          config_command
        when Array
          config_command.join(" ")
        else
          ""
        end
      @volumes = []
      @ports = []
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
      update_ok_button
    end

    def close_dialog
      Yast::UI.CloseDialog
    end

    def controller_loop
      loop do
        input = Yast::UI.UserInput
        case input
        when :ok
          run_container
          return :ok
        when :cancel
          return :cancel
        when :add_volume
          add_volume
        when :remove_volume
          remove_volume
        when :add_port
          add_port
        when :run_cmd
          update_ok_button
        when :remove_port
          remove_port
        else
          raise "Unknown action #{input}"
        end
      end
    end

    def dialog_content
      VBox(
        headings,
        contents,
        ending_buttons
      )
    end

    def headings
      Heading(_("Run Container"))
    end

    def frame_table_with_buttons(headings, table_header, id, button_suffix)
      Frame(
        headings,
        VBox(
          Table(
            Id(id),
            table_header,
            []
          ),
          HBox(
            PushButton(
              Id("add_#{button_suffix}".to_sym),
              _("Add")
            ),
            PushButton(
              Id("remove_#{button_suffix}".to_sym),
              _("Remove")
            )
          )
        )
      )
    end

    def contents
      VBox(
        Left(InputField(Id(:name), _("Name"))),
        Left(InputField(Id(:hostname), _("Hostname"))),
        Left(InputField(Id(:link), _("Link"))),
        frame_table_with_buttons(_("Volumes"),
          Header(_("Host"), _("Container")),
          :volumes_table, "volume"),
        Left(InputField(Id(:volumes_from), _("Volumes from"))),
        frame_table_with_buttons(_("Ports"),
          Header(_("External"), _("Internal"), _("Protocol")),
          :ports_table, "port"),
        Left(CheckBox(Id(:privileged), _("Privileged"), false)),
        Left(InputField(Id(:run_cmd), Opt(:notify), _("Command"), @run_cmd))
      )
    end

    def redraw_volumes
      Yast::UI.ChangeWidget(:volumes_table, :Items, volume_items)
    end

    def volume_items
      @volumes.map do |volume|
        Item(
          Id(volume),
          volume[:source],
          volume[:target]
        )
      end
    end

    def redraw_ports
      Yast::UI.ChangeWidget(:ports_table, :Items, port_items)
    end

    def port_items
      @ports.map do |mapping|
        Item(
          Id(mapping),
          mapping[:external],
          mapping[:internal],
          mapping[:protocol]
        )
      end
    end

    def ending_buttons
      HBox(
        PushButton(Id(:ok), Opt(:okButton), _("&Ok")),
        PushButton(Id(:cancel), Opt(:cancelButton), _("&Cancel"))
      )
    end

    def add_volume
      dir = Yast::UI.AskForExistingDirectory("/", _("Choose directory to share"))
      return unless dir

      Yast::UI.OpenDialog(
        VBox(
          InputField(Id(:target), _("Choose target directory"), ""),
          ending_buttons
        )
      )

      if Yast::UI.UserInput == :cancel
        Yast::UI.CloseDialog
      else
        @volumes << { source: dir, target: Yast::UI.QueryWidget(:target, :Value) }

        Yast::UI.CloseDialog

        redraw_volumes
      end
    end

    def remove_volume
      selected = Yast::UI.QueryWidget(:volumes_table, :SelectedItems)
      selected = selected.first if selected.is_a? Array
      @volumes.delete(selected)

      redraw_volumes
    end

    def add_port
      Yast::UI.OpenDialog(
        VBox(
          InputField(Id(:external), _("Choose external port"), ""),
          InputField(Id(:internal), _("Choose internal port"), ""),
          # TODO: Select between tcp and udp
          InputField(Id(:protocol), _("Choose protocol port"), "tcp"),
          ending_buttons
        )
      )

      if Yast::UI.UserInput == :cancel
        Yast::UI.CloseDialog
      else
        @ports << {
          external: Yast::UI.QueryWidget(:external, :Value),
          internal: Yast::UI.QueryWidget(:internal, :Value),
          protocol: Yast::UI.QueryWidget(:protocol, :Value)
        }

        Yast::UI.CloseDialog

        redraw_ports
      end
    end

    def remove_port
      selected = Yast::UI.QueryWidget(:ports_table, :SelectedItems)
      selected = selected.first if selected.is_a? Array
      @ports.delete(selected)

      redraw_ports
    end

    def port_bindings
      bindings = {}
      @ports.each do |mapping|
        bindings["#{mapping[:internal]}/#{mapping[:protocol]}"] =
          [{ "HostPort" => mapping[:external] }]
      end
      bindings
    end

    def run_container
      command = Shellwords.shellsplit(Yast::UI.QueryWidget(:run_cmd, :Value))
      options = { "Image" => @image.id, "Cmd" => command, "HostConfig" => {} }

      name = Yast::UI.QueryWidget(:name, :Value)
      hostname = Yast::UI.QueryWidget(:hostname, :Value)
      link = Yast::UI.QueryWidget(:link, :Value)
      volumes_from = Yast::UI.QueryWidget(:volumes_from, :Value)

      options["name"] = name unless name.empty?
      options["Hostname"] = hostname unless hostname.empty?
      options["HostConfig"]["Links"] = [link] unless link.empty?
      options["HostConfig"]["VolumesFrom"] = [volumes_from] unless volumes_from.empty?
      if !@volumes.empty?
        options["HostConfig"]["Binds"] = @volumes.map do |mapping|
          "#{mapping[:source]}:#{mapping[:target]}"
        end
      end
      options["HostConfig"]["PortBindings"] = port_bindings unless @ports.empty?
      options["Privileged"] = Yast::UI.QueryWidget(:privileged, :Value)

      container = Docker::Container.create(options)
      container.start!
    end

    def update_ok_button
      command = Shellwords.shellsplit(Yast::UI.QueryWidget(:run_cmd, :Value))
      Yast::UI.ChangeWidget(:ok, :Enabled, !command.empty?)
    end
  end
end
