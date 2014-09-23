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
      @image = image
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
    end

    def close_dialog
      Yast::UI.CloseDialog
    end

    def controller_loop
      while true do
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


    def contents
      VBox(
        Frame(
          _("Volumes"),
          VBox(
            Table(
              Id(:volumes_table),
              Header(
                _("Host"),
                _("Container")
              ),
              []
            ),
            HBox(
              PushButton(
                Id(:add_volume),
                _("Add")
              ),
              PushButton(
                Id(:remove_volume),
                _("Remove")
              )
            )
          )
        ),
        Frame(
          _("Ports"),
          VBox(
            Table(
              Id(:ports_table),
              Header(
                _("Host"),
                _("Container")
              ),
              []
            ),
            HBox(
              PushButton(
                Id(:add_port),
                _("Add")
              ),
              PushButton(
                Id(:remove_port),
                _("Remove")
              )
            )
          )
        ),
        InputField(
          Id(:run_cmd),
          _("Command")
        )
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
          mapping[:internal]
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
          InputField(Id(:target), _("Choose target directory"),""),
          ending_buttons
        )
      )

      return if Yast::UI.UserInput == :cancel

      @volumes << { :source => dir, :target => Yast::UI.QueryWidget(:target, :Value) }

      Yast::UI.CloseDialog

      redraw_volumes
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
          ending_buttons
        )
      )

      return if Yast::UI.UserInput == :cancel

      @ports << {
        :external => Yast::UI.QueryWidget(:external, :Value),
        :internal => Yast::UI.QueryWidget(:internal, :Value)
      }

      Yast::UI.CloseDialog

      redraw_ports
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
        bindings["#{mapping[:internal]}/tcp"] = [{"HostPort" => mapping[:external]}]
      end
      bindings
    end

    def run_container
        command = Shellwords.shellsplit(Yast::UI.QueryWidget(:run_cmd, :Value))
        container = Docker::Container.create(opts={'Image' => @image.id, "Cmd" => command})
        options = {}

        if !@volumes.empty?
          options['Binds'] = @volumes.map{|mapping| "#{mapping[:source]}:#{mapping[:target]}"}
        end

        if !@ports.empty?
          options['PortBindings'] = port_bindings
        end

        container.start!(options)
    end

  end
end