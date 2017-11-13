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
  class CommitDialog
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
      toggle_ok
    end

    def close_dialog
      Yast::UI.CloseDialog
    end

    def controller_loop
      loop do
        input = Yast::UI.UserInput
        case input
        when :ok
          perform_commit
          return :ok
        when :cancel
          return :cancel
        when :repository
          Yast::UI.ChangeWidget(:name, :Items, available_images)
          Yast::UI.ChangeWidget(:tag, :Items, available_tags)
        when :name
          Yast::UI.ChangeWidget(:tag, :Items, available_tags)
        else
          raise "Unknown action #{input}"
        end
        toggle_ok
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
      Heading(_("Commit Container"))
    end

    def contents
      VBox(
        ComboBox(
          Id(:repository),
          Opt(:editable, :notify, :hstretch),
          _("Repository"),
          available_repositories
        ),
        ComboBox(
          Id(:name),
          Opt(:editable, :notify, :hstretch),
          _("Name"),
          available_images
        ),
        ComboBox(
          Id(:tag),
          Opt(:editable, :hstretch),
          _("Tag"),
          available_tags
        ),
        InputField(Id(:author), Opt(:hstretch), _("Author")),
        InputField(Id(:message), Opt(:hstretch), _("Message"))
      )
    end

    def ending_buttons
      HBox(
        PushButton(Id(:ok), _("&Ok")),
        PushButton(Id(:cancel), _("&Cancel"))
      )
    end

    def images
      return @images if @images

      @images = Hash.new {|h, k| h[k] = Hash.new {|h2, k2| h2[k2] = []} }
      Docker::Image.all.each do |image|
        image.info["RepoTags"].each do |repo_tag|
          matches = repo_tag.match(/\A(?:([^\/]+)\/)?([^:]+)(?::(.+))?\z/)
          repo, name, tag = matches.captures
          repo ||= ""
          tag ||= ""
          @images[repo][name] << tag
        end
      end
      Yast::Builtins.y2milestone "images: #{@images.inspect}"
      @images
    end

    def available_repositories
      keys = images.keys
      keys.delete("")
      repos = keys.map{|repo_name| Item(Id(repo_name), repo_name) }
      repos << Item(Id(""), "", true)
    end

    def available_images
      selected = Yast::UI.QueryWidget(:repository, :Value)
      if images[selected]
        keys = images[selected].keys
        images = keys.map{|image_name| Item(Id(image_name), image_name) }
      else
        [Item(Id(""), "", true)]
      end
    end

    def available_tags
      selected_repo = Yast::UI.QueryWidget(:repository, :Value)
      selected_name = Yast::UI.QueryWidget(:name, :Value)
      if images[selected_repo] && images[selected_repo][selected_name]
        images[selected_repo][selected_name].map do |tag|
          Item(Id(tag), tag)
        end
      else
        [Item(Id(""), "", true)]
      end
    end

    def toggle_ok
      selected_name = Yast::UI.QueryWidget(:name, :Value)
      Yast::Builtins.y2milestone "selected name: #{selected_name.inspect}"
      Yast::UI.ChangeWidget(:ok, :Enabled, !selected_name.empty?)
    end

    def perform_commit
      selected_repo = Yast::UI.QueryWidget(:repository, :Value)
      selected_name = Yast::UI.QueryWidget(:name, :Value)
      selected_tag = Yast::UI.QueryWidget(:tag, :Value)
      author = Yast::UI.QueryWidget(:author, :Value)
      message = Yast::UI.QueryWidget(:message, :Value)

      repo = if selected_repo
        "#{selected_repo}/"
      else
        ""
      end

      repo += selected_name
      options = { 'repo' => repo }
      options['tag'] = selected_tag if selected_tag
      options['m'] = message if message
      options['author'] = author if author

      Yast::Builtins.y2milestone(
        "Going to commit new image using the following options: #{options.inspect}"
      )

      @container.commit(options)
    end
  end
end
