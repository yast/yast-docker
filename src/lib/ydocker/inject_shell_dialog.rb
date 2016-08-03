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
require "shellwords"

module YDocker
  class InjectShellDialog
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
        when :ok
          attach
          return
        when :cancel
          return
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
      Heading(_("Inject Shell"))
    end


    def contents
      VBox(
        ComboBox(
          Id(:shell),
          Opt(:editable, :hstretch),
          _("Target Shell"),
          proposed_shells
        )
      )
    end

    def ending_buttons
      HBox(
        PushButton(Id(:ok), _("&Ok")),
        PushButton(Id(:cancel), _("&Cancel"))
      )
    end

    SHELLS = [ "bash", "sh", "zsh", "csh" ]
    def proposed_shells
      SHELLS.map{|shell| Item(Id(shell), shell) }
    end

    def attach
      selected_shell = Yast::UI.QueryWidget(:shell, :Value)

      if Yast::UI.TextMode
        Yast::UI.RunInTerminal("docker exec -ti #{@container.id} #{Shellwords.escape selected_shell} 2>&1")
      else
        res = `xterm -e 'docker exec -ti #{@container.id} #{Shellwords.escape selected_shell} || (echo "Failed to attach. Will close window in 5 seconds";sleep 5)' 2>&1`
        if $?.exitstatus != 0
          Yast::Popup.Error(_("Failed to run terminal. Error: %{error}") % { :error => res })
          return
        end
      end
    end

  end
end
