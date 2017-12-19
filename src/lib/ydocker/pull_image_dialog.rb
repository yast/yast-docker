# Copyright (c) 2017 SUSE LLC.
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
require "yast"

module YDocker
  class PullImageDialog
    include Yast::UIShortcuts
    include Yast::I18n

    def initialize
      textdomain "docker"
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
          pull_image
          return :ok
        when :cancel
          return :cancel
        when :image_source
          update_ok_button
        else
          raise "Unknown action #{input}"
        end
      end
    end

    def dialog_content
      VBox(
        Id(:dialog_content),
        headings,
        contents,
        ending_buttons
      )
    end

    def headings
      Heading(_("Pull Image"))
    end

    def contents
      VBox(
        InputField(
          Id(:image_source),
          Opt(:notify),
          _("Source")
        )
      )
    end

    def ending_buttons
      HBox(
        PushButton(Id(:ok), Opt(:okButton), _("&Ok")),
        PushButton(Id(:cancel), Opt(:cancelButton), _("&Cancel"))
      )
    end

    def pull_image
      image_source = Yast::UI.QueryWidget(:image_source, :Value)
      Yast::UI.ChangeWidget(:dialog_content, :Enabled, false)
      Docker::Image.create("fromImage" => image_source)
    end

    def update_ok_button
      image_source = Yast::UI.QueryWidget(:image_source, :Value)
      Yast::UI.ChangeWidget(:ok, :Enabled, !image_source.empty?)
    end
  end
end
