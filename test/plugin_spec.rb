require './spec_helper.rb'

describe 'wrangler' do
  it 'renames erlang module' do
      vim.edit!('testmod.erl')
      vim.insert('-module(testmod).')
      vim.write
      vim.command(":call AddInput('dupa')")
      vim.command('WranglerRenameModule')
      vim.edit!('dupa.erl')
      expect(vim.echo('getline(".")')).to eq '-module(dupa).'
  end

  it 'renames local variable' do
      vim.edit!('localvar.erl')
      vim.insert "-module(localvar).\n"
      vim.insert "test_function() ->\n"
      vim.insert "G = 1."
      vim.write
      vim.normal '^'
      vim.command(":call AddInput('Renamed')")
      vim.command('WranglerRenameVariable')
      expect(vim.echo('getline(".")')).to eq 'Renamed = 1.'
  end

  it 'renames function variable' do
      vim.edit!('funvar.erl')
      vim.insert "-module(funvar).\n"
      vim.insert "test_function(G) ->\n"
      vim.insert "G = 1."
      vim.write
      vim.normal '^'
      vim.command(":call AddInput('Renamed')")
      vim.command('WranglerRenameVariable')
      expect(vim.echo('getline(3)')).to eq 'Renamed = 1.'
      expect(vim.echo('getline(2)')).to eq "test_function(Renamed) ->"
  end

  it 'renames private function' do
      vim.edit!('privfun.erl')
      vim.insert "-module(privfun).\n"
      vim.insert "test_function(G) -> ok."
      vim.write
      vim.normal '^'
      vim.command(":call AddInput('refactored_function')")
      vim.command('WranglerRenameFunction')
      expect(vim.echo('getline(".")')).to eq "refactored_function(G) -> ok."
  end

  it 'renames exported function' do
      vim.edit!('pubfun.erl')
      vim.insert "-module(pubfun).\n\n"
      vim.insert "-export([publicf/1]).\n\n"
      vim.insert "publicf(G) -> ok.\n"
      vim.write
      vim.normal ':5<CR>'
      vim.command(":call AddInput('public_rename')")
      vim.command('WranglerRenameFunction')
      expect(vim.echo('getline(3)')).to eq "-export([public_rename/1])."
      expect(vim.echo('getline(5)')).to eq "public_rename(G) -> ok."
  end

  it 'discovers other apps in current project' do
      Dir.mkdir("apps") unless File.exists?("apps")
      # create first app
      directory_name = "apps/app1/"
      Dir.mkdir(directory_name) unless File.exists?(directory_name)
      directory_name = "apps/app1/src"
      Dir.mkdir(directory_name) unless File.exists?(directory_name)
      vim.edit!('apps/app1/src/app1_mod.erl')
      vim.insert "-module(app1_mod).\n"
      vim.insert "-export([publicf/1]).\n\n"
      vim.insert "publicf(G) -> \napp2_mod:publicf(1)."
      vim.write

      # create second app
      directory_name = "apps/app2/"
      Dir.mkdir(directory_name) unless File.exists?(directory_name)
      directory_name = "apps/app2/src"
      Dir.mkdir(directory_name) unless File.exists?(directory_name)
      vim.edit!('apps/app2/src/app2_mod.erl')
      vim.insert "-module(app2_mod).\n"
      vim.insert "-export([publicf/1]).\n"
      vim.insert "publicf(G) ->\n app1_mod:publicf(2)."
      vim.write
      vim.normal ':3<CR>'
      vim.command(":call AddInput('public_renamed')")
      puts vim.command('WranglerRenameFunction')
      expect(vim.echo('getline(3)')).to eq "public_renamed(G) ->"

      vim.edit!('apps/app1/src/app1_mod.erl')
      expect(vim.echo('getline(5)')).to eq "app2_mod:public_renamed(1)."
  end
end
