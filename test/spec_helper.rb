require 'vimrunner'
require 'vimrunner/rspec'

Vimrunner::RSpec.configure do |config|
  # Reuse the Vim server
  config.reuse_server = true

  plugin_path = File.expand_path('..')

  config.start_vim do
    # Use vim
    vim = Vimrunner.start

    puts plugin_path
    # Include wrangler path, to check against users installation
    vim.add_plugin(plugin_path, '/test/wrangler_path.vim')

    # Tell Vimrunner to include our plugin
    vim.add_plugin(plugin_path, '/ftplugin/erlang.vim')

    vim
  end
end
