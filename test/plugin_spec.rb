require './spec_helper.rb'

describe 'wrangler' do
  it 'renames erlang module' do
      vim.edit!('testmod.erl')
      vim.insert('-module(testmod).')
      vim.write
      vim.command(":call AddInput('dupa')")
      vim.command('WranglerRenameModule')
      vim.edit!('dupa.erl')
      vim.echo('getline(".")').should eq '-module(dupa).'
  end

  it 'renames local variable' do
  end

  it 'renames function variable' do
  end

  it 'renames private function' do
  end

  it 'renames exported function' do
  end

  it 'discovers other apps in current project' do
  end

  it 'renames process' do
  end

end
