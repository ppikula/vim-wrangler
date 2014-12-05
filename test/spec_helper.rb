require 'vimrunner'
require 'vimrunner/rspec'

Vimrunner::RSpec.configure do |config|
  # Reuse the Vim server
  config.reuse_server = true

  plugin_path = File.expand_path('..')

  config.start_vim do
    # Use GVim
    vim = Vimrunner.start

    # Tell Vimrunner to include our plugin
    vim.add_plugin(plugin_path, '../ftplugin/erlang.vim')

    vim
  end
end
