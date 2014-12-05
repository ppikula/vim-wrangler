require './spec_helper.rb'

describe 'wrangler' do
  it 'replaces vim with Vim in markdown files' do
    # Edit temporary markdown file
    vim.edit!('test.markdown')

    # Insert some text
    vim.insert('vim is awesome. vim vim vim')

    # Save the file
    vim.write

    # Make sure vim has been replaced with Vim
    vim.echo('getline(".")').should eq 'Vim is awesome. Vim Vim Vim'
  end
end
